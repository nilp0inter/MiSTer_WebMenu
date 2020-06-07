require "string"

local KEY_ENTER = 28
local KEY_ESC = 1
local KEY_F10 = 68
local KEY_F12 = 88
local KEY_DOWN = 108

cores={
-- Computer
["Altair8800"]={
	[".*$"]={["dir"]="Altair8800"}},
["Amstrad"]={
	["^.*\.dsk$"]={
		["dir"]="Amstrad",
		["open_filemanager_keys"]={KEY_ENTER}},
	["^.*\.e..$"]={
		["dir"]="Amstrad",
		["open_filemanager_keys"]={KEY_DOWN, KEY_DOWN, KEY_ENTER}},
	["^.*\.cdt$"]={
		["dir"]="Amstrad",
		["open_filemanager_keys"]={KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_ENTER}}
},
["ao486"]={
	["^.*\.img$"]={
		["dir"]="AO486",
		["open_filemanager_keys"]={KEY_ENTER}},
	["^.*\.vhd$"]={
		["dir"]="AO486",
		["open_filemanager_keys"]={KEY_DOWN, KEY_ENTER}}
},
["Apogee"]={
	["^.*\.rka$|^.*\.rkr$|^.*\.gam$"]={
		["dir"]="APOGEE",
		["open_filemanager_keys"]={KEY_ENTER}}
},
["Apple-I"]={
	["^.*\.txt$"]={
		["dir"]="Apple-I",
		["open_filemanager_keys"]={KEY_ENTER}},
},
["Apple-II"]={
	["^.*\.nib$|^.*\.dsk$|^.*\.do^.*\.po$"]={
		["dir"]="Apple-II",
		["open_filemanager_keys"]={KEY_ENTER}}
},
["Aquarius"]={
	["^.*\.bin$"]={["dir"]="AQUARIUS"}},
["Archie"]={
	[""]={["dir"]="ARCHIE"}}, -- TODO
["Atari800"]={
	["^.*\.atr$|^.*\.xex$|^.*\.xfd$|^.*\.atx$"]={
		["dir"]="ATARI800",
		["open_filemanager_keys"]={KEY_ENTER}},
	["^.*\.car$|^.*\.rom$|^.*\.bin$"]={
		["dir"]="ATARI800",
		["open_filemanager_keys"]={KEY_DOWN, KEY_DOWN, KEY_ENTER}},
},
["AtariST"]={
	[""]={["dir"]=nil}}, -- TODO
["BBCMicro"]={
	["^.*\.vhd$"]={
		["dir"]="BBCMicro",
		["open_filemanager_keys"]={KEY_ENTER}}
},
["BK0011M"]={
	["^.*\.bin$"]={
		["dir"]="BK0011M",
		["open_filemanager_keys"]={KEY_ENTER}},
	["^.*\.dsk$"]={
		["dir"]="BK0011M",
		["open_filemanager_keys"]={KEY_DOWN, KEY_ENTER}},
	["^.*\.vhd$"]={
		["dir"]="BK0011M",
		["open_filemanager_keys"]={KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_ENTER}}
},
["C16"]={
	["^.*\.prg$"]={
		["dir"]="C16",
		["open_filemanager_keys"]={KEY_ENTER}},
	["^.*\.bin$"]={
		["dir"]="C16",
		["open_filemanager_keys"]={KEY_DOWN, KEY_ENTER}},
	["^.*\.d64$"]={
		["dir"]="C16",
		["open_filemanager_keys"]={KEY_DOWN, KEY_DOWN, KEY_ENTER}},
	["^.*\.tap$"]={
		["dir"]="C16",
		["open_filemanager_keys"]={KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_ENTER}}
},
["C64"]={
	["^.*\.d64$|^.*\.t64$"]={
		["dir"]="C64",
		["open_filemanager_keys"]={KEY_ENTER}},
	["^.*\.prg$"]={
		["dir"]="C64",
		["open_filemanager_keys"]={KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_ENTER}},
	["^.*\.crt$"]={
		["dir"]="C64",
		["open_filemanager_keys"]={KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_ENTER}},
	["^.*\.tap$"]={
		["dir"]="C64",
		["open_filemanager_keys"]={KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_ENTER}}
},
["Galaksija"]={
	["^.*\.tap$"]={
		["dir"]=nil, -- TODO
		["open_filemanager_keys"]={KEY_ENTER}}
},
["ht1080z"]={
	["^.*\.cas$"]={
		["dir"]="HT1080Z",
		["open_filemanager_keys"]={KEY_ENTER}}
},
["Jupiter"]={
	["^.*\.ace$"]={
		["dir"]="Jupiter",
		["open_filemanager_keys"]={KEY_ENTER}}
},
["MacPlus"]={
	[""]={["dir"]="MACPLUS"}}, -- TODO
["Minimig"]={
	[""]={["dir"]="Minimig"}}, -- TODO
["MSX"]={
	["^.*\.vhd$"]={
		["dir"]="MSX",
		["open_filemanager_keys"]={KEY_ENTER}}
},
["MultiComp"]={
	[""]={["dir"]=nil}}, -- TODO
["ORAO"]={
	["^.*\.tap$"]={
		["dir"]="ORAO",
		["open_filemanager_keys"]={KEY_ENTER}}
},
["Oric"]={
	[""]={["dir"]=nil}}, -- TODO
["PDP1"]={
	["^.*\.pdp$|^.*\.rim$|^.*\.bin$"]={
		["dir"]="PDP1",
		["open_filemanager_keys"]={KEY_ENTER}}
},
["PET2001"]={
	["^.*\.tap$|^.*\.prg$"]={
		["dir"]="PET2001",
		["open_filemanager_keys"]={KEY_ENTER}}
},
["QL"]={
	["^.*\.mvd$"]={
		["dir"]="QL",
		["open_filemanager_keys"]={KEY_ENTER}}
},
["SAMCoupe"]={
	["^.*\.dsk$|^.*\.mgt$|^.*\.img$"]={
		["dir"]="SAMCOUPE",
		["open_filemanager_keys"]={KEY_ENTER}}
},
["SharpMZ"]={
	[""]={["dir"]="SHARP MZ SERIES"}}, -- TODO
["Specialist"]={
	["^.*\.rks$"]={
		["dir"]="SPMX",
		["open_filemanager_keys"]={KEY_ENTER}},
	["^.*\.od1$"]={
		["dir"]="SPMX",
		["open_filemanager_keys"]={KEY_DOWN, KEY_ENTER}},
},
["Ti994a"]={
	["^.*\.bin$"]={
		["dir"]="TI-99_4A",
		["open_filemanager_keys"]={KEY_ENTER}} -- XXX: Multiple .bin
},
["TRS-80"]={
	[""]={["dir"]=nil}}, -- TODO
["TSConf"]={
	["^.*\.vhd$"]={
		["dir"]="TSConf",
		["open_filemanager_keys"]={KEY_ENTER}}
},
["Vector-06C"]={
	["^.*\.rom$|^.*\.com$|^.*\.c00$|^.*\.edd$"]={
		["dir"]="VECTOR06",
		["open_filemanager_keys"]={KEY_ENTER}},
	["^.*\.fdd$"]={
		["dir"]="VECTOR06",
		["open_filemanager_keys"]={KEY_DOWN, KEY_ENTER}}
},
["VIC20"]={
	["^.*\.prg$"]={
		["dir"]="VIC20",
		["open_filemanager_keys"]={KEY_ENTER}},
	["^.*\.crt$"]={
		["dir"]="VIC20",
		["open_filemanager_keys"]={KEY_DOWN, KEY_ENTER}},
	["^.*\.ct.$"]={
		["dir"]="VIC20",
		["open_filemanager_keys"]={KEY_DOWN, KEY_DOWN, KEY_ENTER}},
	["^.*\.d64$"]={
		["dir"]="VIC20",
		["open_filemanager_keys"]={KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_ENTER}},
	["^.*\.tap$"]={
		["dir"]="VIC20",
		["open_filemanager_keys"]={KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_ENTER}}
},
["X68000"]={
	[""]={["dir"]="X68000"}}, -- TODO
["ZX81"]={
	["^.*\.o$|^.*\.p$"]={
		["dir"]="ZX81",
		["open_filemanager_keys"]={KEY_ENTER}}
},
["ZX-Spectrum"]={
	["^.*\.trd$|^.*\.img$|^.*\.dsk$|^.*\.mgt$"]={
		["dir"]="Spectrum",
		["open_filemanager_keys"]={KEY_ENTER},
		["post_rom_load_keys"]={KEY_F10}},
	["^.*\.tap$|^.*\.csw$|^.*\.tzx$"]={
		["dir"]="Spectrum",
		["open_filemanager_keys"]={KEY_DOWN, KEY_ENTER},
		["post_rom_load_keys"]={KEY_F10}},
	["^.*\.z80$"]={
		["dir"]="Spectrum",
		["open_filemanager_keys"]={KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_ENTER}}
},

-- Console
["Astrocade"]={
	["^.*\.bin$"]={
		["dir"]="Astrocade",
		["open_filemanager_keys"]={KEY_ENTER}}
},
["Atari2600"]={
	[".*$"]={
		["dir"]="ATARI2600",
		["core_load_time"]=500,
		["open_filemanager_keys"]={KEY_ENTER}}
},
["Atari5200"]={
	["^.*\.car$|^.*\.a52$|^.*\.bin$|^.*\.rom$"]={
		["dir"]="ATARI5200",
		["core_load_time"]=4000,
		["open_filemanager_keys"]={KEY_ENTER}}
},
["AY-3-8500"]={
},
["ColecoVision"]={
	["^.*\.col$|^.*\.bin$|^.*\.rom$"]={
		["dir"]="Coleco",
		["open_filemanager_keys"]={KEY_ENTER}},
	["^.*\.sg$"]={
		["dir"]="Coleco",
		["open_filemanager_keys"]={KEY_DOWN, KEY_ENTER}}
},
["Gameboy"]={
	["^.*\.gbc$|^.*\.gb$"]={
		["dir"]="GAMEBOY",
		["open_filemanager_keys"]={KEY_ENTER}}
},
["GBA"]={
	["^.*\.gba$"]={
		["dir"]="GBA",
		["core_load_time"]=6000,
		["open_filemanager_keys"]={KEY_ENTER}}
},
["Genesis"]={
	["^.*\.bin$|^.*\.gen$|^.*\.md$"]={
		["dir"]="Genesis",
		["core_load_time"]=4000,
		["open_filemanager_keys"]={KEY_ENTER}}
},
["MegaCD"]={
	["^.*\.cue$"]={
		["dir"]="MegaCD",
		["open_filemanager_keys"]={KEY_ENTER}},
	["^.*\.bin$|^.*\.gen$|^.*\.md$"]={
		["dir"]="MegaCD",
		["open_filemanager_keys"]={KEY_DOWN, KEY_DOWN, KEY_ENTER}},
},
["NeoGeo"]={
	[".*$"]={
		["dir"]="NeoGeo",
		["open_filemanager_keys"]={KEY_ENTER}}
},
["NES"]={
	["^.*\.nes$|^.*\.fds$|^.*\.nsf$"]={
		["dir"]="NES",
		["core_load_time"]=4000,
		["open_filemanager_keys"]={KEY_ENTER}},
	["^.*\.bin$"]={
		["dir"]="NES",
		["open_filemanager_keys"]={KEY_DOWN, KEY_ENTER}}
},
["Odyssey2"]={
	["^.*\.bin$"]={
		["dir"]="ODYSSEY2",
		["open_filemanager_keys"]={KEY_ENTER}}
},
["SMS"]={
	["^.*\.sms$|^.*\.sg$"]={
		["dir"]="SMS",
		["open_filemanager_keys"]={KEY_ENTER}},
	["^.*\.gg$"]={
		["dir"]="SMS",
		["open_filemanager_keys"]={KEY_DOWN, KEY_ENTER}}
},
["SNES"]={
	["^.*\.sfc$|^.*\.smc$|^.*\.bin$"]={
		["dir"]="SNES",
		["open_filemanager_keys"]={KEY_ENTER}}
},
["TurboGrafx16"]={
	["^.*\.pce$|^.*\.bin$"]={
		["dir"]="TGFX16",
		["open_filemanager_keys"]={KEY_ENTER}},
	["^.*\.sgx$"]={
		["dir"]="TGFX16",
		["open_filemanager_keys"]={KEY_DOWN, KEY_ENTER}},
	["^.*\.cue$"]={
		["dir"]="TGFX16-CD",
		["open_filemanager_keys"]={KEY_DOWN, KEY_DOWN, KEY_ENTER}},
},
["Vectrex"]={
	["^.*\.vec$|^.*\.bin$|^.*\.rom$"]={
		["dir"]="VECTREX",
		["open_filemanager_keys"]={KEY_ENTER}}
	}
}

function press(key)
	key_press(key)
	sleep(500)
end

if method =="boot" then
	error("Method not implemented yet")
elseif method == "rload" then
	-- Must have "core_codename"
	-- Must have "core_path"
	-- Must have "rom"
	if cores[core_codename] == nil then
		error("Unknown core")
	end

	dir = nil
	for exp, config in pairs(cores[core_codename]) do
		if match(exp, rom) then
			dir = config["dir"]
			core_load_time = config["core_load_time"] or 5000
			rom_load_time = config["rom_load_time"] or 5000
			open_filenamager_keys = config["open_filemanager_keys"] or {}
			post_rom_load_keys = config["post_rom_load_keys"] or {}
			break
		end
	end
	if dir == nil then
		error("Config not found for core")
	end
	if is_zip then
		rom = string.gsub(rom, "\/[^\/]+$", "", 1)
	end

	dir = "/media/fat/" .. dir

	print(rom, dir)
	load_core(core_path)
	sleep(core_load_time)
	mount(rom, dir, function ()
		press(KEY_ESC) -- Sometimes the menu will popup others won't
		press(KEY_F12)
		for _, key in pairs(open_filenamager_keys) do
			press(key)
		end
		if is_zip then
			press(KEY_DOWN)
			press(KEY_ENTER)
		end
		press(KEY_DOWN)
		press(KEY_ENTER)
		for _, key in pairs(post_rom_load_keys) do
			press(key)
		end
		sleep(rom_load_time)
	end)
else
	error("Unknown method")
end
