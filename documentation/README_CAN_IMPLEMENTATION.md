# qtphy - HBWT iMC vX Display Application

**Project:** HBWT iMC vX Irrigation Controller  
**Application:** qtphy v0.3.2 (Qt6 Display Interface)  
**Hardware:** PHYTEC phyBOARD-Nash i.MX93 @ 192.168.178.206  
**Date:** 8-10 Juli 2026

---

## 📍 Project Locatie

```
/home/phyvm/customer_projects/HBWT/Phycore/imx93/qtphy/qtphy-0.3.2/
```

**Directory Structuur:**
```
qtphy-0.3.2/
├── src/                    # C++ source files
│   ├── main.cpp           # App entry point
│   ├── device_info.cpp/hpp
│   ├── rauc.cpp/hpp
│   └── can_controller.cpp/hpp  # ✨ NEW: CAN implementation
├── resources/             # QML UI en assets
│   ├── main.qml          # Main menu
│   ├── pages/            # UI paginas
│   │   ├── dashboard.qml
│   │   ├── about.qml
│   │   └── can_status.qml  # ✨ NEW: CAN Status UI
│   └── resources.qrc     # Qt resource file
├── build/                 # Meson/Ninja build (werkende versie)
├── build-qmake/          # qmake build (huidige CAN build)
├── meson.build           # Meson build configuratie
├── qtphy.pro             # qmake build configuratie
└── README.md             # Originele Phytec README

Deployed op board: /usr/bin/qtphy
```

---

## 🔧 Build Tooling

### Cross-Compile Environment

**SDK:** Yocto Scarthgap 5.0.18 (Phytec ampliPHY Distribution)
```bash
# SDK locatie
/opt/sysroots/x86_64-phytecsdk-linux/     # Build tools (qmake, moc, rcc, g++)
/opt/sysroots/cortexa55-phytec-linux/     # Target libraries (Qt6, libc, kernel headers)
```

**Target Platform:**
- **Architecture:** ARM aarch64 (Cortex-A55)
- **Qt Version:** Qt 6.8.1
- **Backend:** Wayland (weston compositor)
- **Compiler:** aarch64-phytec-linux-g++ 13.3.0

### Build Systeem #1: Meson + Ninja (Origineel)

**Voordelen:** Officieel Phytec build systeem, sneller, declaratief

```bash
cd /home/phyvm/customer_projects/HBWT/Phycore/imx93/qtphy/qtphy-0.3.2/

# Configure (met cross-compile setup)
cd build/
meson --reconfigure

# Build
ninja -C build

# Output
build/qtphy        # Binary: ~3.7 MB
```

**Configuratie:** `meson.build`
- Automatic Qt6 module detection
- Cross-compile via `/opt/sysroots/.../meson.cross`
- MOC, RCC, UIC tool detection

**Status:** Used voor originele versie, nu handmatig bijgewerkt voor CAN support.

### Build Systeem #2: qmake + make (Huidig CAN Build)

**Voordelen:** Simpeler, geen meson Qt6 tool detection issues, snelle iteratie

```bash
cd /home/phyvm/customer_projects/HBWT/Phycore/imx93/qtphy/qtphy-0.3.2/

# Configure
mkdir -p build-qmake && cd build-qmake
qmake ..

# Build
make clean
make -j$(nproc)

# Output
build-qmake/qtphy  # Binary: ~4.5 MB (met CAN support)
```

**Configuratie:** `qtphy.pro`
```qmake
TEMPLATE = app
TARGET = qtphy

QT += qml quick dbus

SOURCES += \
    src/main.cpp \
    src/device_info.cpp \
    src/rauc.cpp \
    src/can_controller.cpp    # ✨ CAN implementation

HEADERS += \
    src/device_info.hpp \
    src/rauc.hpp \
    src/can_controller.hpp    # ✨ CAN interface

RESOURCES += resources/resources.qrc
```

**qmake locatie:** `/opt/sysroots/x86_64-phytecsdk-linux/usr/bin/qmake`

### Deployment naar Board

**Methode 1: Handmatig SCP**
```bash
cd build-qmake/

# Stop running app
ssh root@192.168.178.206 "systemctl stop qtphy.service"

# Deploy binary
scp qtphy root@192.168.178.206:/usr/bin/qtphy

# Start app
ssh root@192.168.178.206 "systemctl start qtphy.service"
```

**Methode 2: Via Systemd Service**
```bash
# Check status
ssh root@192.168.178.206 "systemctl status qtphy.service"

# View logs
ssh root@192.168.178.206 "journalctl -u qtphy.service -n 50 --no-pager"
```

**Service Configuratie:** `/etc/systemd/system/qtphy.service`
```ini
[Unit]
Description=Qt6 Demo Application (qtphy)
Requires=weston.service
After=weston.service

[Service]
Environment=WAYLAND_DISPLAY=/run/wayland-0
Environment=QT_QPA_PLATFORM=wayland
Environment=XDG_RUNTIME_DIR=/run/user/0
ExecStart=/usr/bin/qtphy
User=root
Restart=always

[Install]
WantedBy=graphical.target
```

### Build Workflow Samenvatting

```bash
# 1. Edit source files
vim src/can_controller.cpp

# 2. Build
cd build-qmake && make -j$(nproc)

# 3. Deploy
scp qtphy root@192.168.178.206:/usr/bin/

# 4. Restart app
ssh root@192.168.178.206 "systemctl restart qtphy.service"

# 5. Monitor logs
ssh root@192.168.178.206 "journalctl -u qtphy.service -f"
```

---

## 🚀 CAN Implementation (8-9 Juli 2026)

### Overzicht

**Doel:** CAN bus master functionaliteit voor slave node discovery en monitoring

**Protocol:** SocketCAN (Linux native CAN stack)

**Hardware:**
- **Controller:** NXP FlexCAN2 @ 0x443a0000
- **Transceiver:** TCAN1051HVDQ1 (TI automotive)
- **Connector:** M12, 5-pin (CAN_H, CAN_L, GND)
- **Bitrate:** 10 kbps (debug mode, was 500 kbps)

### Geïmplementeerde Bestanden

#### 1. **src/can_controller.hpp** (130 regels)

**Purpose:** Qt/QML bridge voor SocketCAN interface

**API:**
```cpp
class CANController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(bool initialized READ initialized NOTIFY initializedChanged)
    Q_PROPERTY(int discoveredCount READ discoveredCount NOTIFY discoveredCountChanged)
    Q_PROPERTY(QVariantList nodes READ nodes NOTIFY nodesChanged)
    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)
    
public:
    Q_INVOKABLE bool initCAN(const QString &interface = "can0", int bitrate = 10000);
    Q_INVOKABLE void shutdownCAN();
    Q_INVOKABLE void scanBus();
    Q_INVOKABLE void clearNodes();
};
```

**Properties:**
- `status`: CAN interface status string
- `initialized`: CAN socket open & configured
- `discoveredCount`: Aantal gevonden nodes
- `nodes`: QVariantList met node details
- `scanning`: Scan in progress

#### 2. **src/can_controller.cpp** (450+ regels)

**Purpose:** SocketCAN implementation met async frame handling

**Key Functions:**
```cpp
bool initCAN(const QString &interface, int bitrate)
    // 1. Open raw CAN socket
    // 2. Configure bitrate via 'ip link set can0 type can bitrate 10000'
    // 3. Bring interface UP
    // 4. Setup QSocketNotifier voor async RX

void scanBus()
    // Broadcast CAN frame: ID=0x100, Data=[0x01, SCAN, 0, 0, 0, 0, 0, 0]
    // Start 5s timeout timer
    
void onCANReadable()
    // Async callback bij incoming CAN frame
    // Parse frame, extract node info, update m_discoveredNodes

bool configureInterface(const QString &interface, int bitrate)
    // ip link set can0 down
    // ip link set can0 type can bitrate 10000
    // ip link set can0 up
```

**CAN Protocol:**
```
Master → Broadcast (ID=0x100):
  [0x01, CMD_SCAN, 0, 0, 0, 0, 0, 0]

Slave → Response (ID=0x200 + nodeId):
  [nodeId, deviceType, fwMajor, fwMinor, status, reserved, reserved, reserved]
```

**Supported Device Types:**
- 0x01 = Valve Controller
- 0x02 = Sensor Module  
- 0x03 = Pump Controller
- 0x04 = Display Module

**Linux Headers:**
```cpp
#include <linux/can.h>
#include <linux/can/raw.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
```

#### 3. **resources/pages/can_status.qml** (350+ regels)

**Purpose:** CAN Status UI met HBWT styling

**Features:**
- Status indicator (groen/rood LED)
- "Scan Bus" button met loading state
- Node table met kolommen:
  - Node ID (hex)
  - Device Type (naam)
  - Firmware Version
  - Status (text)
- Error message display
- Real-time updates via property bindings

**Styling:**
```qml
// HBWT Colors
primaryColor: "#27ae60"     // Teal
accentColor: "#16a085"      // Dark teal
bgDark: "#1c1c1c"           // Background
textColor: "#ecf0f1"        // Light grey
```

**QML Binding:**
```qml
CANController {
    id: canController
    onStatusChanged: statusText.text = status
    onNodesChanged: nodeListModel.clear()
}

Button {
    text: "Scan Bus"
    enabled: canController.initialized && !canController.scanning
    onClicked: canController.scanBus()
}
```

#### 4. **src/main.cpp** Wijzigingen

**Registratie Qt Type:**
```cpp
#include "can_controller.hpp"

int main(int argc, char *argv[])
{
    // Register C++ type voor QML
    qmlRegisterType<CANController>("hbwt.can", 1, 0, "CANController");
    
    // Add "CAN Bus" to enabled pages
    QStringList enabledPages;
    enabledPages << "Dashboard" << "Widget Factory" 
                 << "About HBWT" << "CAN Bus";  // ✨ NEW
    
    engine.rootContext()->setContextProperty("enabledPages", enabledPages);
}
```

#### 5. **resources/main.qml** Wijzigingen

**Menu Item:**
```qml
ListElement {
    title: "CAN Bus"
    icon: "qrc:/images/icons/network.png"  
    page: "pages/can_status.qml"
}
```

#### 6. **resources/resources.qrc** Update

```xml
<RCC>
    <qresource prefix="/">
        <file>pages/can_status.qml</file>  <!-- ✨ NEW -->
        <file>pages/dashboard.qml</file>
        <file>pages/about.qml</file>
    </qresource>
</RCC>
```

### Kernel Driver Setup (8 Juli 2026)

**Problem:** FlexCAN module gecompileerd maar niet gedeployed

**Solution:**
```bash
# 1. Deploy kernel modules tarball
scp build/tmp/deploy/images/phyboard-nash-imx93-1/modules--*.tgz root@192.168.178.206:/tmp/
ssh root@192.168.178.206 "cd / && tar -xzf /tmp/modules*.tgz"

# 2. Rebuild module dependencies
ssh root@192.168.178.206 "depmod -a"

# 3. Load FlexCAN driver
ssh root@192.168.178.206 "modprobe flexcan"

# 4. Configure auto-load
ssh root@192.168.178.206 "echo 'flexcan' > /etc/modules-load.d/can.conf"

# 5. Verify
ssh root@192.168.178.206 "ip link show can0"
# Output: can0: <NOARP,UP,LOWER_UP,ECHO> mtu 72 ... state UP
```

**Kernel Config:**
```
CONFIG_CAN=m
CONFIG_CAN_RAW=m
CONFIG_CAN_FLEXCAN=m
CONFIG_CAN_DEV=m
```

**Device Tree:** (sources/meta-hbwt-display/.../imx93-phyboard-nash-tfp410.dts)
```dts
&flexcan2 {
    status = "okay";
    pinctrl-names = "default";
    pinctrl-0 = <&pinctrl_flexcan2>;
};
```

### CAN Interface Configuratie

**Manual Setup:**
```bash
# Set bitrate en bring UP
ip link set can0 down
ip link set can0 type can bitrate 10000
ip link set can0 up

# Details
ip -details link show can0
# Output:
#   bitrate 10000 sample-point 0.875
#   tq 1250 prop-seg 37 phase-seg1 32 phase-seg2 10
#   state ERROR-ACTIVE (ready for use)
```

**CLI Testing:**
```bash
# Send test frame
cansend can0 100#0102030405060708

# Monitor bus
candump can0

# Statistics
ip -s link show can0
```

### Wayland Display Fix (8 Juli 2026)

**Problem:** Qt app crashed met "Failed to create wl_display"

**Root Cause:** Wayland socket `/run/user/0/wayland-1` niet aangemaakt na reboot

**Solution:**
```bash
# Restart weston compositor
systemctl restart weston.service

# Verify socket
ls -la /run/user/0/wayland-1
# Output: srwxr-xr-x 1 root root 0 ... /run/user/0/wayland-1

# Now qtphy works
systemctl start qtphy.service
```

**Lesson:** Weston restart sometimes needed after system changes to recreate socket.

---

## 🧪 Testing & Verificatie

### CAN Hardware Test

```bash
# 1. Check CAN interface
ssh root@192.168.178.206 "ip link show can0"

# 2. Check bitrate
ssh root@192.168.178.206 "ip -details link show can0 | grep bitrate"
# Expected: bitrate 10000 sample-point 0.875

# 3. Send test frame
ssh root@192.168.178.206 "cansend can0 100#0102030405060708"

# 4. Monitor with candump
ssh root@192.168.178.206 "candump can0 &"
ssh root@192.168.178.206 "cansend can0 123#DEADBEEF"
# Expected: can0  123  [4] DE AD BE EF
```

### Qt App Test

**Via UI:**
1. Boot board → qtphy auto-starts
2. Display shows main menu
3. Select "CAN Bus" → CAN Status pagina opent
4. Click "Scan Bus" → broadcast 0x100 frame
5. Slave responses → tabel wordt gevuld

**Via Logs:**
```bash
ssh root@192.168.178.206 "journalctl -u qtphy.service -f"

# Expected output:
# [CAN] Initializing interface: can0 at 10000 bps
# [CAN] CAN socket created: FD=X
# [CAN] Broadcast scan request: ID=0x100
# [CAN] Received frame: ID=0x201 from nodeId=1
```

### Debug Tips

**Check CAN driver:**
```bash
lsmod | grep can
dmesg | grep flexcan
```

**Check Wayland:**
```bash
ls -la /run/user/0/wayland*
ps aux | grep weston
```

**Check qtphy process:**
```bash
ps aux | grep qtphy
systemctl status qtphy.service
```

---

## 📚 Referenties

**Hardware:**
- [PHYTEC phyBOARD-Nash i.MX93 Manual](https://www.phytec.de/produkte/single-board-computer/phyboard-nash/)
- [NXP FlexCAN Controller Reference](https://www.nxp.com/docs/en/reference-manual/IMX93RM.pdf) (Chapter 35)
- [TI TCAN1051 Transceiver Datasheet](https://www.ti.com/lit/ds/symlink/tcan1051.pdf)

**Software:**
- [SocketCAN Documentation](https://www.kernel.org/doc/html/latest/networking/can.html)
- [Qt6 Documentation](https://doc.qt.io/qt-6/)
- [Yocto Scarthgap Manual](https://docs.yoctoproject.org/5.0/)

**Git Commits:**
- `31cedc2` (2026-07-05): CAN device tree support
- `909ec83` (2026-07-08): CAN kernel modules deployment

**Documentation:**
- `/home/phyvm/yocto/CleanBuild_20260619/documentation/CAN_DRIVER_DEPLOYMENT_FIX_20260708.md`
- `/home/phyvm/yocto/CleanBuild_20260619/documentation/USB_CAN_IMPLEMENTATION.md`

---

## 🎯 Volgende Stappen

### Todo

- [ ] Test met echte CAN slaves (valve controllers)
- [ ] Implement CAN command sending (actief aansturen valves)
- [ ] Add node configuration UI
- [ ] CAN error handling improvements
- [ ] Data logging (CAN frame capture)

### Mogelijk

- [ ] CAN-FD support (2 Mbps data phase)
- [ ] ISO-TP multi-frame support (>8 bytes)
- [ ] UDS diagnostics protocol
- [ ] OTA firmware updates via CAN

---

**Last Updated:** 10 Juli 2026  
**Author:** GitHub Copilot (Claude Sonnet 4.5) + User  
**Contact:** HBWT iMC vX Project Team
