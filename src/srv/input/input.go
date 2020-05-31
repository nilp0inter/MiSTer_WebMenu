package input

import (
	"fmt"

	"github.com/bendahl/uinput"
)

var Keyboard uinput.Keyboard

func init() {
	// initialize keyboard and check for possible errors
	var err error
	Keyboard, err = uinput.CreateKeyboard("/dev/uinput", []byte("WebMenu Virtual Keyboard"))
	if err != nil {
		panic(err)
	}
	fmt.Println("Keyboard initialized")
}
