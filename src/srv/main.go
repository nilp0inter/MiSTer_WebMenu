package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
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

func main() {
	msgs := make(chan Game)

	fmt.Println("Starting MiSTer WebMenu!")
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
	r.PathPrefix("/").Handler(http.FileServer(statikFS))

	srv := &http.Server{
		Handler: r,
		Addr:    "0.0.0.0:80",
		// Good practice: enforce timeouts for servers you create!
		WriteTimeout: 15 * time.Second,
		ReadTimeout:  15 * time.Second,
	}

	log.Fatal(srv.ListenAndServe())

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
