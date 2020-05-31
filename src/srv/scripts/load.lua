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
		["keys"]={KEY_ENTER}},
	["^.*\.e..$"]={
		["dir"]="Amstrad",
		["keys"]={KEY_DOWN, KEY_DOWN, KEY_ENTER}},
	["^.*\.cdt$"]={
		["dir"]="Amstrad",
		["keys"]={KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_ENTER}}
},
["ao486"]={
	["^.*\.img$"]={
		["dir"]="AO486",
		["keys"]={KEY_ENTER}},
	["^.*\.vhd$"]={
		["dir"]="AO486",
		["keys"]={KEY_DOWN, KEY_ENTER}}
},
["Apogee"]={
	["^.*\.rka$|^.*\.rkr$|^.*\.gam$"]={
		["dir"]="APOGEE",
		["keys"]={KEY_ENTER}}
},
["Apple-I"]={
	["^.*\.txt$"]={
		["dir"]="Apple-I",
		["keys"]={KEY_ENTER}},
},
["Apple-II"]={
	["^.*\.nib$|^.*\.dsk$|^.*\.do^.*\.po$"]={
		["dir"]="Apple-II",
		["keys"]={KEY_ENTER}}
},
["Aquarius"]={
	["^.*\.bin$"]={["dir"]="AQUARIUS"}},
["Archie"]={
	[""]={["dir"]="ARCHIE"}}, -- TODO
["Atari800"]={
	["^.*\.atr$|^.*\.xex$|^.*\.xfd$|^.*\.atx$"]={
		["dir"]="ATARI800",
		["keys"]={KEY_ENTER}},
	["^.*\.car$|^.*\.rom$|^.*\.bin$"]={
		["dir"]="ATARI800",
		["keys"]={KEY_DOWN, KEY_DOWN, KEY_ENTER}},
},
["AtariST"]={
	[""]={["dir"]=nil}}, -- TODO
["BBCMicro"]={
	["^.*\.vhd$"]={
		["dir"]="BBCMicro",
		["keys"]={KEY_ENTER}}
},
["BK0011M"]={
	["^.*\.bin$"]={
		["dir"]="BK0011M",
		["keys"]={KEY_ENTER}},
	["^.*\.dsk$"]={
		["dir"]="BK0011M",
		["keys"]={KEY_DOWN, KEY_ENTER}},
	["^.*\.vhd$"]={
		["dir"]="BK0011M",
		["keys"]={KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_ENTER}}
},
["C16"]={
	["^.*\.prg$"]={
		["dir"]="C16",
		["keys"]={KEY_ENTER}},
	["^.*\.bin$"]={
		["dir"]="C16",
		["keys"]={KEY_DOWN, KEY_ENTER}},
	["^.*\.d64$"]={
		["dir"]="C16",
		["keys"]={KEY_DOWN, KEY_DOWN, KEY_ENTER}},
	["^.*\.tap$"]={
		["dir"]="C16",
		["keys"]={KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_ENTER}}
},
["C64"]={
	["^.*\.d64$|^.*\.t64$"]={
		["dir"]="C64",
		["keys"]={KEY_ENTER}},
	["^.*\.prg$"]={
		["dir"]="C64",
		["keys"]={KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_ENTER}},
	["^.*\.crt$"]={
		["dir"]="C64",
		["keys"]={KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_ENTER}},
	["^.*\.tap$"]={
		["dir"]="C64",
		["keys"]={KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_ENTER}}
},
["Galaksija"]={
	["^.*\.tap$"]={
		["dir"]=nil, -- TODO
		["keys"]={KEY_ENTER}}
},
["ht1080z"]={
	["^.*\.cas$"]={
		["dir"]="HT1080Z",
		["keys"]={KEY_ENTER}}
},
["Jupiter"]={
	["^.*\.ace$"]={
		["dir"]="Jupiter",
		["keys"]={KEY_ENTER}}
},
["MacPlus"]={
	[""]={["dir"]="MACPLUS"}}, -- TODO
["Minimig"]={
	[""]={["dir"]="Minimig"}}, -- TODO
["MSX"]={
	["^.*\.vhd$"]={
		["dir"]="MSX",
		["keys"]={KEY_ENTER}}
},
["MultiComp"]={
	[""]={["dir"]=nil}}, -- TODO
["ORAO"]={
	["^.*\.tap$"]={
		["dir"]="ORAO",
		["keys"]={KEY_ENTER}}
},
["Oric"]={
	[""]={["dir"]=nil}}, -- TODO
["PDP1"]={
	["^.*\.pdp$|^.*\.rim$|^.*\.bin$"]={
		["dir"]="PDP1",
		["keys"]={KEY_ENTER}}
},
["PET2001"]={
	["^.*\.tap$|^.*\.prg$"]={
		["dir"]="PET2001",
		["keys"]={KEY_ENTER}}
},
["QL"]={
	["^.*\.mvd$"]={
		["dir"]="QL",
		["keys"]={KEY_ENTER}}
},
["SAMCoupe"]={
	["^.*\.dsk$|^.*\.mgt$|^.*\.img$"]={
		["dir"]="SAMCOUPE",
		["keys"]={KEY_ENTER}}
},
["SharpMZ"]={
	[""]={["dir"]="SHARP MZ SERIES"}}, -- TODO
["Specialist"]={
	["^.*\.rks$"]={
		["dir"]="SPMX",
		["keys"]={KEY_ENTER}},
	["^.*\.od1$"]={
		["dir"]="SPMX",
		["keys"]={KEY_DOWN, KEY_ENTER}},
},
["Ti994a"]={
	["^.*\.bin$"]={
		["dir"]="TI-99_4A",
		["keys"]={KEY_ENTER}} -- XXX: Multiple .bin
},
["TRS-80"]={
	[""]={["dir"]=nil}}, -- TODO
["TSConf"]={
	["^.*\.vhd$"]={
		["dir"]="TSConf",
		["keys"]={KEY_ENTER}}
},
["Vector-06C"]={
	["^.*\.rom$|^.*\.com$|^.*\.c00$|^.*\.edd$"]={
		["dir"]="VECTOR06",
		["keys"]={KEY_ENTER}},
	["^.*\.fdd$"]={
		["dir"]="VECTOR06",
		["keys"]={KEY_DOWN, KEY_ENTER}}
},
["VIC20"]={
	["^.*\.prg$"]={
		["dir"]="VIC20",
		["keys"]={KEY_ENTER}},
	["^.*\.crt$"]={
		["dir"]="VIC20",
		["keys"]={KEY_DOWN, KEY_ENTER}},
	["^.*\.ct.$"]={
		["dir"]="VIC20",
		["keys"]={KEY_DOWN, KEY_DOWN, KEY_ENTER}},
	["^.*\.d64$"]={
		["dir"]="VIC20",
		["keys"]={KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_ENTER}},
	["^.*\.tap$"]={
		["dir"]="VIC20",
		["keys"]={KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_ENTER}}
},
["X68000"]={
	[""]={["dir"]="X68000"}}, -- TODO
["ZX81"]={
	["^.*\.o$|^.*\.p$"]={
		["dir"]="ZX81",
		["keys"]={KEY_ENTER}}
},
["ZX-Spectrum"]={
	["^.*\.trd$|^.*\.img$|^.*\.dsk$|^.*\.mgt$"]={
		["dir"]="Spectrum",
		["keys"]={KEY_ENTER}},
	["^.*\.tap$|^.*\.csw$|^.*\.tzx$"]={
		["dir"]="Spectrum",
		["keys"]={KEY_DOWN, KEY_ENTER}},
	["^.*\.z80$"]={
		["dir"]="Spectrum",
		["keys"]={KEY_DOWN, KEY_DOWN, KEY_DOWN, KEY_ENTER}}
},

-- Console
["Astrocade"]={
	["^.*\.bin$"]={
		["dir"]="Astrocade",
		["keys"]={KEY_ENTER}}
},
["Atari2600"]={
	[".*$"]={
		["dir"]="ATARI2600",
		["keys"]={KEY_ENTER}}
},
["Atari5200"]={
	["^.*\.car$|^.*\.a52$|^.*\.bin$|^.*\.rom$"]={
		["dir"]="ATARI5200",
		["keys"]={KEY_ENTER}}
},
["AY-3-8500"]={
},
["ColecoVision"]={
	["^.*\.col$|^.*\.bin$|^.*\.rom$"]={
		["dir"]="Coleco",
		["keys"]={KEY_ENTER}},
	["^.*\.sg$"]={
		["dir"]="Coleco",
		["keys"]={KEY_DOWN, KEY_ENTER}}
},
["Gameboy"]={
	["^.*\.gbc$|^.*\.gb$"]={
		["dir"]="GAMEBOY",
		["keys"]={KEY_ENTER}}
},
["GBA"]={
	["^.*\.gba$"]={
		["dir"]="GBA",
		["load_time"]=6000,
		["keys"]={KEY_ENTER}}
},
["Genesis"]={
	["^.*\.bin$|^.*\.gen$|^.*\.md$"]={
		["dir"]="Genesis",
		["keys"]={KEY_ENTER}}
},
["MegaCD"]={
	["^.*\.cue$"]={
		["dir"]="MegaCD",
		["keys"]={KEY_ENTER}},
	["^.*\.bin$|^.*\.gen$|^.*\.md$"]={
		["dir"]="MegaCD",
		["keys"]={KEY_DOWN, KEY_DOWN, KEY_ENTER}},
},
["NeoGeo"]={
	[".*$"]={
		["dir"]="NeoGeo",
		["keys"]={KEY_ENTER}}
},
["NES"]={
	["^.*\.nes$|^.*\.fds$|^.*\.nsf$"]={
		["dir"]="NES",
		["keys"]={KEY_ENTER}},
	["^.*\.bin$"]={
		["dir"]="NES",
		["keys"]={KEY_DOWN, KEY_ENTER}}
},
["Odyssey2"]={
	["^.*\.bin$"]={
		["dir"]="ODYSSEY2",
		["keys"]={KEY_ENTER}}
},
["SMS"]={
	["^.*\.sms$|^.*\.sg$"]={
		["dir"]="SMS",
		["keys"]={KEY_ENTER}},
	["^.*\.gg$"]={
		["dir"]="SMS",
		["keys"]={KEY_DOWN, KEY_ENTER}}
},
["SNES"]={
	["^.*\.sfc$|^.*\.smc$|^.*\.bin$"]={
		["dir"]="SNES",
		["keys"]={KEY_ENTER}}
},
["TurboGrafx16"]={
	["^.*\.pce$|^.*\.bin$"]={
		["dir"]="TGFX16",
		["keys"]={KEY_ENTER}},
	["^.*\.sgx$"]={
		["dir"]="TGFX16",
		["keys"]={KEY_DOWN, KEY_ENTER}},
	["^.*\.cue$"]={
		["dir"]="TGFX16-CD",
		["keys"]={KEY_DOWN, KEY_DOWN, KEY_ENTER}},
},
["Vectrex"]={
	["^.*\.vec$|^.*\.bin$|^.*\.rom$"]={
		["dir"]="VECTREX",
		["keys"]={KEY_ENTER}}
	}
}

function press(key)
	print("Key", key)
	key_press(key)
	sleep(500)
end

if method =="boot" then
	error("Method not implemented yet")
elseif method =="rload" then
	-- Must have "core"
	-- Must have "rom"
	if cores[core] == nil then
		error("Unknown core")
	end

	dir = nil
	load_time = nil
	keys = nil
	for exp, config in pairs(cores[core]) do
		if match(exp, rom) then
			dir = config["dir"]
			load_time = config["load_time"]
			keys = config["keys"]
			break
		end
	end
	if dir == nil or keys == nil then
		error("Config not found for core")
	end

	dir = "/media/fat/" .. dir

	mount(rom, dir, function ()
		print(rom, dir)
		load_core(core_path)
		sleep(load_time == nil and load_time or 4000)
		press(KEY_ESC)
		press(KEY_F12)
		for i, key in pairs(keys) do
			press(key)
		end
		press(KEY_DOWN)
		press(KEY_ENTER)
		sleep(4000)
	end)
else
	error("Unknown method")
end
