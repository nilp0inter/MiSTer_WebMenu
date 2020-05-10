# MiSTer WebMenu

![Build](https://github.com/nilp0inter/MiSTer_WebMenu/workflows/Build/badge.svg)

<p align="center">
  <kbd>
  <img alt="Screenshot" src="/assets/capture.gif" />
  </kbd>
</p>

## Installation

1. Download `webmenu.sh` from [the latest release](https://github.com/nilp0inter/MiSTer_WebMenu/releases/latest) and copy it to the `Scripts` directory in your SD card.

2. Start your MiSTer, go to **Scripts** and launch `webmenu`.

3. Open your web browser and point to *http://\<your-mister-ip-address\>*



## Goals
  - Control your MiSTer device from a secondary screen (computer, tablet or phone web browser)
  - Launch cores and games with a single click (independtly of which core is currently running)
  - Manage game collections, playing stats, favourites... 

## Constraints
  - Minimal resource usage: all hard work should be done in the secondary device
  - No modifications: no special MiSTer versions or config modifications
  - Single install step: Once the WebMenu single-distribution-file is in your system you can always update it through the web interface without having to take out your SD never again
  - No interference: WebMenu **WILL NEVER** modify your system in a permanent way.  Just press *reset* and you are back to normal.

## Project Status

The project is in early alpha, the implemented features should work for standard MiSTer setups, but the code is far from being optimal.

I am not accepting new code pull requests at this stage, but I'd appreciate if you can:

- Test it!  And if something is not working properly, please [fill a bug report](https://github.com/nilp0inter/MiSTer_WebMenu/issues/new?assignees=nilp0inter&labels=bug&template=bug_report.md&title=).
- [Contribute your ideas](https://github.com/nilp0inter/MiSTer_WebMenu/issues/new?assignees=nilp0inter&labels=enhancement&template=feature_request.md&title=) about new features.
- [Give feedback](https://github.com/nilp0inter/MiSTer_WebMenu/issues/new?assignees=nilp0inter&labels=user+feedback&template=user-feedback.md&title=). Do you like it? Hate it?
- [Ask anything](https://github.com/nilp0inter/MiSTer_WebMenu/issues/new?assignees=nilp0inter&labels=question&template=question.md&title=%3CShort+question+here%3E%3F) you don't understand.

## Roadmap

- [x] Collection of installed cores & MRA
  - [x] Scan SD for cores & MRA
  - [x] List by category
  - [x] Search by name
  - [x] Launch them from the web interface
- [x] Update from the Web UI
- [ ] Collection of installed roms
  - [ ] Scan SD for games
  - [ ] Filter by metadata (name, platform, genre, favourite...)
  - [ ] Launch games from the web interface
  - [ ] Mark favourite games
- [ ] Configuration management
- [ ] Community feed
- [ ] Device information (available capacity, resources...)


Did I miss something? Fill a [feature request](https://github.com/nilp0inter/MiSTer_WebMenu/issues/new?assignees=nilp0inter&labels=enhancement&template=feature_request.md&title=).

