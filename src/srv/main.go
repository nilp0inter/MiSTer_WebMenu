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
	"syscall"
	"time"

	"github.com/gorilla/mux"
	ps "github.com/mitchellh/go-ps"
	_ "github.com/nilp0inter/MiSTer_WebMenu/statik"
	"github.com/rakyll/statik/fs"
	"gopkg.in/ini.v1"
)

func umountConfig() {
	for {
		cmd := exec.Command("/bin/umount", "/media/fat/MiSTer.ini")

		if err := cmd.Start(); err != nil {
			log.Fatalf("Cannot umount MiSTer config: %v", err)
		}

		if err := cmd.Wait(); err != nil {
			if exiterr, ok := err.(*exec.ExitError); ok {
				if status, ok := exiterr.Sys().(syscall.WaitStatus); ok {
					if st := status.ExitStatus(); st == 32 {
						// Nothing is mounted
						return
					} else {
						log.Fatalf("Error unmounting MiSTer config: ", st)
					}
				}
			} else {
				log.Fatalf("cmd.Wait: %v", err)
				continue
			}
		}
	}
}

func patchConfig() {
	cfg, err := ini.Load("/media/fat/MiSTer.ini")
	if err != nil {
		fmt.Printf("Fail to read file: %v", err)
		os.Exit(1)
	}

	cfg.Section("MiSTer").Key("bootcore").SetValue("lastexactcore")
	cfg.Section("MiSTer").DeleteKey("bootcore_timeout")
	cfg.SaveTo("/tmp/WebMenu.ini")

	cmd := exec.Command("/bin/mount", "-o", "bind,ro", "/tmp/WebMenu.ini", "/media/fat/MiSTer.ini")

	if err := cmd.Start(); err != nil {
		log.Fatalf("Cannot mount MiSTer config: %v", err)
	}

	if err := cmd.Wait(); err != nil {
		if exiterr, ok := err.(*exec.ExitError); ok {
			log.Fatalf("Error mounting MiSTer config: %v", exiterr)
		}
	}

}

type Game struct {
	Core string
	Game string
}

type Core struct {
	Path     string `json:"path"`
	Filename string `json:"filename"`
	Codename string `json:"codename"`
	Codedate string `json:"codedate"`
	Ctime    int64  `json:"ctime"`
	MD5      string `json:"md5"`
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

	return c, nil
}

func reloadMiSTer() {
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
		}
	}
	cmd := exec.Command("/media/fat/MiSTer")
	err = cmd.Start()
	if err != nil {
		log.Fatalf("Cannot launch MiSTer process %v:", err)
	}
	go cmd.Wait()
}

func gameLauncher(c chan Game) {
	for {
		g := <-c
		fmt.Printf("Core: %v | Game: %v\n", g.Core, g.Game)

		err := ioutil.WriteFile("/media/fat/config/lastcore.dat", []byte(g.Core), 0644)
		if err != nil {
			log.Fatal(err)
		}
		reloadMiSTer()

	}
}

func createCache() {
	os.MkdirAll("/media/fat/cache/WebMenu", os.ModePerm)
}

func main() {
	msgs := make(chan Game)

	fmt.Println("Starting MiSTer WebMenu!")
	createCache()
	umountConfig()
	patchConfig()
	go gameLauncher(msgs)

	statikFS, err := fs.New()
	if err != nil {
		log.Fatal(err)
	}

	// Serve the contents over HTTP.
	r := mux.NewRouter()
	r.HandleFunc("/api/run", BuildRunCoreWithGame(msgs))
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

func ScanForCores(w http.ResponseWriter, r *http.Request) {
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
	w.WriteHeader(http.StatusOK)
}

func BuildRunCoreWithGame(c chan Game) func(http.ResponseWriter, *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		game, ok := r.URL.Query()["game"]
		if !ok {
			return
		}

		core, ok := r.URL.Query()["core"]
		if !ok {
			return
		}

		msg := Game{Core: core[0], Game: game[0]}
		c <- msg
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, "%v\n%v", core, game)
	}
}
