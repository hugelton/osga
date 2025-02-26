# OSGA - Ambient Sound Computer

OSGA is a specialized sound computer designed for creating ambient soundscapes, built on LÖVE2D with both a simulator and runtime environment for Raspberry Pi.

## Overview

OSGA is a dedicated hardware/software platform for ambient sound generation. It features a collection of sound apps.
Like: P.O.S.G. for Playdate that my product. https://hugelton.itch.io/posg


## Features

- **Multiple Sound Apps**: Various ambient sound generators including Amebako (rain), Densha (train), Shore (seaside), Buddha, Acidtest, and more
- **Real-time Parameter Control**: Each app offers adjustable parameters to create customized soundscapes
- **Hardware Integration**: Support for physical controls including buttons, rotary encoder, and motion sensing
- **Compact Interface**: Designed for small displays with a 320x240 resolution
- **Dual Environments**: Includes both a simulator (for development) and a runtime (for Raspberry Pi deployment)

## System Requirements

### For Hardware Runtime
- Raspberry Pi (currently tested on Zero W v1.1, planned migration to 3A+)
- Display: ILI9341 (fbcp) - planned migration to MIPI-DBI-SPI
- Raspberry Pi OS Lite (32-bit, planned migration to 64-bit)
- 
### For Simulator
- LÖVE2D 11.4+
- Any OS that runs LÖVE2D (Windows, macOS, Linux)



## Getting Started

### Running the Simulator

1. Install LÖVE2D 11.4 or newer
2. Clone this repository
3. Run the simulator:
   ```
   cd osga-folder
   love osga-sim
   ```

### Running on Raspberry Pi

1. Set up your Raspberry Pi with Raspberry Pi OS Lite
2. Install LÖVE2D on your Raspberry Pi
3. Clone this repository
4. Configure your display and input devices
5. Run the runtime:
   ```
   cd osga-folder
   love osga-run
   ```

## Controls

- **A/B/C Buttons**: App-specific functions (detailed in each app)
- **Rotary Encoder**: Adjust selected parameters
- **Rotary Button (R)**: Select parameter
- **Gyro/Accelerometer**: Motion-based controls in supported apps

## Sound Applications (Preset)

- **Acidtest**: TB-303-inspired bass sequencer
- **Amebako**: Rain and thunder ambient generator
- **Buddha**: Meditative sound generator
- **Densha**: Train journey simulator with environmental sounds
- **Mariawa**: Physics-based musical instrument
- **Shore**: Seaside ambient sound generator
- **Yoru**: Nighttime ambient environment

## Development

OSGA uses a custom API inspired by Playdate. Sound synthesis is based on the denver.lua library with extensions for more complex sound generation.

### API Structure

- `api/gfx.lua`: Graphics primitives
- `api/sound/`: Sound generation modules (include Denver.lua)
- `api/system.lua`: System utilities
- `api/font.lua`: Custom font handling (including NADA font)

## ToDo

- MIDI support for parameter control via CC messages
- Official app repository on GitHub
- Hardware migration to Raspberry Pi 3A+ with MIPI-DBI-SPI display

## License

This project is available under the LGPL v3 license. See the LICENSE file for details.

## Credits

- OSGA by Leo Kuroshita from Hugelton Instruments (2025)
- NADA font by Leo Kuroshita
- Sound generation based on denver.lua by SuperZazu with extensions https://github.com/superzazu/denver.lua
- Additional libraries: sone.lua by camchenry
