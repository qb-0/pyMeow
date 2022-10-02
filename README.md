# pyMeow <br><sup>[Discord](https://discord.gg/B34S4aMYqY)</sup>
pyMeow combines a memory module and functionality of [Raylib](https://www.raylib.com/) to a library which makes it easy to create external cheats:

<img src="https://github.com/qb-0/pyMeow./raw/master/examples/screenshots/csgo.png" alt="alt text" width="350" height="250"> <img src="https://github.com/qb-0/pyMeow./raw/master/examples/screenshots/sauerbraten.png" alt="alt text" width="350" height="250">
<img src="https://github.com/qb-0/pyMeow./raw/master/examples/screenshots/ac_esp_win.png" alt="alt text" width="350" height="250"> <img src="https://github.com/qb-0/pyMeow./raw/master/examples/screenshots/acdebug.png" alt="alt text" width="350" height="250">

## Cheatsheet / Features
An overview of the functionality can be found in the [Cheatsheet](https://github.com/qb-0/pyMeow./blob/master/cheatsheet.txt)

## Installation
- Make sure you use a **64bit** version of Python
- Download the latest PyMeow Module from the ![Release Section](https://github.com/qb-0/pyMeow./releases)
- Extract the files and use pip to install pyMeow: `pip install .`

## Compiling
```bash
# Install Nim and Git!

# Install requirements:
nimble install -y nimpy nimraylib_now x11 winim
# Clone the repository
git clone "https://github.com/qb-0/pyMeow." pyMeow
# Compile
cd pyMeow && nim c pyMeow
```