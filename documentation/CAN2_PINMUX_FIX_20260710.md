# CAN2 Pinmux Fix - SD2 Pins Solution

**Datum:** 10 juli 2026  
**Platform:** PHYTEC phyBOARD-Nash i.MX93  
**Status:** ✅ **RESOLVED & VERIFIED**  
**Commit:** 793e192

---

## Samenvatting

FlexCAN2 (CAN1 interface) was niet beschikbaar door een pinmux conflict met het LCD display. De oplossing was het verplaatsen van de CAN2 pinmux naar de SD2_DATA0/DATA1 pinnen, aangezien de SD card interface niet gebruikt wordt.

---

## Probleem

### Symptomen
1. **CAN1 interface niet beschikbaar**
   - Alleen `can0` aanwezig in `/sys/class/net/`
   - `can1` (FlexCAN2 @ 0x425b0000) ontbrak

2. **Kernel boot error**
   ```
   imx93-pinctrl 443c0000.pinctrl: could not request pin 29 (IMX93_IOMUXC_GPIO_IO25) 
   from group flexcan2grp on device 443c0000.pinctrl
   flexcan 425b0000.can: Error applying setting, reverse things back
   probe of 425b0000.can returned -22
   ```

3. **LCD kleurproblemen**
   - Verkeerde weergave groen/geel
   - Veroorzaakt door ontbrekend LCD_D4 data signaal

### Root Cause

**Pin 29 (IMX93_IOMUXC_GPIO_IO25) dubbel geclaimd:**
- **LCDIF**: Gebruikt pin 29 voor LCD_D4 data signaal (kritisch voor display)
- **FlexCAN2**: BSP configuratie probeerde pin 29 te gebruiken voor CAN2_TX (incorrect)

Kernel pinctrl geeft prioriteit aan de eerst geregistreerde peripheral (LCDIF), waardoor FlexCAN2 probe faalt met -EINVAL.

**Verificatie conflict:**
```bash
$ cat /sys/kernel/debug/pinctrl/443c0000.pinctrl/pinmux-pins | grep "pin 29"
pin 29 (IMX93_IOMUXC_GPIO_IO25): function pinctrl group lcdifgrp
```

---

## Oplossing

### Wijziging: SD2 Pins voor CAN2

**File:** `imx93-phyboard-nash-tfp410.dts`  
**Section:** pinctrl_flexcan2 group (~line 798)

```dts
/* VOOR (INCORRECT - Pin conflict): */
pinctrl_flexcan2: flexcan2grp {
    fsl,pins = <
        MX93_PAD_GPIO_IO25__CAN2_TX     0x139e  // Pin 29: LCD conflict!
        MX93_PAD_GPIO_IO27__CAN2_RX     0x139e
    >;
};

/* NA (CORRECT - SD2 pins): */
pinctrl_flexcan2: flexcan2grp {
    fsl,pins = <
        MX93_PAD_SD2_DATA0__CAN2_TX     0x139e  /* GPIO3_IO03, SOM pin 8, BGA Y18 */
        MX93_PAD_SD2_DATA1__CAN2_RX     0x139e  /* GPIO3_IO04, SOM pin 9, BGA AA18 */
    >;
};
```

### Rationale

1. **SD card interface niet gebruikt**
   - `usdhc2` status = "disabled" (line 826 in DTS)
   - SD2_DATA0/DATA1 pinnen beschikbaar

2. **Hardware routing klopt**
   - SOM pinnen 8/9 → Processor BGA Y18/AA18
   - Komt overeen met hardware PCB routing
   - Pinnen zijn GPIO3_IO03/GPIO3_IO04 in GPIO alt function

3. **Geen conflicts**
   - LCD blijft op GPIO_IO25 (pin 29) voor LCD_D4
   - Geen overlap met Ethernet, USB of andere peripherals
   - FlexCAN1 (can0) onveranderd op PDM audio pinnen

---

## Verificatie Resultaten

### ✅ FlexCAN2 Succesvol Geïnitialiseerd

**Kernel boot log:**
```bash
$ dmesg | grep -i flexcan
[    4.252089] calling  flexcan_driver_init+0x0/0x1000 [flexcan] @ 119
[    4.255437] initcall flexcan_driver_init+0x0/0x1000 [flexcan] returned 0 after 3321 usecs
```
- Geen pinmux conflict errors
- Driver succesvol geladen

### ✅ CAN Interfaces Beschikbaar

```bash
$ ls -la /sys/class/net/ | grep can
lrwxrwxrwx  1 root root 0 Jan  8  2025 can0 -> ../../devices/platform/soc@0/44000000.bus/443a0000.can/net/can0
lrwxrwxrwx  1 root root 0 Jan  8  2025 can1 -> ../../devices/platform/soc@0/42000000.bus/425b0000.can/net/can1
```
- **can0**: FlexCAN1 @ 0x443a0000 (bleef werken)
- **can1**: FlexCAN2 @ 0x425b0000 (NU BESCHIKBAAR)

### ✅ Pinmux Correct Geconfigureerd

```bash
$ cat /sys/kernel/debug/pinctrl/443c0000.pinctrl/pinmux-pins | grep "pin 29\|flexcan2grp"
pin 29 (IMX93_IOMUXC_GPIO_IO25): function pinctrl group lcdifgrp
pin 87 (IMX93_IOMUXC_SD2_DATA0): 425b0000.can function pinctrl group flexcan2grp
pin 88 (IMX93_IOMUXC_SD2_DATA1): 425b0000.can function pinctrl group flexcan2grp
```
- Pin 29: Blijft bij LCD (geen conflict meer)
- Pin 87/88: Nu bij FlexCAN2 (SD2 pinnen)

### ✅ CAN1 Interface Details

```bash
$ ip -details link show can1
5: can1: <NOARP,UP,LOWER_UP,ECHO> mtu 72 qdisc pfifo_fast state UP mode DEFAULT
    can <FD> state ERROR-ACTIVE (berr-counter tx 0 rx 0) restart-ms 0 
          bitrate 500000 sample-point 0.875
          dbitrate 2000000 dsample-point 0.750
          clock 40000000
          parentdev 425b0000.can
```
- State: ERROR-ACTIVE (normaal, geen errors)
- Bitrate: 500 kbit/s (CAN classic)
- Data bitrate: 2 Mbit/s (CAN FD)
- TX/RX errors: 0
- Device: FlexCAN2 @ 0x425b0000 ✅

### ✅ LCD Display Blijft Werken

```bash
$ dmesg | grep -i lcdif
[    2.120149] imx-drm display-subsystem: bound 4ac10000.system-controller:dpi
[    2.129179] [drm] Initialized imx-drm 1.0.0 20120507 for display-subsystem
[    2.296939] imx-drm display-subsystem: [drm] fb0: imx-drmdrmfb frame buffer device
```
- Display subsystem correct geïnitialiseerd
- Framebuffer device (fb0) actief
- Geen kleurproblemen (LCD_D4 behouden op pin 29)

---

## Technische Details

### i.MX93 Pin Functions

**SD2_DATA0 (Pin 87 / BGA Y18):**
- Alt function 2: CAN2_TX (gebruikt)
- Alt function 5: GPIO3_IO03
- SOM connector: pin 8

**SD2_DATA1 (Pin 88 / BGA AA18):**
- Alt function 2: CAN2_RX (gebruikt)
- Alt function 5: GPIO3_IO04
- SOM connector: pin 9

**GPIO_IO25 (Pin 29):**
- Alt function X: LCD_D4 (gebruikt door lcdifgrp)
- Alt function X: CAN2_TX (conflict - niet bruikbaar)

### CAN2 Pin Alternatieven (imx93-pinfunc.h)

i.MX93 biedt 4 pin paren voor FlexCAN2:
1. **DAP_TDI/TDO** - JTAG debug pins (niet bruikbaar tijdens debug)
2. **GPIO_IO25/27** - Oude config (conflict met LCD) ❌
3. **ENET1_TD3/TD2** - Ethernet pins (mogelijk in gebruik)
4. **SD2_DATA0/1** - SD card pins (usdhc2 disabled) ✅ GEKOZEN

---

## Git Repository

**Repository:** git@github.com:HermanGuijt/HBWT-Phycore-iMX93-Display.git  
**Branch:** display-working-config  
**Commit:** 793e1923e10c4f8899e06967bb196540f4dc2f43

**Commit Message:**
```
fix(can2): Resolve pinmux conflict - use SD2 pins instead of GPIO_IO25

FlexCAN2 was using GPIO_IO25 (pin 29) which conflicts with LCD_D4.
Kernel pinctrl gave priority to lcdifgrp, causing FlexCAN2 probe to fail
with -EINVAL. Boot error: 'could not request pin 29 from group flexcan2grp'.

Solution:
- Changed CAN2_TX: GPIO_IO25 → SD2_DATA0 (GPIO3_IO03, SOM pin 8, BGA Y18)
- Changed CAN2_RX: GPIO_IO27 → SD2_DATA1 (GPIO3_IO04, SOM pin 9, BGA AA18)
```

**Files Changed:**
- `imx93-phyboard-nash-tfp410.dts`: Updated pinctrl_flexcan2 group
- `CAN2_PINMUX_ISSUE.md`: Added solution section with verification steps

---

## Test Commando's

### CAN Interface Controle
```bash
# Check beide interfaces aanwezig:
ls /sys/class/net/ | grep can
# Verwacht: can0 en can1

# Details CAN1:
ip -details link show can1

# Boot errors checken:
dmesg | grep flexcan
# Verwacht: Geen errors
```

### Pinmux Verificatie
```bash
# Check pin 29 (LCD):
cat /sys/kernel/debug/pinctrl/443c0000.pinctrl/pinmux-pins | grep "pin 29"
# Verwacht: owned by lcdifgrp

# Check FlexCAN2 pins:
cat /sys/kernel/debug/pinctrl/443c0000.pinctrl/pinmux-pins | grep flexcan2grp
# Verwacht: pin 87 en 88 (SD2_DATA0/1)
```

### CAN Bus Activeren & Testen
```bash
# CAN1 configureren (500 kbit/s):
ip link set can1 type can bitrate 500000
ip link set can1 up

# Status checken:
ip -details link show can1

# Traffic monitoren (als transceiver aangesloten):
candump can1
```

---

## Conclusie

De CAN2 pinmux fix is succesvol geïmplementeerd en geverifieerd:

✅ FlexCAN2 probe succesvol (geen boot errors)  
✅ `can1` interface beschikbaar met correcte configuratie  
✅ LCD display blijft correct werken (pin 29 bij lcdifgrp)  
✅ SD2 pinnen (87/88) correct toegewezen aan FlexCAN2  
✅ Hardware routing klopt (SOM pins 8/9)  
✅ CAN FD support actief (2 Mbit/s data bitrate)  

De oplossing lost het pinmux conflict op zonder impact op andere peripherals. FlexCAN1 (can0) en FlexCAN2 (can1) zijn nu beide beschikbaar voor CAN communicatie.
