package update

import (
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"path"

	"github.com/nilp0inter/MiSTer_WebMenu/system"
)

func sha256Check(filepath string, sumpath string) error {
	cmd := exec.Command("/bin/sh", "-c", "sha256sum -c \"${SUM_PATH}\" < \"${FILE_PATH}\"")
	cmd.Env = append(os.Environ(),
		"SUM_PATH="+sumpath,
		"FILE_PATH="+filepath)
	return cmd.Run()
}

func downloadFile(filepath string, url string) error {

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

func copyFile(src string, dst string) error {
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
	updateChecksum := path.Join(system.CachePath, "sha256.sum")
	updateWebMenuSHPath := path.Join(system.CachePath, "webmenu.sh")
	url := "https://github.com/nilp0inter/MiSTer_WebMenu/releases/download/" + version + "/"

	err := downloadFile(updateChecksum, url+"sha256.sum")
	defer os.Remove(updateChecksum)
	if err != nil {
		return err
	}

	err = downloadFile(updateWebMenuSHPath, url+"webmenu.sh")
	defer os.Remove(updateWebMenuSHPath)
	if err != nil {
		return err
	}

	err = sha256Check(updateWebMenuSHPath, updateChecksum)
	if err != nil {
		return err
	}

	err = copyFile(system.WebMenuSHPath, system.WebMenuSHPathBackup)
	if err != nil {
		return err
	}

	err = copyFile(updateWebMenuSHPath, system.WebMenuSHPath)
	if err != nil {
		return err
	}

	return nil
}
