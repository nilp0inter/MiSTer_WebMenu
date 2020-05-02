package main

import (
	"fmt"
	"log"
	"os/exec"
	"syscall"

	"github.com/rakyll/statik/fs"

	"net/http"

	_ "github.com/nilp0inter/MiSTer_WebMenu/statik"
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

func main() {
	fmt.Println("Starting MiSTer WebMenu!")
	umountConfig()

	statikFS, err := fs.New()
	if err != nil {
		log.Fatal(err)
	}

	// Serve the contents over HTTP.
	http.HandleFunc("/api/hello", HelloServer)
	http.Handle("/", http.FileServer(statikFS))
	http.ListenAndServe(":80", nil)
}

func HelloServer(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello, %s!", r.URL.Path[1:])
}
