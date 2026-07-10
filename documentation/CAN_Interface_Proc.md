# CAN Interface Specification - Processor Module

**Document Versie:** v1.0  
**Datum:** 2026-07-10  
**Tijd:** 22:00:00  
**Status:** DEFINITIEF - Interface Specificatie Processor Module

---

## 1. Inleiding

Dit document specificeert de CAN interface voor de Processor Module. Lees eerst **CAN_Interface_Common.md** voor de gemeenschappelijke specificaties.

**Processor Module verantwoordelijkheden:**
- ✅ Sensor data ontvangen en verwerken
- ✅ Actuator commando's versturen
- ✅ Actuator responses ontvangen en valideren
- ✅ IO Module configureren (sensor interval)
- ✅ Heartbeat versturen
- ✅ IO Module status monitoren

---

## 2. Platform

**Implementatie taal:** Qt Quick (C++/QML)  
**CAN Interface:** Platform-afhankelijk (SocketCAN Linux, PEAK, Vector, etc.)  
**Architecture:** Event-driven, asynchronous message handling

**Recommended libraries:**
- Qt SerialBus (Qt CAN Bus support)
- SocketCAN (Linux)
- PEAK PCAN driver (Windows/Linux)
- Vector CANlib (Windows)

---

## 3. TX Berichten (Processor → CAN Bus)

### 3.1 Heartbeat (Periodiek)

**CAN ID:** 0x0F0 (Processor Module)  
**DLC:** 2 bytes  
**Periode:** Elke 5 seconden (±100ms jitter acceptabel)  
**Prioriteit:** Hoog (system message)

**Data Format:**

| Byte | Naam | Type | Beschrijving |
|------|------|------|--------------|
| 0 | UPTIME_LOW | uint8_t | Uptime seconden LSB |
| 1 | UPTIME_HIGH | uint8_t | Uptime seconden MSB |

**Encoding:**
- Uptime = uint16_t little-endian (modulo 65536)
- Uptime wordt gereset na applicatie restart
- Uptime overflow na ~18 uur is acceptabel

**Implementatie vereisten:**
- MOET elke 5 seconden ±100ms verstuurd worden
- MAG een timer (QTimer in Qt) gebruiken voor nauwkeurige timing
- Uptime counter MAG application uptime gebruiken

---

### 3.2 Node Announce (Bij opstarten)

**CAN ID:** 0x0F1 (Processor Module announce)  
**DLC:** 8 bytes  
**Trigger:** Direct na CAN initialisatie, binnen 1 seconde na start  
**Eenmalig:** Alleen bij opstarten (niet periodiek)

**Data Format:**

| Byte | Naam | Type | Waarde | Beschrijving |
|------|------|------|--------|--------------|
| 0 | NODE_TYPE | uint8_t | 0x02 | Processor Module identifier |
| 1 | HW_VERSION | uint8_t | 0x01 | Hardware versie (v1.0) |
| 2 | SW_VER_MAJOR | uint8_t | 1 | Software major versie |
| 3 | SW_VER_MIN | uint8_t | 0 | Software minor versie |
| 4-7 | CAPABILITIES | uint32_t | 0x00000000 | Gereserveerd voor toekomstig gebruik |

**Implementatie vereisten:**
- MOET verstuurd worden binnen 1s na CAN initialisatie
- MOET correcte software versie bevatten
- Software versie MAG uit applicatie metadata gehaald worden

---

### 3.3 Valve Commands

**CAN ID:** 0x200  
**DLC:** 8 bytes  
**Trigger:** On-demand, wanneer applicatie valves wil aansturen  
**Prioriteit:** Normaal

**Data Format:**

| Byte | Naam | Type | Beschrijving |
|------|------|------|--------------|  
| 0 | VALVE_MASK | uint8_t | Bitmask: welke valves updaten (1=update) |
| 1 | VALVE_STATES | uint8_t | Gewenste states (1=open, 0=closed) |
| 2-7 | - | - | Padding (0x00) |

**VALVE_MASK en VALVE_STATES bits:**
- Bit 0 = Valve 0
- Bit 1 = Valve 1
- ...
- Bit 7 = Valve 7

**Gedrag:**
- Alleen valves waar VALVE_MASK bit=1 worden geupdate
- Voor elke valve waar mask=1: zet naar state gespecificeerd in VALVE_STATES
- Valves waar mask=0 blijven in huidige state op IO Module

**Implementatie vereisten:**
- Processor MOET na versturen wachten op response (CAN ID 0x300)
- Timeout voor response: 1 seconde
- Bij timeout: retry (max 3×, interval 500ms)
- Na 3 failures: rapporteer error aan applicatie

**Use cases:**
- **Enkele valve:** MASK=0x01, STATES=0x01 → Open valve 0
- **Meerdere valves:** MASK=0xFF, STATES=0xF0 → Valves 4-7 open, 0-3 dicht
- **Alle valves dicht:** MASK=0xFF, STATES=0x00

---

### 3.4 Binary Output Commands

**CAN ID:** 0x201  
**DLC:** 8 bytes  
**Trigger:** On-demand, wanneer applicatie outputs wil aansturen  
**Prioriteit:** Normaal

**Data Format:**

| Byte | Naam | Type | Beschrijving |
|------|------|------|--------------|  
| 0 | OUTPUT_MASK | uint8_t | Bitmask: welke outputs updaten (bits 0-2, rest 0) |
| 1 | OUTPUT_STATES | uint8_t | Gewenste states (bits 0-2: 1=on, 0=off) |
| 2-7 | - | - | Padding (0x00) |

**OUTPUT_MASK en OUTPUT_STATES bits:**
- Bit 0 = Binary Output 0
- Bit 1 = Binary Output 1
- Bit 2 = Binary Output 2
- Bits 3-7 = Gereserveerd (altijd 0)

**Implementatie vereisten:**
- Processor MOET na versturen wachten op response (CAN ID 0x301)
- Timeout voor response: 1 seconde
- Bij timeout: retry (max 3×, interval 500ms)
- Na 3 failures: rapporteer error aan applicatie

**Use cases:**
- **Enkele output:** MASK=0x01, STATES=0x01 → Zet output 0 aan
- **Alle outputs uit:** MASK=0x07, STATES=0x00

---

### 3.5 Set Sensor Interval

**CAN ID:** 0x400  
**DLC:** 8 bytes  
**Trigger:** Bij configuratie wijziging door gebruiker/applicatie  
**Prioriteit:** Laag

**Data Format:**

| Byte | Naam | Type | Beschrijving |
|------|------|------|--------------|  
| 0 | INTERVAL_SEC | uint8_t | Sensor interval in seconden (1-255) |
| 1-7 | - | - | Padding (0x00) |

**Implementatie vereisten:**
- Processor MOET interval valideren: 1 ≤ INTERVAL_SEC ≤ 255
- Processor MOET na versturen wachten op acknowledgement (CAN ID 0x300)
- Timeout voor ACK: 2 seconden
- Bij timeout: retry (max 3×, interval 500ms)
- Bij STATUS=0x01 in ACK: interval was invalid (should not happen if validated)

**Use cases:**
- Snelle monitoring: 1-5 seconden
- Normale monitoring: 10-30 seconden
- Langzame monitoring: 60-255 seconden

---

### 3.6 Status Request

**CAN ID:** 0x401  
**DLC:** 0-8 bytes (data wordt genegeerd door IO Module)  
**Trigger:** On-demand voor diagnostiek/monitoring  
**Prioriteit:** Laag

**Implementatie vereisten:**
- Processor MAG lege data versturen (DLC=0)
- Processor MOET wachten op status response (CAN ID 0x301)
- Timeout voor response: 1 seconde
- Bij timeout: IO Module is mogelijk offline

**Use cases:**
- Periodieke health check (bijv. elke 60s)
- On-demand diagnostiek (gebruiker klikt "Status opvragen")
- Troubleshooting tijdens development

---

## 4. RX Berichten (CAN Bus → Processor)

### 4.1 IO Module Heartbeat

**CAN ID:** 0x000 (IO Module 0)  
**DLC:** 2 bytes  
**Periode:** Elke 5 seconden (van IO Module)  
**Actie:** Registreer ontvangst, update "IO module alive" status

**Data Format:**

| Byte | Naam | Type | Beschrijving |
|------|------|------|--------------|  
| 0 | UPTIME_LOW | uint8_t | IO Module uptime LSB |
| 1 | UPTIME_HIGH | uint8_t | IO Module uptime MSB |

**Implementatie vereisten:**
- Processor MOET timestamp van laatste ontvangen heartbeat bijhouden
- Processor MOET IO Module als "alive" beschouwen als heartbeat binnen 15s ontvangen
- Processor MOET IO Module als "offline" beschouwen na 15s timeout (3× periode)
- Bij IO Module timeout:
  - Toon warning in UI
  - Stop versturen van commando's
  - Markeer sensor data als "stale"
- IO Module uptime MAG gebruikt worden voor diagnostiek/logging

**Timeout detectie:**
- Timeout threshold: 15 seconden (3× heartbeat periode)
- Bij timeout: Applicatie state update, UI notification

---

### 4.2 IO Module Announce

**CAN ID:** 0x001 (IO Module 0 announce)  
**DLC:** 8 bytes  
**Trigger:** Bij IO Module opstarten  
**Actie:** Registreer IO module als online, toon versie info

**Data Format:**

| Byte | Naam | Type | Beschrijving |
|------|------|------|--------------|
| 0 | NODE_TYPE | uint8_t | 0x01 = IO Module |
| 1 | HW_VERSION | uint8_t | Hardware versie |
| 2 | SW_VER_MAJOR | uint8_t | Software major versie |
| 3 | SW_VER_MIN | uint8_t | Software minor versie |
| 4-7 | CAPABILITIES | uint32_t | Gereserveerd (0x00000000) |

**Implementatie vereisten:**
- Processor MOET Node Announce verwerken en IO Module registreren
- Processor MAG versie info tonen in UI/log
- Processor MAG default configuratie versturen na announce (optioneel)

---

### 4.3 Sensor Data Messages

#### 4.3.1 Moisture Sensors (8× float waarden)

De 8 moisture sensor waarden worden verdeeld over 4 CAN berichten (2 floats per bericht).

**Bericht 1 - Moisture Sensors 0-1:**

| CAN ID | DLC | Byte 0-3 | Byte 4-7 |
|--------|-----|----------|----------|
| 0x100 | 8 | Moisture[0] (float) | Moisture[1] (float) |

**Bericht 2 - Moisture Sensors 2-3:**

| CAN ID | DLC | Byte 0-3 | Byte 4-7 |
|--------|-----|----------|----------|
| 0x101 | 8 | Moisture[2] (float) | Moisture[3] (float) |

**Bericht 3 - Moisture Sensors 4-5:**

| CAN ID | DLC | Byte 0-3 | Byte 4-7 |
|--------|-----|----------|----------|
| 0x102 | 8 | Moisture[4] (float) | Moisture[5] (float) |

**Bericht 4 - Moisture Sensors 6-7:**

| CAN ID | DLC | Byte 0-3 | Byte 4-7 |
|--------|-----|----------|----------|
| 0x103 | 8 | Moisture[6] (float) | Moisture[7] (float) |

**Data representatie:**
- Eenheid: Percentage (0.0 - 100.0) of sensor-specifieke eenheid
- Encoding: IEEE 754 single precision, little-endian
- Byte order: LSB eerst (bytes [0,1,2,3] voor eerste float)

**Implementatie vereisten:**
- Processor MOET floats correct decoden (IEEE 754 little-endian)
- Processor MOET alle 4 berichten verwerken voor complete moisture data
- Processor MAG data cachen tot volledige set ontvangen
- Processor MOET timestamp bijhouden van laatste update

---

#### 4.3.2 Pressure Sensors (3× float waarden)

De 3 pressure sensor waarden worden verdeeld over 2 CAN berichten.

**Bericht 1 - Pressure Sensors 0-1:**

| CAN ID | DLC | Byte 0-3 | Byte 4-7 |
|--------|-----|----------|----------|
| 0x104 | 8 | Pressure[0] (float) | Pressure[1] (float) |

**Bericht 2 - Pressure Sensor 2:**

| CAN ID | DLC | Byte 0-3 | Byte 4-7 |
|--------|-----|----------|----------|
| 0x105 | 8 | Pressure[2] (float) | 0x00000000 (padding) |

**Data representatie:**
- Eenheid: hPa (hectopascal) of bar
- Encoding: IEEE 754 single precision, little-endian

**Implementatie vereisten:**
- Zelfde als moisture sensors
- Padding bytes (4-7 in 0x105) MOETEN genegeerd worden

---

#### 4.3.3 Temperature Sensor (1× float waarde)

**Bericht - Temperature:**

| CAN ID | DLC | Byte 0-3 | Byte 4-7 |
|--------|-----|----------|----------|
| 0x106 | 8 | Temperature (float) | 0x00000000 (padding) |

**Data representatie:**
- Eenheid: °C (graden Celsius)
- Encoding: IEEE 754 single precision, little-endian

**Implementatie vereisten:**
- Processor MOET float correct decoden
- Padding bytes (4-7) MOETEN genegeerd worden

---

#### 4.3.4 Binary Inputs (3× boolean)

**Bericht - Binary Inputs:**

| CAN ID | DLC | Byte 0 | Byte 1-7 |
|--------|-----|--------|----------|
| 0x107 | 8 | INPUT_BITS | 0x00 (padding) |

**Data Format Byte 0:**

| Bit | Naam | Beschrijving |
|-----|------|--------------|
| 0 | INPUT_0 | Binary Input 0 (1=high, 0=low) |
| 1 | INPUT_1 | Binary Input 1 (1=high, 0=low) |
| 2 | INPUT_2 | Binary Input 2 (1=high, 0=low) |
| 3-7 | Reserved | Genegeerd (altijd 0x00) |

**Implementatie vereisten:**
- Processor MOET bits 0-2 extraheren
- Processor MOET bits 3-7 negeren
- Processor MAG boolean array maken voor UI/logic

**Voorbeeld decoding:**
```
Data byte 0 = 0x05 (0b00000101)
→ INPUT_0 = 1 (high)
→ INPUT_1 = 0 (low)
→ INPUT_2 = 1 (high)
```

---

### 4.4 Actuator Responses

#### 4.4.1 Valve Response

**CAN ID:** 0x300  
**DLC:** 8 bytes  
**Trigger:** Binnen 100ms na verzonden valve command  
**Actie:** Valideer uitvoering, update UI/state

**Data Format:**

| Byte | Naam | Type | Beschrijving |
|------|------|------|--------------|
| 0 | VALVE_STATES | uint8_t | Actuele valve states na uitvoering (bits 0-7) |
| 1 | STATUS | uint8_t | Execution status code |
| 2-7 | - | - | Padding (genegeerd) |

**Status Codes:**

| Code | Naam | Beschrijving |
|------|------|--------------|
| 0x00 | OK | Commando succesvol uitgevoerd |
| 0x01 | HW_ERROR | Hardware fout (valve driver error) |
| 0x02 | INVALID_CMD | Invalid commando parameters |

**VALVE_STATES bits:**
- Bit 0 = Valve 0 (1=open, 0=closed)
- Bit 1 = Valve 1 (1=open, 0=closed)
- ...
- Bit 7 = Valve 7 (1=open, 0=closed)

**Implementatie vereisten:**
- Processor MOET response matchen met verzonden command (tracking)
- Bij STATUS=0x00: update valve state in applicatie/UI
- Bij STATUS!=0x00: toon error, log voor diagnostiek
- Bij timeout (geen response binnen 1s): retry of error

---

#### 4.4.2 Binary Output Response

**CAN ID:** 0x301  
**DLC:** 8 bytes (of 2 bytes, zie onderscheid met status response)  
**Trigger:** Binnen 100ms na verzonden binary output command  
**Actie:** Valideer uitvoering, update UI/state

**Data Format:**

| Byte | Naam | Type | Beschrijving |
|------|------|------|--------------|
| 0 | OUTPUT_STATES | uint8_t | Actuele output states (bits 0-2, rest 0) |
| 1 | STATUS | uint8_t | Execution status code |
| 2-7 | - | - | Padding (genegeerd) |

**Status Codes:** (zelfde als valve response)

**OUTPUT_STATES bits:**
- Bit 0 = Output 0 (1=on, 0=off)
- Bit 1 = Output 1 (1=on, 0=off)
- Bit 2 = Output 2 (1=on, 0=off)
- Bits 3-7 = Reserved (altijd 0)

**Implementatie vereisten:**
- Zelfde als valve response
- Processor MOET bits 0-2 extraheren, bits 3-7 negeren

---

### 4.5 Configuration Acknowledgement

**CAN ID:** 0x300 (shared met valve response)  
**DLC:** 8 bytes  
**Trigger:** Binnen 100ms na verzonden config command  
**Onderscheid:** CMD_ID byte bepaalt type acknowledgement

**Data Format:**

| Byte | Naam | Type | Beschrijving |
|------|------|------|--------------|
| 0 | CMD_ID | uint8_t | Command identifier (0x00 = Set Interval) |
| 1 | STATUS | uint8_t | Execution status |
| 2-7 | - | - | Padding (genegeerd) |

**CMD_ID values:**

| Value | Beschrijving |
|-------|--------------|
| 0x00 | Set Sensor Interval |
| 0x01-0xFF | Gereserveerd |

**STATUS codes:**

| Code | Naam | Beschrijving |
|------|------|--------------|
| 0x00 | OK | Configuratie geaccepteerd |
| 0x01 | INVALID_VALUE | Parameter buiten toegestaan bereik |

**Implementatie vereisten:**
- Processor MOET response matchen met verzonden config command
- Bij STATUS=0x00: configuratie succesvol, update lokale state
- Bij STATUS=0x01: toon error ("Interval out of range")
- Bij timeout: retry of error

**Onderscheid tussen responses op CAN ID 0x300:**
- Valve response: Byte 0 bevat valve states (vaak ≠ 0x00)
- Config ACK: Byte 0 = 0x00 (CMD_ID voor Set Interval)

---

### 4.6 Status Response

**CAN ID:** 0x301 (shared met binary output response)  
**DLC:** 8 bytes  
**Trigger:** Binnen 500ms na verzonden status request  
**Onderscheid:** DLC=8 (status) vs DLC=2 (output response)

**Response Data Format:**

| Byte | Naam | Type | Beschrijving |
|------|------|------|--------------|  
| 0 | STATE | uint8_t | Huidige system state |
| 1 | ERROR_FLAGS | uint8_t | Error bitflags |
| 2 | CURRENT_INTERVAL | uint8_t | Huidige sensor interval (seconden) |
| 3 | UPTIME_LOW | uint8_t | Uptime LSB |
| 4 | UPTIME_HIGH | uint8_t | Uptime MSB |
| 5-7 | - | - | Gereserveerd (genegeerd) |

**STATE values:**

| Value | Naam | Beschrijving |
|-------|------|--------------|  
| 0x00 | INIT | Module initialiseert |
| 0x01 | RUNNING | Normaal operation |
| 0x02 | ERROR | Error state (zie ERROR_FLAGS) |
| 0x03 | SHUTDOWN | Graceful shutdown bezig |

**ERROR_FLAGS bits:**

| Bit | Beschrijving |
|-----|--------------|  
| 0 | Processor heartbeat timeout (IO ziet geen Processor) |
| 1 | CAN bus-off error |
| 2 | Sensor hardware fout |
| 3 | Actuator hardware fout |
| 4-7 | Gereserveerd |

**Implementatie vereisten:**
- Processor MOET status response verwerken en tonen in UI/diagnostiek
- ERROR_FLAGS MOETEN geïnterpreteerd worden (bit per bit)
- CURRENT_INTERVAL MAG gevalideerd worden tegen verwachte waarde
- UPTIME MAG gebruikt worden voor monitoring/logging

**Onderscheid tussen responses op CAN ID 0x301:**
- Status response: DLC=8, rijke data
- Binary output response: DLC=2 (of 8 met padding), beperkte data

---

## 5. Implementatie Requirements

### 5.1 CAN Controller Configuratie

**Hardware:**
- CAN 2.0A standard frames (11-bit identifier)
- Baudrate: 10 kbit/s
- Sample point: 87.5% (indien configureerbaar)
- Auto-retransmission: Enabled (hardware level)

**Qt SerialBus configuratie voorbeeld:**
- Plugin: "socketcan" (Linux), "peakcan", "vectorcan", etc.
- Bitrate: 10000 (10 kbit/s)
- Data bitrate: Not used (Classic CAN)

### 5.2 Message Filtering (Optioneel)

**Hardware filters (indien beschikbaar):**
- Filter alleen relevante CAN IDs (0x000-0x107, 0x300-0x301)
- Reject alle andere berichten

**Software filtering (fallback):**
- If hardware filters niet beschikbaar, filter in software
- Switch-case op CAN ID in RX handler

**Te accepteren CAN IDs:**

| CAN ID Range | Beschrijving |
|--------------|--------------|
| 0x000-0x007 | IO Module system messages |
| 0x100-0x107 | IO Module sensor data |
| 0x300-0x301 | IO Module actuator responses |

### 5.3 TX/RX Message Handling

**TX Requirements:**
- Berichten MOETEN non-blocking verstuurd worden
- Bij volle TX queue: wacht met timeout of return error
- DLC altijd 8 bytes (ook bij kortere payloads, rest padding)
- Standard ID (11-bit), niet Extended (29-bit)

**RX Requirements:**
- Gebruik signal/slot mechanisme (Qt) of callback voor RX events
- Berichten verwerken in event loop (non-blocking)
- Dispatcher functie routeert berichten naar juiste handler op basis van CAN ID
- Onbekende CAN IDs negeren (geen error, log optioneel)

---

## 6. Application State & Data Model

### 6.1 Sensor Data Model

**Data Structure (pseudo-code):**
```
SensorData {
    timestamp: DateTime           // Laatste update
    moisture: float[8]           // 8 moisture sensors
    pressure: float[3]           // 3 pressure sensors
    temperature: float           // 1 temperature sensor
    binary_inputs: bool[3]       // 3 binary inputs
    is_valid: bool               // Data is recent (< timeout)
}
```

**Update logic:**
- Bij ontvangst van sensor bericht: update data model
- Update timestamp
- Trigger UI update (signal/emit in Qt)
- Check data validity (timestamp < 30s oud, of 3× sensor interval)

### 6.2 Actuator State Model

**Data Structure (pseudo-code):**
```
ActuatorState {
    valves: bool[8]              // 8 valve states (commanded)
    binary_outputs: bool[3]      // 3 output states (commanded)
    valves_actual: bool[8]       // 8 valve states (from IO feedback)
    outputs_actual: bool[3]      // 3 output states (from IO feedback)
    pending_commands: Map<CommandID, Command>  // Awaiting response
}
```

**Command tracking:**
- Bij TX van command: voeg toe aan pending_commands met timestamp
- Bij RX van response: match met pending command, verwijder uit map
- Bij timeout: retry of error, verwijder uit map

### 6.3 IO Module Health Model

**Data Structure (pseudo-code):**
```
IOModuleHealth {
    is_online: bool              // Heartbeat binnen 15s
    last_heartbeat: DateTime
    hw_version: uint8
    sw_version: (major, minor)
    uptime: uint16
    state: IOModuleState         // INIT, RUNNING, ERROR, SHUTDOWN
    error_flags: uint8
    sensor_interval: uint8       // Current configured interval
}
```

**Health monitoring:**
- Periodiek check: is_online = (now - last_heartbeat < 15s)
- Bij offline: stop TX van commando's, toon warning
- Bij online na offline: optioneel re-configureer IO Module

---

## 7. Error Handling & Recovery

### 7.1 IO Module Timeout

**Detectie:**
- Geen heartbeat ontvangen binnen 15s

**Actie:**
- Set is_online = false
- Toon warning in UI: "IO Module offline"
- Stop versturen van commando's (queue wissen)
- Markeer sensor data als "stale"

**Recovery:**
- Bij ontvangst van nieuwe heartbeat of announce:
  - Set is_online = true
  - Toon "IO Module online" in UI
  - Optioneel: verstuur configuratie (sensor interval)
  - Hervat normale operatie

### 7.2 Command Timeout

**Detectie:**
- Geen response ontvangen binnen timeout (1-2s)

**Actie:**
1. Retry verzenden (max 3×, interval 500ms)
2. Na 3 retries:
   - Log error
   - Toon error in UI
   - Return failure naar applicatie logic

**Recovery:**
- Gebruiker kan opnieuw proberen
- Of: automatische retry op achtergrond (optioneel)

### 7.3 Invalid Response

**Detectie:**
- Response met STATUS != 0x00

**Actie:**
- Log error met details (CAN ID, status code, context)
- Toon error in UI met duidelijke beschrijving:
  - 0x01: "Hardware error op IO Module"
  - 0x02: "Invalid commando (software bug?)"
- Niet retransmit (command was ontvangen maar niet uitgevoerd)

---

## 8. Timing & Schedulering

### 8.1 Periodic Tasks

| Task | Interval | Tolerance | Implementation |
|------|----------|-----------|----------------|
| Heartbeat TX | 5.0s | ±100ms | QTimer met 5000ms interval |
| IO health check | 1.0s | ±500ms | QTimer met 1000ms interval |
| Sensor data timeout check | 10.0s | ±1s | Check bij sensor data ontvangst |

---

## 9. User Interface Requirements

### 9.1 CAN BUS Status Scherm

**Doel:** Real-time weergave van CAN communicatie status en diagnostiek.

**Vereiste UI elementen:**

| Element | Type | Data Source | Update Interval |
|---------|------|-------------|-----------------|
| CAN Bus Status | Label/Indicator | Bus state (OK/Error/Offline) | Real-time |
| IO Module Online Status | Indicator (groen/rood) | `IOModuleHealth.is_online` | 1s |
| Last Heartbeat | Timestamp | `IOModuleHealth.last_heartbeat` | 1s |
| IO Module Uptime | Label | `IOModuleHealth.uptime` | Bij heartbeat RX |
| Processor Uptime | Label | Processor internal counter | 1s |
| IO Module HW/SW Versie | Label | `IOModuleHealth.hw_version`, `sw_version` | Bij announce RX |
| Bus Load | Label (%) | Berekend uit message rate | 5s |
| Error Count | Label | Totaal aantal errors | Bij error |
| Last Error Message | Label | Laatste error beschrijving | Bij error |

**Functionaliteit:**
- ✅ Auto-refresh van status indicatoren
- ✅ Groene indicator wanneer IO Module online (heartbeat < 15s)
- ✅ Rode indicator wanneer IO Module offline (geen heartbeat)
- ✅ Oranje/gele indicator bij errors (error_flags != 0)
- ✅ Log van laatste 10-20 CAN berichten (optioneel, voor debug)
- ✅ "Reset Error Count" knop om error teller te wissen

**HBWT Bedrijfsstijl:**
- HBWT kleurenschema (bedrijfskleuren)
- HBWT logo
- HBWT lettertype (indien gespecificeerd)
- Consistente UI layout met andere schermen

---

### 9.2 Sensor Data Scherm

**Doel:** Real-time weergave van alle sensor waarden van IO Module.

**Vereiste UI elementen:**

#### Moisture Sensors (8 stuks)

| Element | Type | Data Source | Range | Update |
|---------|------|-------------|-------|--------|
| Moisture 0-7 | Label met value | `SensorData.moisture[0-7]` | 0-100 % | Bij sensor data RX |
| Moisture Timestamp | Label | `SensorData.last_update` | - | Bij sensor data RX |
| Moisture Status | Indicator | Data validity | OK/Stale/Offline | Real-time |

**Layout suggestie:** 8 labels in 2 rijen van 4, of verticale lijst.

#### Pressure Sensors (3 stuks)

| Element | Type | Data Source | Range | Update |
|---------|------|-------------|-------|--------|
| Pressure 0-2 | Label met value | `SensorData.pressure[0-2]` | 0-2000 mbar | Bij sensor data RX |
| Pressure Timestamp | Label | `SensorData.last_update` | - | Bij sensor data RX |
| Pressure Status | Indicator | Data validity | OK/Stale/Offline | Real-time |

**Layout suggestie:** 3 labels, horizontaal of verticaal.

#### Temperature Sensor (1 stuk)

| Element | Type | Data Source | Range | Update |
|---------|------|-------------|-------|--------|
| Temperature | Label met value | `SensorData.temperature` | -40 tot +85 °C | Bij sensor data RX |
| Temperature Timestamp | Label | `SensorData.last_update` | - | Bij sensor data RX |
| Temperature Status | Indicator | Data validity | OK/Stale/Offline | Real-time |

#### Binary Inputs (3 stuks)

| Element | Type | Data Source | State | Update |
|---------|------|-------------|-------|--------|
| Binary Input 0-2 | Indicator (LED/icon) | `SensorData.binary_inputs[0-2]` | ON (1) / OFF (0) | Bij sensor data RX |
| Binary Input Labels | Label | - | "Input 0", "Input 1", "Input 2" | Static |

**Layout suggestie:** 3 LED indicators met labels.

**Functionaliteit:**
- ✅ Auto-refresh van alle sensor waarden
- ✅ Data validity indicatoren (groen=recent, oranje=oud, rood=offline)
- ✅ Timestamp van laatste update (per sensor type)
- ✅ "Stale data" warning wanneer sensor data ouder dan 30s (of 3× sensor interval)
- ✅ Eenheden weergeven (%, mbar, °C)
- ✅ Sensor interval configuratie (via dropdown of input field, range 1-255s)
- ✅ "Request Update" knop om direct sensor data op te vragen (optioneel)

**HBWT Bedrijfsstijl:**
- HBWT kleurenschema
- Consistente layout met CAN BUS scherm
- Duidelijke labels en eenheden
- Professional look & feel

---

### 9.3 Actuator Control Scherm

**Doel:** Bediening van alle actuatoren (valves en binary outputs).

**Vereiste UI elementen:**

#### Valve Control (8 valves)

| Element | Type | Functie | Feedback |
|---------|------|---------|----------|
| Valve 0-7 Open Knop | Button | TX valve command (valve=1) | Groen bij open |
| Valve 0-7 Close Knop | Button | TX valve command (valve=0) | Grijs/uit bij dicht |
| Valve 0-7 Status Indicator | LED/Icon | Toont actuele state | Van IO feedback (0x300) |
| Valve 0-7 Label | Label | "Valve 0" t/m "Valve 7" | Static |

**Layout suggestie:**
- Tabel: 8 rijen, elke rij: Label | Open knop | Close knop | Status indicator
- Of: 8 toggle switches met status LED

**Gedrag:**
- Bij klik op "Open": TX valve command met MASK voor die valve, STATES=1
- Bij klik op "Close": TX valve command met MASK voor die valve, STATES=0
- Wacht op response (CAN ID 0x300) met timeout 1s
- Bij success: update status indicator
- Bij error: toon error message, laat oude status staan
- Bij timeout: retry (max 3×), daarna error

#### Binary Output Control (3 outputs)

| Element | Type | Functie | Feedback |
|---------|------|---------|----------|
| Output 0-2 ON Knop | Button | TX output command (output=1) | Groen bij ON |
| Output 0-2 OFF Knop | Button | TX output command (output=0) | Grijs/uit bij OFF |
| Output 0-2 Status Indicator | LED/Icon | Toont actuele state | Van IO feedback (0x301) |
| Output 0-2 Label | Label | "Output 0" t/m "Output 2" | Static |

**Layout suggestie:**
- Tabel: 3 rijen, elke rij: Label | ON knop | OFF knop | Status indicator
- Of: 3 toggle switches met status LED

**Gedrag:**
- Bij klik op "ON": TX output command met MASK voor die output, STATES=1
- Bij klik op "OFF": TX output command met MASK voor die output, STATES=0
- Wacht op response (CAN ID 0x301) met timeout 1s
- Bij success: update status indicator
- Bij error: toon error message, laat oude status staan
- Bij timeout: retry (max 3×), daarna error

**Functionaliteit:**
- ✅ Real-time feedback van actuator states (van IO Module responses)
- ✅ Command acknowledgement (groen flash bij success, rood bij error)
- ✅ Error messages bij command failures (duidelijke foutmelding)
- ✅ Disable knoppen wanneer IO Module offline (grijs uit)
- ✅ "All Valves Close" emergency knop (optioneel)
- ✅ "All Outputs OFF" emergency knop (optioneel)
- ✅ Command history log (laatste 10 commando's, optioneel voor debug)

**HBWT Bedrijfsstijl:**
- HBWT kleurenschema
- Grote, duidelijke knoppen (goed klikbaar)
- Consistente layout met andere schermen
- Professional look & feel
- Duidelijke visual feedback (groen=actief, grijs=uit, rood=error)

---

### 9.4 Algemene UI Requirements

**Navigatie:**
- ✅ Menu of tabbladen voor schakelen tussen:
  - CAN BUS Status scherm
  - Sensor Data scherm
  - Actuator Control scherm
- ✅ Duidelijke indicatie van actief scherm

**Responsive Design:**
- ✅ UI werkt op desktop (primair)
- ✅ Optioneel: tablet support (indien vereist)
- ✅ Minimum resolutie: 1024×768 (of HBWT standaard)

**Error Handling UI:**
- ✅ Duidelijke error messages (niet alleen error codes)
- ✅ Toast/notification voor tijdelijke meldingen
- ✅ Modal dialog voor kritieke errors
- ✅ Error log scherm (optioneel, voor debug/diagnostiek)

**HBWT Bedrijfsstijl Compliance:**
- ✅ HBWT kleurenpalet (exacte kleuren te verkrijgen van HBWT)
- ✅ HBWT logo placement (bijv. top-left of top-right)
- ✅ HBWT lettertype (indien gespecificeerd in styleguide)
- ✅ Consistente button styles, borders, shadows
- ✅ Professional, clean design
- ✅ Accessibility: voldoende contrast, leesbare tekst

**Performance:**
- ✅ UI updates < 100ms latency (sensor data, status updates)
- ✅ Smooth animations (indien gebruikt)
- ✅ Geen UI freezes bij CAN communicatie

**Qt Quick Implementatie Hints:**
- QML voor UI layout en styling
- C++ backend voor CAN communicatie
- QML property bindings voor auto-updates
- Qt Quick Controls 2 voor moderne UI componenten
- Signals/slots voor event handling

---

## 10. Samenvatting & Checklist

### Processor Module MOET implementeren:

**CAN Communicatie:**
- ✅ TX: Heartbeat (0x0F0, 5s), Announce (0x0F1, bij start)
- ✅ TX: Valve commands (0x200), Output commands (0x201)
- ✅ TX: Set sensor interval (0x400), Status request (0x401)
- ✅ RX: IO heartbeat (0x000), announce (0x001)
- ✅ RX: Sensor data (0x100-0x107)
- ✅ RX: Actuator responses (0x300-0x301)

**Error Handling:**
- ✅ IO Module timeout detectie (15s)
- ✅ Command retry logic (3×, 500ms)
- ✅ Invalid response handling

**Data Models:**
- ✅ SensorData met validity tracking
- ✅ ActuatorState met command tracking
- ✅ IOModuleHealth met online status

**User Interface:**
- ✅ CAN BUS Status scherm met real-time status
- ✅ Sensor Data scherm met alle sensor waarden in labels
- ✅ Actuator Control scherm met knoppen voor elke actuator
- ✅ HBWT bedrijfsstijl (kleuren, logo, lettertype)
- ✅ Error handling UI met duidelijke meldingen
- ✅ Responsive design en goede performance

---

**Document Einde**

### 8.2 Reactive Tasks

| Event | Max Response Time | Implementation |
|-------|-------------------|----------------|
| Valve command → Await response | 1000ms timeout | Start QTimer bij TX, cancel bij RX |
| Output command → Await response | 1000ms timeout | Start QTimer bij TX, cancel bij RX |
| Config command → Await ACK | 2000ms timeout | Start QTimer bij TX, cancel bij RX |
| Status request → Await response | 1000ms timeout | Start QTimer bij TX, cancel bij RX |

### 8.3 Bus Load Impact

Met default sensor interval van 10s:
- **Verwachte message rate:** ~1.2 msg/s (zie Common.md sectie 9)
- **Bus load:** ~1.5%
- **Overhead voor on-demand commando's:** < 0.1% (occasional)

→ Zeer lage bus load, geen timing issues verwacht

---

## 9. Test & Validatie

### 9.1 Interface Compliance Checklist

**CAN Bus Parameters:**
- [ ] Baudrate correct: 10 kbit/s (±0.5%)
- [ ] Standard 11-bit IDs (niet Extended 29-bit)
- [ ] Classic CAN frames (niet CAN FD)

**TX Messages - Timing:**
- [ ] Heartbeat periode: 5.0s (±100ms)
- [ ] Node Announce: binnen 1s na startup
- [ ] Command responses: binnen timeout (1-2s)

**TX Messages - Data Encoding:**
- [ ] Uptime: uint16_t little-endian
- [ ] Valve/Output masks en states correct
- [ ] Interval value: 1-255 range validation
- [ ] Padding bytes: 0x00

**RX Messages - Data Decoding:**
- [ ] Float decoding: IEEE 754 little-endian
- [ ] Moisture sensors: alle 8 waarden correct
- [ ] Pressure sensors: alle 3 waarden correct
- [ ] Temperature: correcte waarde
- [ ] Binary inputs: bits 0-2 correct geëxtraheerd
- [ ] Actuator responses: status codes correct geïnterpreteerd

**Error Handling:**
- [ ] IO Module timeout detectie (15s)
- [ ] Command timeout + retry (3×, 500ms)
- [ ] Invalid response handling (STATUS != 0x00)

### 9.2 Test Scenarios

**Scenario 1: Basic Communication**
1. Start Processor applicatie
2. Verify Node Announce binnen 1s (CAN ID 0x0F1)
3. Verify Heartbeat elke 5s (CAN ID 0x0F0)
4. Start IO Module
5. Verify IO Module Announce ontvangen en verwerkt
6. Verify Sensor data ontvangen en correct gedecoded

**Scenario 2: Actuator Control**
1. Gebruiker klikt "Open Valve 3"
2. Verify command verzonden: `0x200: [0x08, 0x08, 0, 0, 0, 0, 0, 0]`
3. Verify response ontvangen binnen 100ms
4. Verify UI update: valve 3 = open

**Scenario 3: Configuration**
1. Gebruiker wijzigt sensor interval naar 5s
2. Verify config command verzonden: `0x400: [0x05, 0, 0, 0, 0, 0, 0, 0]`
3. Verify ACK ontvangen binnen 100ms met STATUS=0x00
4. Verify sensor data nu elke 5s ontvangen wordt

**Scenario 4: IO Module Timeout**
1. Start met normale operatie (beide modules heartbeating)
2. Stop IO Module
3. Verify Processor detecteert timeout na 15s
4. Verify UI toont "IO Module offline"
5. Herstart IO Module
6. Verify Processor detecteert IO Module Announce
7. Verify UI toont "IO Module online"

**Scenario 5: Command Retry**
1. Disconnect CAN cable (simulate IO Module niet reachable)
2. Gebruiker klikt "Open Valve 0"
3. Verify command verzonden
4. Verify timeout na 1s
5. Verify retry 1 verzonden na 500ms
6. Verify retry 2 verzonden na 500ms
7. Verify retry 3 verzonden na 500ms
8. Verify error getoond in UI na 3 failures

### 9.3 Debug & Measurement Tools

**CAN Monitoring Tools:**
- candump (Linux): `candump can0`
- CANalyzer (Vector)
- PCAN-View (PEAK)
- Wireshark met SocketCAN plugin

**Qt Debugging:**
- QDebug output voor alle TX/RX messages
- QML debugging voor UI state changes
- Qt Creator debugger voor C++ backend

**Expected Dummy Values (v1.0):**
- **Moisture[0-7]:** 25.5, 27.5, 29.5, 31.5, 33.5, 35.5, 37.5, 39.5
- **Pressure[0-2]:** 1013.25, 250.0, 150.0
- **Temperature:** 21.5
- **Binary Inputs:** Toggles elke interval (0x00 → 0x01 → ... → 0x07)

---

## 10. Qt Implementation Hints

### 10.1 QCanBus Integration

**Initialization:**
```cpp
// Create CAN device
QCanBus *canBus = QCanBus::instance();
QString plugin = "socketcan";  // or "peakcan", "vectorcan"
QString interface = "can0";

QCanBusDevice *device = canBus->createDevice(plugin, interface);

// Configure bitrate
device->setConfigurationParameter(
    QCanBusDevice::BitRateKey, 10000);  // 10 kbit/s

// Connect signals
connect(device, &QCanBusDevice::framesReceived,
        this, &CANInterface::onFramesReceived);
connect(device, &QCanBusDevice::errorOccurred,
        this, &CANInterface::onErrorOccurred);

// Open device
device->connectDevice();
```

**TX Message:**
```cpp
void sendMessage(quint32 id, const QByteArray &data) {
    QCanBusFrame frame;
    frame.setFrameId(id);
    frame.setPayload(data);
    
    device->writeFrame(frame);
}
```

**RX Handler:**
```cpp
void onFramesReceived() {
    while (device->framesAvailable() > 0) {
        QCanBusFrame frame = device->readFrame();
        processFrame(frame.frameId(), frame.payload());
    }
}
```

### 10.2 Float Encoding/Decoding

**Encode float to bytes (little-endian):**
```cpp
QByteArray floatToBytes(float value) {
    QByteArray bytes(4, 0);
    memcpy(bytes.data(), &value, 4);
    return bytes;  // Little-endian on x86/ARM
}
```

**Decode bytes to float (little-endian):**
```cpp
float bytesToFloat(const QByteArray &bytes, int offset = 0) {
    float value;
    memcpy(&value, bytes.constData() + offset, 4);
    return value;
}
```

### 10.3 QML Integration

**Expose sensor data to QML:**
```cpp
// C++ class
class SensorDataModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(QList<float> moisture READ moisture NOTIFY moistureChanged)
    Q_PROPERTY(float temperature READ temperature NOTIFY temperatureChanged)
    // ... etc
    
signals:
    void moistureChanged();
    void temperatureChanged();
    
public slots:
    void updateMoisture(int index, float value);
};
```

**Use in QML:**
```qml
ListView {
    model: sensorDataModel.moisture
    delegate: Text {
        text: "Moisture " + index + ": " + modelData.toFixed(1) + "%"
    }
}
```

---

## 11. Versie Geschiedenis

| Versie | Datum | Tijd | Wijzigingen |
|--------|-------|------|-------------|
| v1.0 | 2026-07-10 | 22:00 | Initiële versie - taal-onafhankelijke interface specificatie |

---

**Document eigenaar:** iMC Project Team  
**Review status:** Approved voor implementatie  
**Target Platform:** Qt Quick (C++/QML)  
**Compatibiliteit:** Interface beschrijving is taal-onafhankelijk, maar bevat Qt-specifieke hints voor implementatie
