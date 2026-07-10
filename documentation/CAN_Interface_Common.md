# CAN Interface Specification - Common

**Document Versie:** v1.0  
**Datum:** 2026-07-10  
**Tijd:** 21:30:00  
**Status:** DEFINITIEF - Strict Interface Contract

---

## 1. Inleiding

Dit document definieert de gemeenschappelijke CAN bus specificaties voor communicatie tussen de Processor Module en IO Module(s) in het iMC systeem. Dit is een **strict interface contract** - alle implementaties moeten exact aan deze specificatie voldoen.

---

## 2. Fysieke Laag

### 2.1 CAN Configuratie
- **Protocol:** CAN 2.0A (Standard Frame, 11-bit identifier)
- **Baudrate:** 10 kbit/s
- **Sample Point:** 87.5% (typisch voor lage baudrates)
- **Synchronization Jump Width:** 1 TQ
- **Bus terminatie:** 120Ω aan beide uiteinden

### 2.2 Rationale Baudrate Keuze
De lage baudrate van 10 kbit/s is gekozen voor:
- Maximale robuustheid tegen storingen
- Langere kabellengte mogelijk (tot 1000m)
- Eenvoudige debugging met oscilloscoop/logic analyzer
- Voldoende bandbreedte voor de lage data-intensiteit van dit systeem

---

## 3. Data Encoding

### 3.1 Byte Order
- **Endianness:** Little-endian (LSB eerst)
- **Rationale:** Native voor ARM Cortex-M processors (STM32), meest gebruikelijk in embedded systemen

### 3.2 Data Types

| Type | Bytes | Format | Range | Gebruik |
|------|-------|--------|-------|---------|
| `float` | 4 | IEEE 754 single precision | ±3.4E±38 | Sensor waarden |
| `uint8_t` | 1 | Unsigned integer | 0-255 | Flags, kleine getallen |
| `uint16_t` | 2 | Unsigned integer | 0-65535 | Timers, grotere getallen |
| `bool` | 1 bit | Bit in byte | 0 of 1 | Digitale I/O |

**Opmerking:** Voor sensor waarden wordt `float` (4 bytes) gebruikt in plaats van `double` (8 bytes) vanwege CAN frame limiet van 8 bytes. Float precisie is ruim voldoende voor deze toepassing.

---

## 4. CAN Message ID Schema

### 4.1 ID Structuur (11-bit)

```
Bit: 10  9  8  7  6  5  4  3  2  1  0
     [MSG_TYPE][MODULE_ID][SUB_TYPE  ]
     └─3 bits─┘└─4 bits──┘└─4 bits───┘
```

- **MSG_TYPE (bits 10-8):** Type bericht (0x0-0x7)
- **MODULE_ID (bits 7-4):** IO Module identifier (0x0-0xF, max 16 modules)
- **SUB_TYPE (bits 3-0):** Subtype binnen message type (0x0-0xF)

### 4.2 Message Types

| MSG_TYPE | Waarde | Beschrijving | ID Range |
|----------|--------|--------------|----------|
| SYSTEM | 0x0 | System management berichten | 0x000-0x0FF |
| SENSOR | 0x1 | Sensor data van IO → Processor | 0x100-0x1FF |
| COMMAND | 0x2 | Actuator commando's Processor → IO | 0x200-0x2FF |
| RESPONSE | 0x3 | Actuator responses IO → Processor | 0x300-0x3FF |
| CONFIG | 0x4 | Configuratie berichten | 0x400-0x4FF |

### 4.3 Schaalbaarheid
- **Module ID 0x0:** Gereserveerd voor eerste/primaire IO module
- **Module ID 0x1-0xE:** Beschikbaar voor toekomstige IO modules
- **Module ID 0xF:** Gereserveerd voor Processor Module / broadcast

---

## 5. System Messages (0x0xx)

### 5.1 Heartbeat

**Doel:** Nodes tonen dat ze actief zijn op de bus.

| Module | CAN ID | DLC | Data | Periode |
|--------|--------|-----|------|---------|
| IO Module 0 | 0x000 | 2 | `[uptime_low, uptime_high]` | 5s |
| Processor | 0x0F0 | 2 | `[uptime_low, uptime_high]` | 5s |

**Data bytes:**
- Byte 0-1: Uptime in seconden (uint16_t), max 65535s (~18 uur)

**Timeout detectie:** Als er 3 heartbeats gemist worden (15s), wordt de node als offline beschouwd.

### 5.2 Node Announce

**Doel:** Node meldt zich aan bij opstarten.

| Richting | CAN ID | DLC | Data |
|----------|--------|-----|------|
| IO → All | 0x0X1 | 8 | `[NODE_TYPE, HW_VER, SW_VER_MAJ, SW_VER_MIN, CAPABILITIES[4]]` |

**Data bytes:**
- Byte 0: `NODE_TYPE` (0x01 = IO Module, 0x02 = Processor)
- Byte 1: `HW_VER` (hardware versie, bijv. 0x01 voor v1.0)
- Byte 2: `SW_VER_MAJ` (software major versie)
- Byte 3: `SW_VER_MIN` (software minor versie)
- Byte 4-7: `CAPABILITIES` (bitflags voor toekomstig gebruik, nu 0x00000000)

**Voorbeeld:** IO Module v1.0 met firmware v1.2:
```
CAN ID: 0x001
Data: [0x01, 0x01, 0x01, 0x02, 0x00, 0x00, 0x00, 0x00]
```

### 5.3 Node Leave

**Doel:** Node meldt zich af (graceful shutdown).

| Richting | CAN ID | DLC | Data |
|----------|--------|-----|------|
| IO → All | 0x0X2 | 1 | `[REASON]` |

**REASON codes:**
- 0x00: Normal shutdown
- 0x01: Error condition
- 0x02: Watchdog reset imminent
- 0xFF: Unknown/unspecified

---

## 6. Error Handling & Robuustheid

### 6.1 Timeouts

| Event | Timeout | Actie |
|-------|---------|-------|
| Heartbeat gemist | 15s (3× periode) | Node offline markeren |
| Actuator response | 1s | Retry versturen (max 3×) |
| Config acknowledge | 2s | Retry versturen (max 3×) |

### 6.2 CAN Bus Errors

**Bus-off recovery:**
- Bij bus-off state: automatische recovery na 128× 11 recessive bits
- Controller reset en opnieuw initialiseren
- Node Announce versturen na recovery

**Error counters:**
- RX/TX error counters monitoren
- Bij error-passive state (>127 errors): warning loggen
- Bij bus-off state: recovery procedure starten

### 6.3 Retry Strategy

Voor critical messages (actuator commando's, configuratie):
- **Max retries:** 3
- **Retry interval:** 500ms
- **Backoff:** Geen (vaste interval)
- **Failure handling:** Na 3 retries, error aan applicatie doorgeven

### 6.4 Message Lost Detection

CAN native acknowledgement wordt gebruikt (CAN 2.0A ACK bit). Er is geen applicatie-level sequence numbering in v1.0.

**Toekomstige uitbreiding:** Sequence numbers kunnen toegevoegd worden in v2.0 indien nodig.

---

## 7. Timing & Schedulering

### 7.1 Sensor Data Interval
- **Default interval:** 10 seconden
- **Configureerbaar range:** 1-255 seconden
- **Configuratie via:** CONFIG message (zie sectie 8)

### 7.2 Message Prioriteiten

Lagere CAN ID = hogere prioriteit op de bus.

**Prioriteit volgorde (hoog → laag):**
1. System messages (0x0xx) - hoogste prioriteit
2. Sensor data (0x1xx)
3. Actuator commands (0x2xx)
4. Actuator responses (0x3xx)
5. Configuration (0x4xx) - laagste prioriteit

**Rationale:** Bij deze lage bus load (10 kbit/s) zijn expliciete prioriteiten niet kritisch, maar het ID schema ondersteunt natuurlijke prioritering.

---

## 8. Configuration Messages (0x4xx)

### 8.1 Set Sensor Interval

**Richting:** Processor → IO

| CAN ID | DLC | Data |
|--------|-----|------|
| 0x4X0 | 1 | `[INTERVAL_SEC]` |

**Data:**
- Byte 0: `INTERVAL_SEC` (1-255 seconden)

**Response:** IO stuurt binnen 100ms een actuator response met status:
- CAN ID: 0x300
- Data: `[CMD_ID=0x00, STATUS]` (STATUS: 0x00=OK, 0x01=Invalid value)

### 8.2 Status Request

**Richting:** Processor → IO

| CAN ID | DLC | Data |
|--------|-----|------|
| 0x4X1 | 0 | - |

**Response:** IO stuurt binnen 500ms een status bericht:
- CAN ID: 0x301
- Data: `[STATE, ERROR_FLAGS, CURRENT_INTERVAL, UPTIME_LOW, UPTIME_HIGH, 0, 0, 0]`

**Data bytes:**
- Byte 0: `STATE` (0x00=Init, 0x01=Running, 0x02=Error, 0x03=Shutdown)
- Byte 1: `ERROR_FLAGS` (bitflags, 0x00=geen errors)
- Byte 2: `CURRENT_INTERVAL` (huidige sensor interval in seconden)
- Byte 3-4: `UPTIME` (uint16_t, uptime in seconden)
- Byte 5-7: Gereserveerd (0x00)

---

## 9. Bus Load Berekening

### 9.1 Worst-case Scenario
**Aannames:**
- Sensor interval: 10 seconden
- Heartbeat interval: 5 seconden (beide nodes)
- Alle sensor data + heartbeats

**Message count per 10 seconden:**
- Heartbeat IO: 2 berichten
- Heartbeat Processor: 2 berichten
- Moisture sensors: 4 berichten (8 floats, 2 per bericht)
- Pressure sensors: 2 berichten (3 floats)
- Temperature: 1 bericht
- Binary inputs: 1 bericht
- **Totaal:** ~12 berichten per 10 seconden = 1.2 msg/s

**Bitrate berekening:**
- CAN frame: ~128 bits (worst-case met stuffing)
- 1.2 msg/s × 128 bits = ~154 bits/s
- **Bus load:** 154 / 10000 = **1.54%**

**Conclusie:** Zeer lage bus load, voldoende ruimte voor toekomstige uitbreidingen.

---

## 10. Compliance & Validatie

### 10.1 Implementatie Vereisten

Beide modules MOETEN:
- ✅ Exact deze CAN IDs gebruiken
- ✅ Little-endian byte order implementeren
- ✅ IEEE 754 float encoding gebruiken
- ✅ Heartbeat elke 5s versturen
- ✅ Heartbeat timeout na 15s detecteren
- ✅ Node announce bij opstarten versturen
- ✅ Retry logic implementeren volgens sectie 6.3
- ✅ Timeout handling implementeren volgens sectie 6.1

### 10.2 Test Criteria

**Minimale test suite:**
1. Heartbeat transmit & receive met timeout detectie
2. Node announce/leave procedure
3. Data encoding/decoding (float conversie)
4. Error recovery (bus-off scenario)
5. Retry mechanism (gesimuleerde message loss)
6. Interval configuratie

---

## 11. Versie Geschiedenis

| Versie | Datum | Wijzigingen |
|--------|-------|-------------|
| v1.0 | 2026-07-10 21:30 | Initiële versie - strict interface contract |

---

## 12. References

- ISO 11898-1:2015 - CAN Protocol Specification
- IEEE 754-2008 - Floating Point Arithmetic
- ARM Cortex-M0+ Technical Reference Manual

---

**Document eigenaar:** iMC Project Team  
**Review status:** Approved voor implementatie
