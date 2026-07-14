/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2026 HB Watertechnologie
 * 
 * CAN Bus Controller Implementation for iMC vX Processor Module
 * Implements CAN_Interface_Proc.md specification
 */

#include "can_controller.hpp"
#include "can_logger.hpp"
#include <QDebug>
#include <QProcess>
#include <QThread>
#include <cstring>
#include <cmath>

// Linux SocketCAN headers
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <linux/can.h>
#include <linux/can/raw.h>
#include <net/if.h>
#include <unistd.h>

// ════════════════════════════════════════════════════════════════════════════
// Constructor / Destructor
// ════════════════════════════════════════════════════════════════════════════

CANController::CANController(QObject *parent)
    : QObject(parent)
    , m_socketFd(-1)
    , m_socketNotifier(nullptr)
    , m_heartbeatTimer(nullptr)
    , m_healthCheckTimer(nullptr)
    , m_commandResponseTimer(nullptr)
    , m_logger(nullptr)
    , m_status("Not initialized")
    , m_initialized(false)
    , m_processorUptime(0)
{
    // Setup heartbeat timer (TX every 5s)
    m_heartbeatTimer = new QTimer(this);
    m_heartbeatTimer->setInterval(HEARTBEAT_INTERVAL_MS);
    connect(m_heartbeatTimer, &QTimer::timeout, this, &CANController::onHeartbeatTimer);
    
    // Setup health check timer (check IO module online status every 1s)
    m_healthCheckTimer = new QTimer(this);
    m_healthCheckTimer->setInterval(HEALTH_CHECK_INTERVAL_MS);
    connect(m_healthCheckTimer, &QTimer::timeout, this, &CANController::onHealthCheckTimer);
    
    // Setup command response timeout timer (single-shot)
    m_commandResponseTimer = new QTimer(this);
    m_commandResponseTimer->setSingleShot(true);
    connect(m_commandResponseTimer, &QTimer::timeout, this, &CANController::onCommandResponseTimeout);
    
    // Create CAN logger
    m_logger = new CANLogger(this);
}

CANController::~CANController()
{
    shutdownCAN();
}

// ════════════════════════════════════════════════════════════════════════════
// Property Getters
// ════════════════════════════════════════════════════════════════════════════

QString CANController::ioModuleVersion() const
{
    if (m_ioHealth.swMajor == 0 && m_ioHealth.swMinor == 0) {
        return "Unknown";
    }
    return QString("HW v%1 / SW v%2.%3")
        .arg(m_ioHealth.hwVersion)
        .arg(m_ioHealth.swMajor)
        .arg(m_ioHealth.swMinor);
}

QString CANController::ioModuleStateText() const
{
    switch (m_ioHealth.state) {
        case 0x00: return "Initializing";
        case 0x01: return "Running";
        case 0x02: return "Error";
        case 0x03: return "Shutdown";
        default: return "Unknown";
    }
}

QVariantList CANController::moistureSensors() const
{
    QVariantList list;
    for (int i = 0; i < 8; ++i) {
        list.append(m_sensorData.moisture[i]);
    }
    return list;
}

QVariantList CANController::pressureSensors() const
{
    QVariantList list;
    for (int i = 0; i < 3; ++i) {
        list.append(m_sensorData.pressure[i]);
    }
    return list;
}

QVariantList CANController::binaryInputs() const
{
    QVariantList list;
    for (int i = 0; i < 3; ++i) {
        list.append(m_sensorData.binaryInputs[i]);
    }
    return list;
}

QString CANController::sensorDataTimestamp() const
{
    if (!m_sensorData.timestamp.isValid()) {
        return "Never";
    }
    return m_sensorData.timestamp.toString("yyyy-MM-dd HH:mm:ss");
}

QVariantList CANController::valveStates() const
{
    QVariantList list;
    for (int i = 0; i < 8; ++i) {
        QVariantMap map;
        map["commanded"] = m_actuatorState.valves[i];
        map["actual"] = m_actuatorState.valvesActual[i];
        list.append(map);
    }
    return list;
}

QVariantList CANController::outputStates() const
{
    QVariantList list;
    for (int i = 0; i < 3; ++i) {
        QVariantMap map;
        map["commanded"] = m_actuatorState.binaryOutputs[i];
        map["actual"] = m_actuatorState.outputsActual[i];
        list.append(map);
    }
    return list;
}

// ════════════════════════════════════════════════════════════════════════════
// Initialization / Shutdown
// ════════════════════════════════════════════════════════════════════════════

bool CANController::initCAN(const QString &interface, int bitrate)
{
    qInfo() << "[CAN] Initializing interface:" << interface << "at" << bitrate << "bps";
    
    if (m_initialized) {
        qWarning() << "[CAN] Already initialized";
        return true;
    }
    
    // Configure CAN interface (bitrate + bring UP)
    if (!configureInterface(interface, bitrate)) {
        m_status = "Failed to configure interface";
        emit statusChanged();
        emit errorOccurred(m_status);
        return false;
    }
    
    // Open SocketCAN socket
    if (!openSocket(interface)) {
        return false;
    }
    
    m_currentInterface = interface;
    m_initialized = true;
    m_status = QString("Initialized: %1 @ %2 kbps").arg(interface).arg(bitrate / 1000);
    
    emit initializedChanged();
    emit statusChanged();
    
    // Start periodic tasks
    m_heartbeatTimer->start();
    m_healthCheckTimer->start();
    
    // Start CAN logger
    if (m_logger) {
        if (m_logger->start()) {
            qInfo() << "[CAN] Logger started:" << m_logger->logFilePath();
        } else {
            qWarning() << "[CAN] Failed to start logger";
        }
    }
    
    // Send Node Announce
    sendNodeAnnounce();
    
    // Configure sensor data interval (default: 10 seconds)
    sendConfigSetInterval(10);
    
    qInfo() << "[CAN] Initialization successful";
    return true;
}

void CANController::shutdownCAN()
{
    if (!m_initialized) {
        return;
    }
    
    qInfo() << "[CAN] Shutting down";
    
    // Stop timers
    m_heartbeatTimer->stop();
    m_healthCheckTimer->stop();
    m_commandResponseTimer->stop();
    
    // Stop CAN logger
    if (m_logger) {
        m_logger->stop();
    }
    
    // Cancel any pending retries
    cancelCommandRetry();
    
    // Close socket
    closeSocket();
    
    m_initialized = false;
    m_status = "Not initialized";
    
    emit initializedChanged();
    emit statusChanged();
}

bool CANController::resetCAN()
{
    qInfo() << "[CAN] Resetting CAN interface";
    
    QString currentInterface = m_currentInterface;
    
    // Shutdown current connection
    shutdownCAN();
    
    // Wait a moment for cleanup
    QThread::msleep(100);
    
    // Re-initialize with same interface and bitrate
    bool success = initCAN(currentInterface, 10000);
    
    if (success) {
        emit commandSuccess("CAN interface reset successful");
        qInfo() << "[CAN] Reset successful";
    } else {
        emit errorOccurred("CAN interface reset failed");
        qWarning() << "[CAN] Reset failed";
    }
    
    return success;
}

// ════════════════════════════════════════════════════════════════════════════
// Actuator Commands (QML Invokable)
// ════════════════════════════════════════════════════════════════════════════

bool CANController::setValve(int valveIndex, bool state)
{
    if (valveIndex < 0 || valveIndex >= 8) {
        qWarning() << "[CAN] Invalid valve index:" << valveIndex;
        emit commandFailed("Invalid valve index");
        return false;
    }
    
    quint8 mask = (1 << valveIndex);
    quint8 states = state ? mask : 0;
    
    return sendValveCommand(mask, states);
}

bool CANController::setAllValves(quint8 mask, quint8 states)
{
    return sendValveCommand(mask, states);
}

bool CANController::setBinaryOutput(int outputIndex, bool state)
{
    if (outputIndex < 0 || outputIndex >= 3) {
        qWarning() << "[CAN] Invalid output index:" << outputIndex;
        emit commandFailed("Invalid output index");
        return false;
    }
    
    quint8 mask = (1 << outputIndex);
    quint8 states = state ? mask : 0;
    
    return sendOutputCommand(mask, states);
}

bool CANController::setAllOutputs(quint8 mask, quint8 states)
{
    return sendOutputCommand(mask, states);
}

bool CANController::setSensorInterval(quint8 intervalSeconds)
{
    if (intervalSeconds == 0) {
        qWarning() << "[CAN] Invalid sensor interval:" << intervalSeconds;
        emit commandFailed("Sensor interval must be 1-255 seconds");
        return false;
    }
    
    return sendConfigSetInterval(intervalSeconds);
}

bool CANController::requestStatus()
{
    return sendStatusRequest();
}

// ════════════════════════════════════════════════════════════════════════════
// CAN Socket Management
// ════════════════════════════════════════════════════════════════════════════

bool CANController::openSocket(const QString &interface)
{
    // Create SocketCAN socket
    m_socketFd = socket(PF_CAN, SOCK_RAW, CAN_RAW);
    if (m_socketFd < 0) {
        m_status = "Failed to create socket";
        qCritical() << "[CAN]" << m_status << ":" << strerror(errno);
        emit statusChanged();
        emit errorOccurred(m_status);
        return false;
    }
    
    // Get interface index
    struct ifreq ifr;
    std::strncpy(ifr.ifr_name, interface.toUtf8().constData(), IFNAMSIZ - 1);
    ifr.ifr_name[IFNAMSIZ - 1] = '\0';
    
    if (ioctl(m_socketFd, SIOCGIFINDEX, &ifr) < 0) {
        m_status = QString("Interface %1 not found").arg(interface);
        qCritical() << "[CAN]" << m_status << ":" << strerror(errno);
        close(m_socketFd);
        m_socketFd = -1;
        emit statusChanged();
        emit errorOccurred(m_status);
        return false;
    }
    
    // Bind socket to CAN interface
    struct sockaddr_can addr;
    std::memset(&addr, 0, sizeof(addr));
    addr.can_family = AF_CAN;
    addr.can_ifindex = ifr.ifr_ifindex;
    
    if (bind(m_socketFd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        m_status = QString("Failed to bind to %1").arg(interface);
        qCritical() << "[CAN]" << m_status << ":" << strerror(errno);
        close(m_socketFd);
        m_socketFd = -1;
        emit statusChanged();
        emit errorOccurred(m_status);
        return false;
    }
    
    // Setup async read notification
    m_socketNotifier = new QSocketNotifier(m_socketFd, QSocketNotifier::Read, this);
    connect(m_socketNotifier, &QSocketNotifier::activated, this, &CANController::onCANReadable);
    
    qDebug() << "[CAN] Socket opened and bound to" << interface;
    return true;
}

void CANController::closeSocket()
{
    if (m_socketNotifier) {
        delete m_socketNotifier;
        m_socketNotifier = nullptr;
    }
    
    if (m_socketFd >= 0) {
        close(m_socketFd);
        m_socketFd = -1;
    }
}

bool CANController::configureInterface(const QString &interface, int bitrate)
{
    // Bring interface DOWN first (required for configuration)
    QProcess downProc;
    downProc.start("ip", {"link", "set", interface, "down"});
    downProc.waitForFinished(2000);
    
    // Set bitrate
    QProcess bitrateProc;
    bitrateProc.start("ip", {"link", "set", interface, "type", "can", "bitrate", QString::number(bitrate)});
    if (!bitrateProc.waitForFinished(2000) || bitrateProc.exitCode() != 0) {
        qCritical() << "[CAN] Failed to set bitrate:" << bitrateProc.readAllStandardError();
        return false;
    }
    
    // Bring interface UP
    return bringInterfaceUp(interface);
}

bool CANController::bringInterfaceUp(const QString &interface)
{
    QProcess upProc;
    upProc.start("ip", {"link", "set", interface, "up"});
    if (!upProc.waitForFinished(2000) || upProc.exitCode() != 0) {
        qCritical() << "[CAN] Failed to bring interface UP:" << upProc.readAllStandardError();
        return false;
    }
    
    qDebug() << "[CAN] Interface" << interface << "is UP";
    return true;
}

// ════════════════════════════════════════════════════════════════════════════
// CAN TX Methods
// ════════════════════════════════════════════════════════════════════════════

bool CANController::sendCANFrame(quint32 canId, const QByteArray &data)
{
    if (!m_initialized || m_socketFd < 0) {
        qWarning() << "[CAN] Cannot send: not initialized";
        return false;
    }
    
    struct can_frame frame;
    std::memset(&frame, 0, sizeof(frame));
    
    frame.can_id = canId;
    frame.can_dlc = qMin(data.size(), 8);
    std::memcpy(frame.data, data.constData(), frame.can_dlc);
    
    ssize_t nbytes = write(m_socketFd, &frame, sizeof(frame));
    if (nbytes != sizeof(frame)) {
        qCritical() << "[CAN] Failed to send frame ID 0x" << QString::number(canId, 16) 
                    << ":" << strerror(errno);
        return false;
    }
    
    qDebug() << "[CAN] TX: ID 0x" << QString::number(canId, 16).toUpper()
             << " DLC:" << frame.can_dlc
             << " Data:" << QByteArray(reinterpret_cast<const char*>(frame.data), frame.can_dlc).toHex(' ');
    
    // Log to CAN logger
    if (m_logger && m_logger->isActive()) {
        m_logger->logTx(canId, data);
    }
    
    return true;
}

bool CANController::sendHeartbeat()
{
    // CAN ID: 0x0F0 (Processor heartbeat)
    // DLC: 2 bytes
    // Data: [UPTIME_LOW, UPTIME_HIGH] (uint16_t little-endian)
    
    QByteArray data(8, 0);
    data[0] = m_processorUptime & 0xFF;        // LSB
    data[1] = (m_processorUptime >> 8) & 0xFF; // MSB
    
    return sendCANFrame(CAN_ID_PROC_HEARTBEAT, data);
}

bool CANController::sendNodeAnnounce()
{
    // CAN ID: 0x0F1 (Processor announce)
    // DLC: 8 bytes
    // Data: [NODE_TYPE, HW_VER, SW_VER_MAJ, SW_VER_MIN, CAPABILITIES[4]]
    
    QByteArray data(8, 0);
    data[0] = NODE_TYPE_PROCESSOR;  // 0x02
    data[1] = 0x01;  // HW version 1.0
    data[2] = 0x00;  // SW major version (TODO: get from build)
    data[3] = 0x03;  // SW minor version (0.3)
    // Bytes 4-7: CAPABILITIES (reserved, all zeros)
    
    bool result = sendCANFrame(CAN_ID_PROC_ANNOUNCE, data);
    if (result) {
        qInfo() << "[CAN] Processor Node Announce sent";
    }
    return result;
}

bool CANController::sendValveCommand(quint8 mask, quint8 states)
{
    // CAN ID: 0x200 (Valve command)
    // DLC: 8 bytes
    // Data: [VALVE_MASK, VALVE_STATES, padding...]
    
    QByteArray data(8, 0);
    data[0] = mask;
    data[1] = states;
    
    bool result = sendCANFrame(CAN_ID_VALVE_CMD, data);
    if (result) {
        // Update commanded states
        for (int i = 0; i < 8; ++i) {
            if (mask & (1 << i)) {
                m_actuatorState.valves[i] = (states & (1 << i)) != 0;
            }
        }
        emit valveStatesChanged();
        qInfo() << "[CAN] Valve command sent: mask=0x" << QString::number(mask, 16)
                << " states=0x" << QString::number(states, 16);
        
        // Start retry tracking (wait for response on 0x300)
        startCommandRetry(CAN_ID_VALVE_CMD, data, "Valve command");
    }
    return result;
}

bool CANController::sendOutputCommand(quint8 mask, quint8 states)
{
    // CAN ID: 0x201 (Binary output command)
    // DLC: 8 bytes
    // Data: [OUTPUT_MASK, OUTPUT_STATES, padding...]
    
    QByteArray data(8, 0);
    data[0] = mask & 0x07;  // Only bits 0-2 valid
    data[1] = states & 0x07;
    
    bool result = sendCANFrame(CAN_ID_OUTPUT_CMD, data);
    if (result) {
        // Update commanded states
        for (int i = 0; i < 3; ++i) {
            if (mask & (1 << i)) {
                m_actuatorState.binaryOutputs[i] = (states & (1 << i)) != 0;
            }
        }
        emit outputStatesChanged();
        qInfo() << "[CAN] Binary output command sent: mask=0x" << QString::number(mask, 16)
                << " states=0x" << QString::number(states, 16);
        
        // Start retry tracking (wait for response on 0x301)
        startCommandRetry(CAN_ID_OUTPUT_CMD, data, "Binary output command");
    }
    return result;
}

bool CANController::sendConfigSetInterval(quint8 interval)
{
    // CAN ID: 0x400 (Set sensor interval)
    // DLC: 8 bytes
    // Data: [INTERVAL_SEC, padding...]
    
    QByteArray data(8, 0);
    data[0] = interval;
    
    bool result = sendCANFrame(CAN_ID_CONFIG_SET_INTERVAL, data);
    if (result) {
        qInfo() << "[CAN] Config: Set sensor interval to" << interval << "seconds";
        
        // Start retry tracking (wait for ACK on 0x300)
        startCommandRetry(CAN_ID_CONFIG_SET_INTERVAL, data, "Set sensor interval");
    }
    return result;
}

bool CANController::sendStatusRequest()
{
    // CAN ID: 0x401 (Status request)
    // DLC: 0 or 8 bytes (data ignored by IO Module)
    
    QByteArray data(8, 0);
    
    bool result = sendCANFrame(CAN_ID_CONFIG_STATUS_REQ, data);
    if (result) {
        qInfo() << "[CAN] Status request sent";
    }
    return result;
}

// ════════════════════════════════════════════════════════════════════════════
// CAN RX Processing
// ════════════════════════════════════════════════════════════════════════════

void CANController::onCANReadable()
{
    struct can_frame frame;
    ssize_t nbytes = read(m_socketFd, &frame, sizeof(frame));
    
    if (nbytes < 0) {
        qWarning() << "[CAN] Read error:" << strerror(errno);
        return;
    }
    
    if (nbytes < static_cast<ssize_t>(sizeof(frame))) {
        qWarning() << "[CAN] Incomplete frame received";
        return;
    }
    
    // Convert to QByteArray for easier processing
    QByteArray data(reinterpret_cast<const char*>(frame.data), frame.can_dlc);
    
    qDebug() << "[CAN] RX: ID 0x" << QString::number(frame.can_id, 16).toUpper()
             << " DLC:" << frame.can_dlc
             << " Data:" << data.toHex(' ');
    
    // Log to CAN logger
    if (m_logger && m_logger->isActive()) {
        m_logger->logRx(frame.can_id, data);
    }
    
    processCANFrame(frame.can_id, data);
}

void CANController::processCANFrame(quint32 canId, const QByteArray &data)
{
    // Dispatch based on CAN ID
    switch (canId) {
        // ── System Messages ──────────────────────────────────────────────
        case CAN_ID_IO_HEARTBEAT:
            processIOHeartbeat(data);
            break;
        case CAN_ID_IO_ANNOUNCE:
            processIOAnnounce(data);
            break;
            
        // ── Sensor Data ──────────────────────────────────────────────────
        case CAN_ID_MOISTURE_0_1:
        case CAN_ID_MOISTURE_2_3:
        case CAN_ID_MOISTURE_4_5:
        case CAN_ID_MOISTURE_6_7:
            processMoistureSensors(canId, data);
            break;
        case CAN_ID_PRESSURE_0_1:
        case CAN_ID_PRESSURE_2:
            processPressureSensors(canId, data);
            break;
        case CAN_ID_TEMPERATURE:
            processTemperatureSensor(data);
            break;
        case CAN_ID_BINARY_INPUTS:
            processBinaryInputs(data);
            break;
            
        // ── Actuator Responses ───────────────────────────────────────────
        case CAN_ID_VALVE_RESPONSE:
            processValveResponse(data);
            break;
        case CAN_ID_OUTPUT_RESPONSE:
            // Note: 0x301 is shared between output response and status response
            // Distinguish by DLC: status has 8 bytes with specific structure
            if (data.size() == 8 && static_cast<quint8>(data[0]) <= 3) {
                // Likely status response (STATE field in byte 0: 0-3)
                processStatusResponse(data);
            } else {
                processOutputResponse(data);
            }
            break;
            
        // ── Unknown ID ───────────────────────────────────────────────────
        default:
            // Silently ignore (could be from other nodes or test traffic)
            break;
    }
}

void CANController::processIOHeartbeat(const QByteArray &data)
{
    // CAN ID: 0x000
    // Data: [UPTIME_LOW, UPTIME_HIGH]
    
    if (data.size() < 2) {
        qWarning() << "[CAN] IO Heartbeat: insufficient data";
        return;
    }
    
    m_ioHealth.uptime = bytesToUint16(data, 0);
    m_ioHealth.lastHeartbeat = QDateTime::currentDateTime();
    
    // Update online status
    if (!m_ioHealth.isOnline) {
        m_ioHealth.isOnline = true;
        emit ioModuleOnlineChanged();
        qInfo() << "[CAN] IO Module is now ONLINE";
    }
    
    emit ioModuleUptimeChanged();
}

void CANController::processIOAnnounce(const QByteArray &data)
{
    // CAN ID: 0x001
    // Data: [NODE_TYPE, HW_VER, SW_VER_MAJ, SW_VER_MIN, CAPABILITIES[4]]
    
    if (data.size() < 8) {
        qWarning() << "[CAN] IO Announce: insufficient data";
        return;
    }
    
    quint8 nodeType = static_cast<quint8>(data[0]);
    if (nodeType != NODE_TYPE_IO_MODULE) {
        qWarning() << "[CAN] IO Announce: unexpected node type" << nodeType;
        return;
    }
    
    m_ioHealth.hwVersion = static_cast<quint8>(data[1]);
    m_ioHealth.swMajor = static_cast<quint8>(data[2]);
    m_ioHealth.swMinor = static_cast<quint8>(data[3]);
    
    emit ioModuleVersionChanged();
    
    qInfo() << "[CAN] IO Module announced: HW v" << m_ioHealth.hwVersion
            << " SW v" << m_ioHealth.swMajor << "." << m_ioHealth.swMinor;
}

void CANController::processMoistureSensors(quint32 canId, const QByteArray &data)
{
    // Moisture sensors are split across 4 messages (2 floats per message)
    // 0x100: Moisture[0-1]
    // 0x101: Moisture[2-3]
    // 0x102: Moisture[4-5]
    // 0x103: Moisture[6-7]
    
    if (data.size() < 8) {
        qWarning() << "[CAN] Moisture sensors: insufficient data";
        return;
    }
    
    int baseIndex = (canId - CAN_ID_MOISTURE_0_1) * 2;
    
    m_sensorData.moisture[baseIndex] = bytesToFloat(data, 0);
    m_sensorData.moisture[baseIndex + 1] = bytesToFloat(data, 4);
    
    // Update timestamp on last moisture message
    if (canId == CAN_ID_MOISTURE_6_7) {
        m_sensorData.timestamp = QDateTime::currentDateTime();
        m_sensorData.isValid = true;
        emit sensorDataChanged();
    }
}

void CANController::processPressureSensors(quint32 canId, const QByteArray &data)
{
    // Pressure sensors are split across 2 messages
    // 0x104: Pressure[0-1]
    // 0x105: Pressure[2] + padding
    
    if (data.size() < 8) {
        qWarning() << "[CAN] Pressure sensors: insufficient data";
        return;
    }
    
    if (canId == CAN_ID_PRESSURE_0_1) {
        m_sensorData.pressure[0] = bytesToFloat(data, 0);
        m_sensorData.pressure[1] = bytesToFloat(data, 4);
    } else if (canId == CAN_ID_PRESSURE_2) {
        m_sensorData.pressure[2] = bytesToFloat(data, 0);
        // Bytes 4-7 are padding
        
        m_sensorData.timestamp = QDateTime::currentDateTime();
        m_sensorData.isValid = true;
        emit sensorDataChanged();
    }
}

void CANController::processTemperatureSensor(const QByteArray &data)
{
    // CAN ID: 0x106
    // Data: [TEMPERATURE (float), padding...]
    
    if (data.size() < 8) {
        qWarning() << "[CAN] Temperature sensor: insufficient data";
        return;
    }
    
    m_sensorData.temperature = bytesToFloat(data, 0);
    // Bytes 4-7 are padding
    
    m_sensorData.timestamp = QDateTime::currentDateTime();
    m_sensorData.isValid = true;
    emit sensorDataChanged();
}

void CANController::processBinaryInputs(const QByteArray &data)
{
    // CAN ID: 0x107
    // Data: [INPUT_BITS, padding...]
    // Bits 0-2: Binary inputs 0-2
    
    if (data.size() < 1) {
        qWarning() << "[CAN] Binary inputs: insufficient data";
        return;
    }
    
    quint8 inputBits = static_cast<quint8>(data[0]);
    
    for (int i = 0; i < 3; ++i) {
        m_sensorData.binaryInputs[i] = (inputBits & (1 << i)) != 0;
    }
    
    m_sensorData.timestamp = QDateTime::currentDateTime();
    m_sensorData.isValid = true;
    emit sensorDataChanged();
}

void CANController::processValveResponse(const QByteArray &data)
{
    // CAN ID: 0x300
    // Data: [VALVE_STATES, STATUS, padding...]
    
    if (data.size() < 2) {
        qWarning() << "[CAN] Valve response: insufficient data";
        return;
    }
    
    // Cancel retry tracking - response received
    cancelCommandRetry();
    
    quint8 valveStates = static_cast<quint8>(data[0]);
    quint8 status = static_cast<quint8>(data[1]);
    
    if (status == 0x00) {
        // Success - update actual valve states
        for (int i = 0; i < 8; ++i) {
            m_actuatorState.valvesActual[i] = (valveStates & (1 << i)) != 0;
        }
        emit valveStatesChanged();
        emit commandSuccess("Valve command executed successfully");
        qInfo() << "[CAN] Valve response: SUCCESS (states=0x" << QString::number(valveStates, 16) << ")";
    } else {
        QString errorMsg;
        if (status == 0x01) errorMsg = "Hardware error";
        else if (status == 0x02) errorMsg = "Invalid command";
        else errorMsg = QString("Unknown error (0x%1)").arg(status, 2, 16, QChar('0'));
        
        emit commandFailed(QString("Valve command failed: %1").arg(errorMsg));
        qWarning() << "[CAN] Valve response: ERROR -" << errorMsg;
    }
}

void CANController::processOutputResponse(const QByteArray &data)
{
    // CAN ID: 0x301
    // Data: [OUTPUT_STATES, STATUS, padding...]
    
    if (data.size() < 2) {
        qWarning() << "[CAN] Output response: insufficient data";
        return;
    }
    
    // Cancel retry tracking - response received
    cancelCommandRetry();
    
    quint8 outputStates = static_cast<quint8>(data[0]) & 0x07;  // Bits 0-2 only
    quint8 status = static_cast<quint8>(data[1]);
    
    if (status == 0x00) {
        // Success - update actual output states
        for (int i = 0; i < 3; ++i) {
            m_actuatorState.outputsActual[i] = (outputStates & (1 << i)) != 0;
        }
        emit outputStatesChanged();
        emit commandSuccess("Binary output command executed successfully");
        qInfo() << "[CAN] Output response: SUCCESS (states=0x" << QString::number(outputStates, 16) << ")";
    } else {
        QString errorMsg;
        if (status == 0x01) errorMsg = "Hardware error";
        else if (status == 0x02) errorMsg = "Invalid command";
        else errorMsg = QString("Unknown error (0x%1)").arg(status, 2, 16, QChar('0'));
        
        emit commandFailed(QString("Output command failed: %1").arg(errorMsg));
        qWarning() << "[CAN] Output response: ERROR -" << errorMsg;
    }
}

void CANController::processConfigAck(const QByteArray &data)
{
    // CAN ID: 0x300 (shared with valve response)
    // Data: [CMD_ID, STATUS, padding...]
    
    if (data.size() < 2) {
        qWarning() << "[CAN] Config ACK: insufficient data";
    // Cancel retry tracking - ACK received
    cancelCommandRetry();
    
        return;
    }
    
    quint8 cmdId = static_cast<quint8>(data[0]);
    quint8 status = static_cast<quint8>(data[1]);
    
    if (cmdId == 0x00) {  // Set Interval
        if (status == 0x00) {
            emit commandSuccess("Sensor interval configured successfully");
            qInfo() << "[CAN] Config ACK: Sensor interval set successfully";
        } else {
            emit commandFailed("Sensor interval configuration failed: Invalid value");
            qWarning() << "[CAN] Config ACK: Invalid interval value";
        }
    }
}

void CANController::processStatusResponse(const QByteArray &data)
{
    // CAN ID: 0x301
    // Data: [STATE, ERROR_FLAGS, CURRENT_INTERVAL, UPTIME_LOW, UPTIME_HIGH, reserved...]
    
    if (data.size() < 8) {
        qWarning() << "[CAN] Status response: insufficient data";
        return;
    }
    
    m_ioHealth.state = static_cast<quint8>(data[0]);
    m_ioHealth.errorFlags = static_cast<quint8>(data[1]);
    m_ioHealth.sensorInterval = static_cast<quint8>(data[2]);
    m_ioHealth.uptime = bytesToUint16(data, 3);
    
    emit ioModuleStateChanged();
    
    qInfo() << "[CAN] Status response: State=" << ioModuleStateText()
            << " Errors=0x" << QString::number(m_ioHealth.errorFlags, 16)
            << " Interval=" << m_ioHealth.sensorInterval << "s"
            << " Uptime=" << m_ioHealth.uptime << "s";
}

// ════════════════════════════════════════════════════════════════════════════
// Timer Slots
// ════════════════════════════════════════════════════════════════════════════

void CANController::onHeartbeatTimer()
{
    // Send processor heartbeat every 5 seconds
    if (m_initialized) {
        m_processorUptime++;
        sendHeartbeat();
    }
}

void CANController::onHealthCheckTimer()
{
    // Check IO module online status every second
    updateIOModuleOnlineStatus();
}

// ════════════════════════════════════════════════════════════════════════════
// Helper Methods
// ════════════════════════════════════════════════════════════════════════════

void CANController::updateIOModuleOnlineStatus()
{
    if (!m_ioHealth.lastHeartbeat.isValid()) {
        // Never received heartbeat
        if (m_ioHealth.isOnline) {
            m_ioHealth.isOnline = false;
            emit ioModuleOnlineChanged();
        }
        return;
    }
    
    // Check timeout (15 seconds = 3× heartbeat period)
    qint64 msSinceLastHeartbeat = m_ioHealth.lastHeartbeat.msecsTo(QDateTime::currentDateTime());
    
    if (msSinceLastHeartbeat > IO_HEARTBEAT_TIMEOUT_MS) {
        if (m_ioHealth.isOnline) {
            m_ioHealth.isOnline = false;
            emit ioModuleOnlineChanged();
            qWarning() << "[CAN] IO Module timeout - marking as OFFLINE";
        }
    } else {
        if (!m_ioHealth.isOnline) {
            m_ioHealth.isOnline = true;
            emit ioModuleOnlineChanged();
            qInfo() << "[CAN] IO Module is ONLINE";
        }
    }
}

float CANController::bytesToFloat(const QByteArray &data, int offset) const
{
    // IEEE 754 single precision, little-endian
    if (offset + 4 > data.size()) {
        qWarning() << "[CAN] bytesToFloat: offset out of range";
        return 0.0f;
    }
    
    union {
        float f;
        quint32 i;
    } u;
    
    u.i = static_cast<quint8>(data[offset])
        | (static_cast<quint8>(data[offset + 1]) << 8)
        | (static_cast<quint8>(data[offset + 2]) << 16)
        | (static_cast<quint8>(data[offset + 3]) << 24);
    
    return u.f;
}

quint16 CANController::bytesToUint16(const QByteArray &data, int offset) const
{
    // Little-endian uint16
    if (offset + 2 > data.size()) {
        qWarning() << "[CAN] bytesToUint16: offset out of range";
        return 0;
    }
    
    return static_cast<quint8>(data[offset])
         | (static_cast<quint8>(data[offset + 1]) << 8);
}

void CANController::startCommandRetry(quint32 commandId, const QByteArray &commandData, const QString &commandName)
{
    // Store pending command for retry
    m_pendingCommand.canId = commandId;
    m_pendingCommand.data = commandData;
    m_pendingCommand.name = commandName;
    m_pendingCommand.retryCount = 0;
    m_pendingCommand.active = true;
    
    // Start response timeout timer (1 second)
    m_commandResponseTimer->start(COMMAND_RESPONSE_TIMEOUT_MS);
    
    qDebug() << "[CAN] Started retry tracking for" << commandName;
}

void CANController::cancelCommandRetry()
{
    if (!m_pendingCommand.active) {
        return;
    }
    
    // Cancel timeout timer
    m_commandResponseTimer->stop();
    
    // Clear pending command
    m_pendingCommand.active = false;
    m_pendingCommand.retryCount = 0;
    
    qDebug() << "[CAN] Cancelled retry tracking for" << m_pendingCommand.name;
}

void CANController::onCommandResponseTimeout()
{
    if (!m_pendingCommand.active) {
        return;
    }
    
    m_pendingCommand.retryCount++;
    
    qWarning() << "[CAN]" << m_pendingCommand.name << "timeout (retry" 
               << m_pendingCommand.retryCount << "of" << COMMAND_RETRY_MAX << ")";
    
    if (m_pendingCommand.retryCount < COMMAND_RETRY_MAX) {
        // Retry: resend command
        QThread::msleep(COMMAND_RETRY_INTERVAL_MS);  // Wait 500ms between retries
        
        if (sendCANFrame(m_pendingCommand.canId, m_pendingCommand.data)) {
            // Restart timeout timer
            m_commandResponseTimer->start(COMMAND_RESPONSE_TIMEOUT_MS);
            qInfo() << "[CAN] Retrying" << m_pendingCommand.name;
        } else {
            // Failed to send retry
            emit commandFailed(QString("%1 retry failed: Cannot send CAN frame").arg(m_pendingCommand.name));
            cancelCommandRetry();
        }
    } else {
        // Max retries exhausted
        emit commandFailed(QString("%1 failed after %2 retries: No response from IO Module")
                          .arg(m_pendingCommand.name).arg(COMMAND_RETRY_MAX));
        qCritical() << "[CAN]" << m_pendingCommand.name << "FAILED after" << COMMAND_RETRY_MAX << "retries";
        cancelCommandRetry();
    }
}
