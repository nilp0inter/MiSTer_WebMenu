package main

import (
	"crypto/md5"
	"encoding/json"
	"encoding/xml"
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
var Version = "<Version>"

var scanMutex = &sync.Mutex{}

type Cores struct {
	RBFs []RBF `json:"rbfs"`
	MRAs []MRA `json:"mras"`
}

type MRA struct {
	Path      string   `json:"path"`
	Filename  string   `json:"filename"`
	Ctime     int64    `json:"ctime"`
	LogicPath []string `json:"lpath"`
	MD5       string   `json:"md5"`
	Name      string   `json:"name" xml:"name"`
	Rbf       string   `xml:"rbf" json:"-"`
	Roms      []struct {
		Zip   string `xml:"zip,attr" json:"zip"`
		Index string `xml:"index,attr" json:"-"`
	} `xml:"rom" json:"roms"`
	RomsFound bool `json:"roms_found"`
}

type RBF struct {
	Path      string   `json:"path"`
	Filename  string   `json:"filename"`
	Codename  string   `json:"codename"`
	Codedate  string   `json:"codedate"`
	Ctime     int64    `json:"ctime"`
	LogicPath []string `json:"lpath"`
	MD5       string   `json:"md5"`
}

func scanMRA(filename string) (MRA, error) {
	var c MRA

	// Path
	c.Path = filename
	fi, err := os.Stat(filename)
	if err != nil {
		return c, err
	}
	c.Ctime = fi.ModTime().Unix()

	// MD5
	x, err := ioutil.ReadFile(filename)
	if err != nil {
		return c, err
	}

	h := md5.New()
	h.Sum(x)
	c.MD5 = fmt.Sprintf("%x", h.Sum(nil))

	// NAME
	baseDir := pathlib.Dir(filename)
	c.Filename = pathlib.Base(filename)

	// LPATH
	for _, d := range strings.Split(strings.TrimPrefix(baseDir, system.SdPath), "/") {
		if strings.HasPrefix(d, "_") {
			c.LogicPath = append(c.LogicPath, strings.TrimLeft(d, "_"))
		}
	}

	err = xml.Unmarshal(x, &c)
	if err != nil {
		return c, err
	}

	c.RomsFound = len(c.Roms) == 0
	rp := 0
	for i := 0; i < len(c.Roms); i++ {
		rom := c.Roms[i]
		if rom.Zip == "" || rom.Index != "0" {
			continue
		}
		c.Roms[rp] = rom
		rp++
		thisFound := false
	romLoop:
		for _, zip := range strings.Split(rom.Zip, "|") {
			parent := filepath.Clean(path.Join(system.SdPath, "..", "..")) //Double .. to include /media/fat
			for p := baseDir; filepath.Clean(p) != parent; p = path.Join(p, "..") {
				_, err := os.Stat(path.Join(p, zip))
				if err == nil {
					thisFound = true
					break romLoop
				}
				_, err = os.Stat(path.Join(p, "mame", zip))
				if err == nil {
					thisFound = true
					break romLoop
				}
				_, err = os.Stat(path.Join(p, "hbmame", zip))
				if err == nil {
					thisFound = true
					break romLoop
				}
			}
		}
		c.RomsFound = c.RomsFound || thisFound
	}
	c.Roms = c.Roms[:rp]

	return c, nil
}

func scanRBF(filename string) (RBF, error) {
	var c RBF

	// Path
	c.Path = filename
	fi, err := os.Stat(filename)
	if err != nil {
		return c, err
	}
	c.Ctime = fi.ModTime().Unix()

	// MD5
	f, err := os.Open(filename)
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
	c.Filename = pathlib.Base(filename)

	re := regexp.MustCompile(`^([^_]+)_(\d{8})[^\.]*\.rbf$`)
	matches := re.FindStringSubmatch(c.Filename)
	if matches != nil {
		c.Codename = string(matches[1])
		c.Codedate = string(matches[2])
	}

	// LPATH
	for _, d := range strings.Split(strings.TrimPrefix(pathlib.Dir(filename), system.SdPath), "/") {
		if strings.HasPrefix(d, "_") {
			c.LogicPath = append(c.LogicPath, strings.TrimLeft(d, "_"))
		}
	}
	return c, nil
}

func launchGame(filename string) error {
	return ioutil.WriteFile(system.MisterFifo, []byte("load_core "+filename), 0644)
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
		fmt.Printf("Browse to: http://%s\n", ip)
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

func ScanPath(base string, file os.FileInfo, cores *Cores) {
	ext := strings.ToLower(pathlib.Ext(file.Name()))
	isPrefix := strings.HasPrefix(file.Name(), "_")
	filepath := path.Join(base, file.Name())
	if file.IsDir() && isPrefix {
		files, err := ioutil.ReadDir(filepath)
		if err != nil {
			fmt.Println(err)
			return
		}
		for _, entry := range files {
			ScanPath(filepath, entry, cores)
		}
	} else if file.Mode().IsRegular() && ext == ".rbf" {
		fmt.Printf("RBF: %s\n", filepath)
		c, err := scanRBF(filepath)
		if err != nil {
			log.Println(filepath, err)
		} else {
			cores.RBFs = append(cores.RBFs, c)
		}
	} else if file.Mode().IsRegular() && ext == ".mra" {
		fmt.Printf("MRA: %s\n", filepath)
		c, err := scanMRA(filepath)
		if err != nil {
			log.Println(filepath, err)
		} else {
			cores.MRAs = append(cores.MRAs, c)
		}
	}
}

func ScanForCores(w http.ResponseWriter, r *http.Request) {
	scanMutex.Lock()
	defer scanMutex.Unlock()

	force, ok := r.URL.Query()["force"]
	doForce := ok && force[0] == "1"

	if _, err := os.Stat(system.CoresDBPath); doForce || err != nil {
		var cores Cores

		// Scan for RBFs & MRAs
		topLevels, err := ioutil.ReadDir(system.SdPath)
		for _, root := range topLevels {
			if strings.HasPrefix(root.Name(), "_") {
				ScanPath(system.SdPath, root, &cores)
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

func PerformWebMenuReboot(w http.ResponseWriter, r *http.Request) {
	cmd := exec.Command(system.WebMenuSHPath)
	go func() {
		time.Sleep(3 * time.Second)
		cmd.Run()
	}()
}
