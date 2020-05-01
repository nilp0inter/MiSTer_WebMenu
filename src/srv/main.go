package main

import (
	"fmt"
	"log"

	"github.com/rakyll/statik/fs"

	"net/http"

	_ "github.com/nilp0inter/MiSTer_WebMenu/statik" // TODO: Replace with the absolute import path
)

func main() {
	statikFS, err := fs.New()
	if err != nil {
		log.Fatal(err)
	}

	// Serve the contents over HTTP.
	http.HandleFunc("/api/hello", HelloServer)
	http.Handle("/", http.FileServer(statikFS))
	http.ListenAndServe(":8080", nil)
}

func HelloServer(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello, %s!", r.URL.Path[1:])
}
