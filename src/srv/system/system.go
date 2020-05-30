package system

import "path"

const MisterFifo = "/dev/MiSTer_cmd"
const SdPath = "/media/fat"

var ScriptsPath = path.Join(SdPath, "Scripts")
var CachePath = path.Join(SdPath, ".cache", "WebMenu")
var GamesDBPath = path.Join(CachePath, "games")
var CoresDBPath = path.Join(CachePath, "cores.json")
var FoldersDBPath = path.Join(CachePath, "folders.json")
var WebMenuSHPath = path.Join(ScriptsPath, "webmenu.sh")
var WebMenuSHPathBackup = path.Join(ScriptsPath, "webmenu_prev.sh")
var MamePath = path.Join(SdPath, "_Arcade", "mame")
var HBMamePath = path.Join(SdPath, "_Arcade", "hbmame")
