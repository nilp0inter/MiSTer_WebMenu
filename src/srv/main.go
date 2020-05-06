package main

import (
	"crypto/md5"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
	pathlib "path"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/gorilla/mux"
	ps "github.com/mitchellh/go-ps"
	_ "github.com/nilp0inter/MiSTer_WebMenu/statik"
	"github.com/rakyll/statik/fs"
)

var scanMutex = &sync.Mutex{}
var Version string = "<Version>"

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
	for _, d := range strings.Split(strings.TrimPrefix(pathlib.Dir(path), "/media/fat/"), "/") {
		if strings.HasPrefix(d, "_") {
			c.LogicPath = append(c.LogicPath, strings.TrimLeft(d, "_"))
		}
	}
	return c, nil
}

func reloadMiSTer(corepath string) {
	pss, err := ps.Processes()
	if err != nil {
		log.Fatalf("Cannot list processes: %v", err)
	}
	for _, p := range pss {
		if p.Executable() == "MiSTer" {
			p2, err := os.FindProcess(p.Pid())
			if err != nil {
				log.Printf("Cannot find MiSTer process, maybe it died?: %v", err)
				continue
			}

			err = p2.Signal(os.Interrupt)
			if err != nil {
				log.Printf("Cannot kill MiSTer process!: %v", err)
				continue
			}

			// Wait for the process to die
			for {
				p, err := os.FindProcess(p.Pid())
				if err != nil {
					log.Fatalf("Error finding process")
				}
				err = p.Signal(syscall.Signal(0))
				if err != nil {
					// it died
					break
				}
			}
		}
	}

	// time.Sleep(2 * time.Second) // Wait for the system to recover from the loss :)

	cmd := exec.Command("/media/fat/MiSTer", corepath)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err = cmd.Start()
	if err != nil {
		log.Fatalf("Cannot launch MiSTer process %v:", err)
	}
	go cmd.Wait()
}

func launchGame(path string) error {
	return ioutil.WriteFile("/dev/MiSTer_cmd", []byte("load_core "+path), 0644)
}

func createCache() {
	os.MkdirAll("/media/fat/cache/WebMenu", os.ModePerm)
}

func main() {

	fmt.Printf("MiSTer WebMenu %s\n", Version)
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
	r.PathPrefix("/cached/").Handler(http.StripPrefix("/cached/", http.FileServer(http.Dir("/media/fat/cache/WebMenu"))))
	r.PathPrefix("/").Handler(http.FileServer(statikFS))

	srv := &http.Server{
		Handler: r,
		Addr:    "0.0.0.0:80",
		// Good practice: enforce timeouts for servers you create!
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

	if _, err := os.Stat("/media/fat/cache/WebMenu/cores.json"); doForce || err != nil {
		// File doesn't exist
		var cores []Core
		paths := []string{
			"/media/fat/_*/**/*.rbf",
			"/media/fat/_*/*.rbf"}

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
		err = ioutil.WriteFile("/media/fat/cache/WebMenu/cores.json", b, 0644)
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
	url := "https://github.com/nilp0inter/MiSTer_WebMenu/releases/download/" + version + "/"

	err := DownloadFile("/tmp/sha256.sum", url+"sha256.sum")
	defer os.Remove("/tmp/sha256.sum")
	if err != nil {
		return err
	}

	err = DownloadFile("/tmp/webmenu.sh", url+"webmenu.sh")
	defer os.Remove("/tmp/webmenu.sh")
	if err != nil {
		return err
	}

	err = Sha256Check("/tmp/webmenu.sh", "/tmp/sha256.sum")
	if err != nil {
		return err
	}

	err = CopyFile(
		"/media/fat/Scripts/webmenu.sh",
		"/media/fat/Scripts/webmenu_prev.sh")
	if err != nil {
		return err
	}

	err = CopyFile(
		"/tmp/webmenu.sh",
		"/media/fat/Scripts/webmenu.sh")
	if err != nil {
		return err
	}

	return nil
}

/////////////////////////////////////////////////////////////////////////
//                               reboot                                //
/////////////////////////////////////////////////////////////////////////

func PerformWebMenuReboot(w http.ResponseWriter, r *http.Request) {
	cmd := exec.Command("/media/fat/Scripts/webmenu.sh")
	go func() {
		time.Sleep(3 * time.Second)
		cmd.Run()
	}()
}
