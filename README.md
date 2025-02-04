# osga : Organic Sound Generation Architecture

![License](https://img.shields.io/badge/License-GPLv3-blue.svg)

**osga is work in progress.**
<img width="1238" alt="osga_device_mock" src="https://github.com/user-attachments/assets/20c96b6a-c83a-40ca-aaec-3064d1db479b" />

## Overview

osga is non-musical sound device. A computer that allows you to program sound and vision. 

## Features

- Modular Lua-based scripting system
- Audio output via I2S DAC
- Visual feedback via LCD
- Motion sensing with IMU
- Web interface

## Hardware Architecture

```mermaid
graph TD
    RP[ Raspberry Pi Zero W ] -->|SPI| LCD[ILI9341 LCD]
    RP -->|I2S| DAC[PCM5102 DAC]
    RP -->|I2C| IMU[MPU6050]
    RP -->|GPIO| UI[UI Controls]
    DAC -->|Analog| SPK[Speaker]
    IMU -->|Motion| RP
    LCD -->|Display| VIZ[Visual]
```

## Installation

```bash
cd ~
wget https://raw.githubusercontent.com/hugelton/osga-setup/main/install.sh
chmod +x install.sh
./install.sh
sudo reboot
```

## Project Structure

```
osga/
├── osga-kage/    # Display subsystem
├── osga-nami/    # Audio engine
├── osga-koto/    # Sensor interface
├── osga-torii/   # Web interface
└── osga-kumo/    # Home screen 
```

## Module Example

```lua
block = {}

function block.init()
  -- Initialization
end

function block.draw()
  kage.clear(0)
  kage.drawBox(0,0,squareSize,squareSize)
  kage.draw()
end

function block.update()
  -- Updates
end
```

## License

This project is licensed under the **GNU General Public License v3.0**. See [LICENSE](LICENSE) for full terms.

## Community

- Issues: [GitHub Issues](https://github.com/hugelton/osga/issues)
- Hardware: [osga-hardware](https://github.com/hugelton/osga-hardware)
- Forum: [OSGA Discourse](https://github.com/hugelton/osga/discussions/)
