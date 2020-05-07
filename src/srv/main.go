package main

import (
	"crypto/md5"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path"
	pathlib "path"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/mux"
	_ "github.com/nilp0inter/MiSTer_WebMenu/statik"
	"github.com/rakyll/statik/fs"
)

// Version is obtained at compile time
const Version = "<Version>"
const misterFifo = "/dev/MiSTer_cmd"
const sdPath = "/media/fat"

var scriptsPath = path.Join(sdPath, "Scripts")
var cachePath = path.Join(sdPath, ".cache", "WebMenu")
var coresDBPath = path.Join(cachePath, "cores.json")
var webMenuSHPath = path.Join(scriptsPath, "webmenu.sh")
var webMenuSHPathBackup = path.Join(scriptsPath, "webmenu_prev.sh")

var scanMutex = &sync.Mutex{}

type Game struct {
	Core     string
	CorePath string
	Game     string
}

type Core struct {
	Path      string   `json:"path"`
	Filename  string   `json:"filename"`
	Codename  string   `json:"codename"`
	Codedate  string   `json:"codedate"`
	Ctime     int64    `json:"ctime"`
	LogicPath []string `json:"lpath"`
	MD5       string   `json:"md5"`
}

func scanCore(path string) (Core, error) {
	var c Core

	// Path
	c.Path = path
	fi, err := os.Stat(path)
	if err != nil {
		return c, err
	}
	c.Ctime = fi.ModTime().Unix()

	// MD5
	f, err := os.Open(path)
	if err != nil {
		return c, err
	}
	defer f.Close()

	h := md5.New()
	if _, err := io.Copy(h, f); err != nil {
		return c, err
	}
	c.MD5 = fmt.Sprintf("%x", h.Sum(nil))

	// NAME
	c.Filename = pathlib.Base(path)

	re := regexp.MustCompile(`^([^_]+)_(\d{8})[^\.]*\.rbf$`)
	matches := re.FindStringSubmatch(c.Filename)
	if matches != nil {
		c.Codename = string(matches[1])
		c.Codedate = string(matches[2])
	}

	// LPATH
	for _, d := range strings.Split(strings.TrimPrefix(pathlib.Dir(path), sdPath), "/") {
		if strings.HasPrefix(d, "_") {
			c.LogicPath = append(c.LogicPath, strings.TrimLeft(d, "_"))
		}
	}
	return c, nil
}

func launchGame(path string) error {
	return ioutil.WriteFile(misterFifo, []byte("load_core "+path), 0644)
}

func createCache() {
	os.MkdirAll(cachePath, os.ModePerm)
}

// Get preferred outbound ip of this machine
func GetOutboundIP() (error, net.IP) {
	conn, err := net.Dial("udp", "8.8.8.8:80")
	if err != nil {
		return err, nil
	}
	defer conn.Close()

	localAddr := conn.LocalAddr().(*net.UDPAddr)

	return nil, localAddr.IP
}

func greetUser() {
	fmt.Printf("MiSTer WebMenu %s\n\n", Version)
	err, ip := GetOutboundIP()
	if err != nil {
		fmt.Println("No connection detected :(")
	} else {
		fmt.Printf("Browser to: http://%s\n", ip)
	}
}

func main() {

	greetUser()
	createCache()

	statikFS, err := fs.New()
	if err != nil {
		log.Fatal(err)
	}

	// Serve the contents over HTTP.
	r := mux.NewRouter()
	r.HandleFunc("/api/webmenu/reboot", PerformWebMenuReboot).Methods("POST")
	r.HandleFunc("/api/update", PerformUpdate).Methods("POST")
	r.HandleFunc("/api/run", RunCoreWithGame)
	r.HandleFunc("/api/version/current", GetCurrentVersion)
	r.HandleFunc("/api/cores/scan", ScanForCores)
	r.PathPrefix("/cached/").Handler(http.StripPrefix("/cached/", http.FileServer(http.Dir(cachePath))))
	r.PathPrefix("/").Handler(http.FileServer(statikFS))

	srv := &http.Server{
		Handler:      r,
		Addr:         "0.0.0.0:80",
		WriteTimeout: 90 * time.Second,
		ReadTimeout:  90 * time.Second,
	}
	log.Fatal(srv.ListenAndServe())
}

func GetCurrentVersion(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte(Version))
}

func ScanForCores(w http.ResponseWriter, r *http.Request) {
	scanMutex.Lock()
	defer scanMutex.Unlock()

	force, ok := r.URL.Query()["force"]
	doForce := ok && force[0] == "1"

	if _, err := os.Stat(coresDBPath); doForce || err != nil {
		// File doesn't exist
		var cores []Core
		paths := []string{
			path.Join(sdPath, "_*/*.rbf"),
		}

		for _, p := range paths {
			matches, err := filepath.Glob(p)
			if err != nil {
				log.Fatalf("Error scanning cores: %v", err)
			}
			for _, m := range matches {
				c, err := scanCore(m)
				if err != nil {
					log.Println(err)
				} else {
					cores = append(cores, c)
				}
			}
		}

		b, err := json.Marshal(cores)
		if err != nil {
			log.Fatal(err)
		}
		err = ioutil.WriteFile(coresDBPath, b, 0644)
		if err != nil {
			log.Fatal(err)
		}
	}
	w.WriteHeader(http.StatusOK)
}

func RunCoreWithGame(w http.ResponseWriter, r *http.Request) {
	path, ok := r.URL.Query()["path"]
	if !ok {
		return
	}

	err := launchGame(path[0])
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(err.Error()))
		return
	}
}

/////////////////////////////////////////////////////////////////////////
//                               update                                //
/////////////////////////////////////////////////////////////////////////

func PerformUpdate(w http.ResponseWriter, r *http.Request) {
	version, ok := r.URL.Query()["version"]
	if !ok {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Version is mandatory"))
		return
	}
	err := UpdateSystem(version[0])
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(err.Error()))
		return
	}
	return
}

func Sha256Check(filepath string, sumpath string) error {
	cmd := exec.Command("/bin/sh", "-c", "sha256sum -c \"${SUM_PATH}\" < \"${FILE_PATH}\"")
	cmd.Env = append(os.Environ(),
		"SUM_PATH="+sumpath,
		"FILE_PATH="+filepath)
	return cmd.Run()
}

func DownloadFile(filepath string, url string) error {

	// Get the data
	resp, err := http.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	// Create the file
	out, err := os.Create(filepath)
	if err != nil {
		return err
	}
	defer out.Close()

	// Write the body to file
	_, err = io.Copy(out, resp.Body)
	return err
}

func CopyFile(src string, dst string) error {
	input, err := ioutil.ReadFile(src)
	if err != nil {
		fmt.Println(err)
		return err
	}

	err = ioutil.WriteFile(dst, input, 0644)
	if err != nil {
		fmt.Println("Error creating", dst)
		fmt.Println(err)
		return err
	}

	return nil
}

func UpdateSystem(version string) error {
	updateChecksum := path.Join(cachePath, "sha256.sum.update")
	updatewebMenuSHPath := path.Join(cachePath, "webmenu.sh.update")
	url := "https://github.com/nilp0inter/MiSTer_WebMenu/releases/download/" + version + "/"

	err := DownloadFile(updateChecksum, url+"sha256.sum")
	defer os.Remove(updateChecksum)
	if err != nil {
		return err
	}

	err = DownloadFile(updatewebMenuSHPath, url+"webmenu.sh")
	defer os.Remove(updatewebMenuSHPath)
	if err != nil {
		return err
	}

	err = Sha256Check(updatewebMenuSHPath, updateChecksum)
	if err != nil {
		return err
	}

	err = CopyFile(webMenuSHPath, webMenuSHPathBackup)
	if err != nil {
		return err
	}

	err = CopyFile(updatewebMenuSHPath, webMenuSHPath)
	if err != nil {
		return err
	}

	return nil
}

/////////////////////////////////////////////////////////////////////////
//                               reboot                                //
/////////////////////////////////////////////////////////////////////////

func PerformWebMenuReboot(w http.ResponseWriter, r *http.Request) {
	cmd := exec.Command(webMenuSHPath)
	go func() {
		time.Sleep(3 * time.Second)
		cmd.Run()
	}()
}
