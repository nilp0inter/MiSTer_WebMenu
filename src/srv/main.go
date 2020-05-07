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
	"github.com/nilp0inter/MiSTer_WebMenu/system"
	"github.com/nilp0inter/MiSTer_WebMenu/update"
	"github.com/rakyll/statik/fs"
)

// Version is obtained at compile time
const Version = "<Version>"

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
	for _, d := range strings.Split(strings.TrimPrefix(pathlib.Dir(path), system.SdPath), "/") {
		if strings.HasPrefix(d, "_") {
			c.LogicPath = append(c.LogicPath, strings.TrimLeft(d, "_"))
		}
	}
	return c, nil
}

func launchGame(path string) error {
	return ioutil.WriteFile(system.MisterFifo, []byte("load_core "+path), 0644)
}

func createCache() {
	os.MkdirAll(system.CachePath, os.ModePerm)
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
	r.PathPrefix("/cached/").Handler(http.StripPrefix("/cached/", http.FileServer(http.Dir(system.CachePath))))
	r.PathPrefix("/").Handler(http.FileServer(statikFS))

	srv := &http.Server{
		Handler:      r,
		Addr:         "0.0.0.0:80",
		WriteTimeout: 90 * time.Second,
		ReadTimeout:  90 * time.Second,
	}
	log.Fatal(srv.ListenAndServe())
}

/////////////////////////////////////////////////////////////////////////
//                                 API                                 //
/////////////////////////////////////////////////////////////////////////

func GetCurrentVersion(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte(Version))
}

func ScanForCores(w http.ResponseWriter, r *http.Request) {
	scanMutex.Lock()
	defer scanMutex.Unlock()

	force, ok := r.URL.Query()["force"]
	doForce := ok && force[0] == "1"

	if _, err := os.Stat(system.CoresDBPath); doForce || err != nil {
		// File doesn't exist
		var cores []Core
		paths := []string{
			path.Join(system.SdPath, "_*/*.rbf"),
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
		err = ioutil.WriteFile(system.CoresDBPath, b, 0644)
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
	err := update.UpdateSystem(version[0])
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(err.Error()))
		return
	}
	return
}

/////////////////////////////////////////////////////////////////////////
//                               reboot                                //
/////////////////////////////////////////////////////////////////////////

func PerformWebMenuReboot(w http.ResponseWriter, r *http.Request) {
	cmd := exec.Command(system.WebMenuSHPath)
	go func() {
		time.Sleep(3 * time.Second)
		cmd.Run()
	}()
}
