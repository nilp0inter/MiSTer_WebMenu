# MiSTer_WebMenu

![GitHub release (latest by date)](https://img.shields.io/github/v/release/nilp0inter/MiSTer_WebMenu)
![Build](https://github.com/nilp0inter/MiSTer_WebMenu/workflows/Build/badge.svg)

## Goals
  - Control your MiSTer device from a secondary screen (computer, tablet or phone web browser)
  - Launch cores and games with a single click (independtly of which core is currently running)
  - Manage game collections, playing stats, favourites... 

## Constraints
  - Minimal resource usage: all hard work should be done in the secondary device
  - No modifications: no special MiSTer versions or config modifications
  - Single install step: Once the WebMenu single-file distribution is in your system you can always update it through the web interface
  - No interference: WebMenu **WILL NEVER** modify your system in a permanent way.  Just press *reset* and you are back to normal.

![Screenshot](/assets/capture.gif)

## Project Status

The project is in early alpha, the implemented features should work for standard MiSTer setups, but the code is far from being optimal.

I am not accepting new code pull requests at this stage, but I'd appreciate if you can:

- Test it!  If something is not working properly, please open an [issue](https://github.com/nilp0inter/MiSTer_WebMenu/issues).
- Contribute your ideas about new features.
- Give your feedback. Do you like it? Hate it? Open an issue or send me a tweet ([@nilp0inter](https://twitter.com/nilp0inter))

## Usage Instructions

1. Download `webmenu.sh` from [the latest release](https://github.com/nilp0inter/MiSTer_WebMenu/releases/latest) and copy it to the `Scripts` directory in your SD card.

2. Start your MiSTer, go to **Scripts** and launch `webmenu`.

3. Open your web browser and point to *http://\<your-mister-ip-address\>*

## Features

- [x] Collection of installed cores
  - [x] Scan SD for cores
  - [x] List by category
  - [x] Search by name
  - [x] Launch cores from the web interface
- [ ] Collection of installed roms
  - [ ] Scan SD for games
  - [ ] Filter by metadata (name, platform, genre, favourite...)
  - [ ] Launch games from the web interface
  - [ ] Mark favourite games
- [ ] Configuration management
- [ ] Community feed
- [ ] Device information (available capacity, resources...)
- [ ] Auto-update

Do you miss something? Open an [issue](https://github.com/nilp0inter/MiSTer_WebMenu/issues).

