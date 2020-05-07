package system

import "path"

const MisterFifo = "/dev/MiSTer_cmd"
const SdPath = "/media/fat"

var ScriptsPath = path.Join(SdPath, "Scripts")
var CachePath = path.Join(SdPath, ".cache", "WebMenu")
var CoresDBPath = path.Join(CachePath, "cores.json")
var WebMenuSHPath = path.Join(ScriptsPath, "webmenu.sh")
var WebMenuSHPathBackup = path.Join(ScriptsPath, "webmenu_prev.sh")
