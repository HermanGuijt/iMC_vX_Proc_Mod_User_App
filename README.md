# iMC vX - Processor Module User Application

**Project:** HBWT iMC vX Irrigation Controller  
**Component:** Processor Module User Interface Application  
**Platform:** PHYTEC phyBOARD-Nash i.MX93 (ARM Cortex-A55)  
**Framework:** Qt6 (Qt Quick / QML)  
**Version:** 0.3.2

---

## 📋 Overview

Qt6-based user interface application for the iMC vX Processor Module. Provides real-time monitoring and control of the irrigation system via CAN bus communication with IO Module(s).

**Key Features:**
- ✅ CAN bus master interface (SocketCAN, 10 kbit/s)
- ✅ Real-time sensor data display (moisture, pressure, temperature, binary inputs)
- ✅ Actuator control interface (valves, binary outputs)
- ✅ IO Module health monitoring and diagnostics
- ✅ HBWT corporate styling and branding
- ✅ Wayland/Weston display backend

---

## 🔧 Hardware Platform

**Board:** PHYTEC phyBOARD-Nash i.MX93  
**SoC:** NXP i.MX93 (Dual Cortex-A55 @ 1.7 GHz)  
**CAN Controller:** FlexCAN2 (NXP native)  
**CAN Transceiver:** TCAN1051HVDQ1 (TI automotive)  
**Display:** HDMI via TFP410 (DVI transmitter)  
**OS:** Yocto Scarthgap 5.0.18 (Phytec ampliPHY Distribution)

---

## 🚀 Building

### Prerequisites

Cross-compile environment must be sourced:
```bash
source /opt/environment-setup-cortexa55-phytec-linux
export PATH=/opt/sysroots/x86_64-phytecsdk-linux/usr/libexec:$PATH
```

### Build with qmake (Recommended)

```bash
mkdir -p build-qmake && cd build-qmake
qmake ..
make -j$(nproc)
```

Binary output: `build-qmake/qtphy` (~4.5 MB)

### Build with Meson (Alternative)

```bash
meson setup build --wipe
meson compile -C build
```

Binary output: `build/qtphy` (~3.7 MB)

---

## 📡 CAN Bus Implementation

### Protocol Specification

- **Protocol:** CAN 2.0A (Standard Frame, 11-bit ID)
- **Baudrate:** 10 kbit/s
- **Interface:** SocketCAN (`can0`)
- **Topology:** Master (Processor) ↔ Slave (IO Module)

### Hardware Setup

```bash
# Configure CAN interface
ip link set can0 type can bitrate 10000
ip link set can0 up

# Verify
ip -details link show can0
```

See [`documentation/CAN_Interface_Common.md`](documentation/CAN_Interface_Common.md) for complete CAN protocol specification.

---

## 🖥️ User Interface

### Screens

1. **CAN Bus Status** - Real-time CAN communication monitoring
2. **Sensor Data** - Live sensor readings from IO Module
3. **Actuator Control** - Valve and output control interface
4. **Dashboard** - System overview
5. **About** - Version and system information

### Styling

HBWT corporate design with custom Qt Quick Controls theme:
- Primary color: `#27ae60` (teal)
- Background: `#1c1c1c` (dark)
- Accent: `#16a085` (dark teal)

---

## 📦 Deployment

### Deploy to Board

```bash
# Stop running application
ssh root@192.168.178.124 "systemctl stop qtphy.service"

# Copy binary
scp build-qmake/qtphy root@192.168.178.124:/usr/bin/qtphy

# Restart application
ssh root@192.168.178.124 "systemctl start qtphy.service"
```

### Systemd Service

Application runs as systemd service: `qtphy.service`

```bash
# Check status
systemctl status qtphy.service

# View logs
journalctl -u qtphy.service -f
```

---

## 📚 Documentation

- [`README_CAN_IMPLEMENTATION.md`](documentation/README_CAN_IMPLEMENTATION.md) - Complete CAN implementation guide
- [`CAN_Interface_Common.md`](documentation/CAN_Interface_Common.md) - CAN protocol specification (common)
- [`CAN_Interface_Proc.md`](documentation/CAN_Interface_Proc.md) - CAN protocol specification (Processor Module)

---

## 🏗️ Project Structure

```
qtphy-0.3.2/
├── src/                        # C++ source files
│   ├── main.cpp               # Application entry point
│   ├── can_controller.cpp/hpp # CAN bus interface (SocketCAN)
│   ├── device_info.cpp/hpp    # Device information
│   └── rauc.cpp/hpp           # RAUC update support
├── resources/                  # QML UI and assets
│   ├── main.qml               # Main menu navigation
│   ├── pages/                 # UI screens
│   │   ├── can_status.qml     # CAN Status screen
│   │   ├── dashboard.qml      # Dashboard overview
│   │   └── about.qml          # About screen
│   └── PhyStyle/              # Custom Qt Quick Controls
├── documentation/              # Technical documentation
├── meson.build                # Meson build configuration
└── qtphy.pro                  # qmake build configuration
```

---

## 🧪 Testing

### CAN Hardware Test

```bash
# Send test frame
cansend can0 100#0102030405060708

# Monitor bus
candump can0
```

### Application Test

```bash
# Monitor application logs
journalctl -u qtphy.service -f
```

---

## 🔒 License

Based on PHYTEC's *qtphy* reference implementation (MIT License).

HBWT-specific modifications and CAN implementation:  
**Copyright © 2026 HBWT - iMC vX Project**

See `LICENSE` for full terms and conditions.

---

## 👥 Credits

**Original qtphy:**
- PHYTEC Messtechnik GmbH
- Maintainer: Martin Schwan

**iMC vX Processor Module Application:**
- HBWT iMC vX Project Team
- Developer: Herman Guijt

---

**Last Updated:** July 10, 2026  
**Repository:** https://github.com/HermanGuijt/iMC_vX_Proc_Mod_User_App
