/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2026 HB Watertechnologie
 * 
 * CAN Bus Logger Implementation
 */

#include "can_logger.hpp"
#include <QDebug>
#include <QDir>
#include <cstring>

// ════════════════════════════════════════════════════════════════════════════
// Constructor / Destructor
// ════════════════════════════════════════════════════════════════════════════

CANLogger::CANLogger(QObject *parent)
    : QObject(parent)
    , m_isActive(false)
    , m_currentFileSize(0)
{
}

CANLogger::~CANLogger()
{
    stop();
}

// ════════════════════════════════════════════════════════════════════════════
// Public Methods
// ════════════════════════════════════════════════════════════════════════════

bool CANLogger::start(const QString &logFilePath)
{
    QMutexLocker locker(&m_mutex);
    
    if (m_isActive) {
        qWarning() << "[CANLogger] Already active";
        return true;
    }
    
    // Clean up old log files before starting new one
    cleanupOldLogs();
    
    // Determine log file path
    m_logFilePath = logFilePath.isEmpty() ? generateLogFilePath() : logFilePath;
    
    // Ensure directory exists
    QFileInfo fileInfo(m_logFilePath);
    QDir dir = fileInfo.dir();
    if (!dir.exists()) {
        if (!dir.mkpath(".")) {
            qCritical() << "[CANLogger] Failed to create directory:" << dir.path();
            return false;
        }
    }
    
    // Open log file
    m_logFile.setFileName(m_logFilePath);
    if (!m_logFile.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Append)) {
        qCritical() << "[CANLogger] Failed to open log file:" << m_logFilePath 
                    << "Error:" << m_logFile.errorString();
        return false;
    }
    
    // Setup text stream
    m_logStream.setDevice(&m_logFile);
    
    // Initialize file size tracking
    m_currentFileSize = m_logFile.size();
    
    // Write header (only if new file)
    if (m_currentFileSize == 0) {
        m_logStream << "# CAN Bus Log - Started: " << QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss.zzz") << "\n";
        m_logStream << "# Format: Timestamp,Direction,CAN_ID,DLC,Data,Interpretation\n";
        m_logStream << "# ────────────────────────────────────────────────────────────────────────────────────\n";
        m_logStream.flush();
        m_currentFileSize = m_logFile.size();
    }
    
    m_isActive = true;
    
    qInfo() << "[CANLogger] Logging started to:" << m_logFilePath 
            << "Size:" << (m_currentFileSize / 1024) << "KB";
    return true;
}

void CANLogger::stop()
{
    QMutexLocker locker(&m_mutex);
    
    if (!m_isActive) {
        return;
    }
    
    // Write footer
    m_logStream << "# ────────────────────────────────────────────────────────────────────────────────────\n";
    m_logStream << "# CAN Bus Log - Stopped: " << QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss.zzz") << "\n";
    m_logStream.flush();
    
    // Close file
    m_logFile.close();
    
    m_isActive = false;
    
    qInfo() << "[CANLogger] Logging stopped";
}

void CANLogger::logTx(quint32 canId, const QByteArray &data)
{
    if (!m_isActive) {
        return;
    }
    
    QDateTime timestamp = QDateTime::currentDateTime();
    QString interpretation = interpretFrame(canId, data);
    writeLogEntry(timestamp, "TX", canId, data, interpretation);
}

void CANLogger::logRx(quint32 canId, const QByteArray &data)
{
    if (!m_isActive) {
        return;
    }
    
    QDateTime timestamp = QDateTime::currentDateTime();
    QString interpretation = interpretFrame(canId, data);
    writeLogEntry(timestamp, "RX", canId, data, interpretation);
}

// ════════════════════════════════════════════════════════════════════════════
// Private Methods
// ════════════════════════════════════════════════════════════════════════════

void CANLogger::writeLogEntry(const QDateTime &timestamp,
                              const QString &direction,
                              quint32 canId,
                              const QByteArray &data,
                              const QString &interpretation)
{
    QMutexLocker locker(&m_mutex);
    
    if (!m_isActive) {
        return;
    }
    
    // Check if log rotation is needed
    checkAndRotateIfNeeded();
    
    // Format: Timestamp,Direction,CAN_ID,DLC,Data,Interpretation
    QString timeStr = timestamp.toString("yyyy-MM-dd HH:mm:ss.zzz");
    QString canIdStr = QString("0x%1").arg(canId, 3, 16, QChar('0')).toUpper();
    QString dataHex = data.toHex(' ').toUpper();
    
    QString logLine = QString("%1,%2,%3,%4,%5,%6\n")
        .arg(timeStr)
        .arg(direction)
        .arg(canIdStr)
        .arg(data.size())
        .arg(QString(dataHex))
        .arg(interpretation);
    
    m_logStream << logLine;
    
    // Flush to ensure data is written immediately (important for debugging)
    m_logStream.flush();
    
    // Update file size tracking
    m_currentFileSize += logLine.toUtf8().size();
}

QString CANLogger::interpretFrame(quint32 canId, const QByteArray &data)
{
    // Interpret based on CAN ID
    switch (canId) {
        // System Messages
        case CAN_ID_IO_HEARTBEAT:
            return interpretHeartbeat(data, true);
        case CAN_ID_IO_ANNOUNCE:
            return interpretAnnounce(data, true);
        case CAN_ID_PROC_HEARTBEAT:
            return interpretHeartbeat(data, false);
        case CAN_ID_PROC_ANNOUNCE:
            return interpretAnnounce(data, false);
            
        // Sensor Data
        case CAN_ID_MOISTURE_0_1:
        case CAN_ID_MOISTURE_2_3:
        case CAN_ID_MOISTURE_4_5:
        case CAN_ID_MOISTURE_6_7:
            return interpretMoistureSensors(canId, data);
        case CAN_ID_PRESSURE_0_1:
        case CAN_ID_PRESSURE_2:
            return interpretPressureSensors(canId, data);
        case CAN_ID_TEMPERATURE:
            return interpretTemperatureSensor(data);
        case CAN_ID_BINARY_INPUTS:
            return interpretBinaryInputs(data);
            
        // Actuator Commands
        case CAN_ID_VALVE_CMD:
            return interpretValveCommand(data);
        case CAN_ID_OUTPUT_CMD:
            return interpretOutputCommand(data);
            
        // Actuator Responses
        case CAN_ID_VALVE_RESPONSE:
            return interpretValveResponse(data);
        case CAN_ID_OUTPUT_RESPONSE:
            return interpretOutputResponse(data);
            
        // Configuration
        case CAN_ID_CONFIG_SET_INTERVAL:
            return interpretConfigSetInterval(data);
        case CAN_ID_CONFIG_STATUS_REQ:
            return interpretStatusRequest(data);
            
        default:
            return "Unknown CAN ID";
    }
}

QString CANLogger::generateLogFilePath()
{
    QString timestamp = QDateTime::currentDateTime().toString("yyyyMMdd_HHmmss");
    return QString("/tmp/can_log_%1.csv").arg(timestamp);
}

// ════════════════════════════════════════════════════════════════════════════
// Frame Interpretation Methods
// ════════════════════════════════════════════════════════════════════════════

QString CANLogger::interpretHeartbeat(const QByteArray &data, bool isIO)
{
    if (data.size() < 2) {
        return "Heartbeat (insufficient data)";
    }
    
    quint16 uptime = bytesToUint16(data, 0);
    QString nodeType = isIO ? "IO Module" : "Processor";
    
    return QString("%1 Heartbeat: uptime=%2s").arg(nodeType).arg(uptime);
}

QString CANLogger::interpretAnnounce(const QByteArray &data, bool isIO)
{
    if (data.size() < 8) {
        return "Node Announce (insufficient data)";
    }
    
    quint8 nodeType = static_cast<quint8>(data[0]);
    quint8 hwVer = static_cast<quint8>(data[1]);
    quint8 swMajor = static_cast<quint8>(data[2]);
    quint8 swMinor = static_cast<quint8>(data[3]);
    
    QString nodeTypeStr;
    if (nodeType == NODE_TYPE_IO_MODULE) {
        nodeTypeStr = "IO Module";
    } else if (nodeType == NODE_TYPE_PROCESSOR) {
        nodeTypeStr = "Processor";
    } else {
        nodeTypeStr = QString("Unknown(0x%1)").arg(nodeType, 2, 16, QChar('0'));
    }
    
    return QString("%1 Announce: HW v%2 / SW v%3.%4")
        .arg(nodeTypeStr)
        .arg(hwVer)
        .arg(swMajor)
        .arg(swMinor);
}

QString CANLogger::interpretMoistureSensors(quint32 canId, const QByteArray &data)
{
    if (data.size() < 8) {
        return "Moisture Sensors (insufficient data)";
    }
    
    int baseIndex = (canId - CAN_ID_MOISTURE_0_1) * 2;
    float moisture0 = bytesToFloat(data, 0);
    float moisture1 = bytesToFloat(data, 4);
    
    return QString("Moisture[%1]=%2%, Moisture[%3]=%4%")
        .arg(baseIndex)
        .arg(moisture0, 0, 'f', 1)
        .arg(baseIndex + 1)
        .arg(moisture1, 0, 'f', 1);
}

QString CANLogger::interpretPressureSensors(quint32 canId, const QByteArray &data)
{
    if (data.size() < 8) {
        return "Pressure Sensors (insufficient data)";
    }
    
    if (canId == CAN_ID_PRESSURE_0_1) {
        float pressure0 = bytesToFloat(data, 0);
        float pressure1 = bytesToFloat(data, 4);
        return QString("Pressure[0]=%1hPa, Pressure[1]=%2hPa")
            .arg(pressure0, 0, 'f', 1)
            .arg(pressure1, 0, 'f', 1);
    } else if (canId == CAN_ID_PRESSURE_2) {
        float pressure2 = bytesToFloat(data, 0);
        return QString("Pressure[2]=%1hPa").arg(pressure2, 0, 'f', 1);
    }
    
    return "Pressure Sensors (unknown ID)";
}

QString CANLogger::interpretTemperatureSensor(const QByteArray &data)
{
    if (data.size() < 8) {
        return "Temperature Sensor (insufficient data)";
    }
    
    float temperature = bytesToFloat(data, 0);
    return QString("Temperature=%1°C").arg(temperature, 0, 'f', 1);
}

QString CANLogger::interpretBinaryInputs(const QByteArray &data)
{
    if (data.size() < 1) {
        return "Binary Inputs (insufficient data)";
    }
    
    quint8 inputBits = static_cast<quint8>(data[0]);
    
    QString states;
    for (int i = 0; i < 3; ++i) {
        if (i > 0) states += ", ";
        states += QString("IN%1=%2").arg(i).arg((inputBits & (1 << i)) ? "ON" : "OFF");
    }
    
    return QString("Binary Inputs: %1").arg(states);
}

QString CANLogger::interpretValveCommand(const QByteArray &data)
{
    if (data.size() < 2) {
        return "Valve Command (insufficient data)";
    }
    
    quint8 mask = static_cast<quint8>(data[0]);
    quint8 states = static_cast<quint8>(data[1]);
    
    QString changedValves;
    for (int i = 0; i < 8; ++i) {
        if (mask & (1 << i)) {
            if (!changedValves.isEmpty()) changedValves += ", ";
            changedValves += QString("V%1=%2").arg(i).arg((states & (1 << i)) ? "OPEN" : "CLOSE");
        }
    }
    
    if (changedValves.isEmpty()) {
        return "Valve Command: (no changes)";
    }
    
    return QString("Valve Command: %1").arg(changedValves);
}

QString CANLogger::interpretOutputCommand(const QByteArray &data)
{
    if (data.size() < 2) {
        return "Output Command (insufficient data)";
    }
    
    quint8 mask = static_cast<quint8>(data[0]);
    quint8 states = static_cast<quint8>(data[1]);
    
    QString changedOutputs;
    for (int i = 0; i < 3; ++i) {
        if (mask & (1 << i)) {
            if (!changedOutputs.isEmpty()) changedOutputs += ", ";
            changedOutputs += QString("OUT%1=%2").arg(i).arg((states & (1 << i)) ? "ON" : "OFF");
        }
    }
    
    if (changedOutputs.isEmpty()) {
        return "Output Command: (no changes)";
    }
    
    return QString("Output Command: %1").arg(changedOutputs);
}

QString CANLogger::interpretValveResponse(const QByteArray &data)
{
    if (data.size() < 2) {
        return "Valve Response (insufficient data)";
    }
    
    quint8 valveStates = static_cast<quint8>(data[0]);
    quint8 status = static_cast<quint8>(data[1]);
    
    QString statusStr;
    switch (status) {
        case 0x00: statusStr = "SUCCESS"; break;
        case 0x01: statusStr = "HW_ERROR"; break;
        case 0x02: statusStr = "INVALID_CMD"; break;
        case 0x03: statusStr = "BUSY"; break;
        default: statusStr = QString("UNKNOWN(0x%1)").arg(status, 2, 16, QChar('0')); break;
    }
    
    QString valveList;
    for (int i = 0; i < 8; ++i) {
        if (i > 0) valveList += ", ";
        valveList += QString("V%1=%2").arg(i).arg((valveStates & (1 << i)) ? "1" : "0");
    }
    
    return QString("Valve Response: status=%1, states=[%2]").arg(statusStr).arg(valveList);
}

QString CANLogger::interpretOutputResponse(const QByteArray &data)
{
    if (data.size() < 2) {
        return "Output Response (insufficient data)";
    }
    
    quint8 outputStates = static_cast<quint8>(data[0]);
    quint8 status = static_cast<quint8>(data[1]);
    
    QString statusStr;
    switch (status) {
        case 0x00: statusStr = "SUCCESS"; break;
        case 0x01: statusStr = "HW_ERROR"; break;
        case 0x02: statusStr = "INVALID_CMD"; break;
        case 0x03: statusStr = "BUSY"; break;
        default: statusStr = QString("UNKNOWN(0x%1)").arg(status, 2, 16, QChar('0')); break;
    }
    
    QString outputList;
    for (int i = 0; i < 3; ++i) {
        if (i > 0) outputList += ", ";
        outputList += QString("OUT%1=%2").arg(i).arg((outputStates & (1 << i)) ? "1" : "0");
    }
    
    return QString("Output Response: status=%1, states=[%2]").arg(statusStr).arg(outputList);
}

QString CANLogger::interpretConfigSetInterval(const QByteArray &data)
{
    if (data.size() < 1) {
        return "Config Set Interval (insufficient data)";
    }
    
    quint8 interval = static_cast<quint8>(data[0]);
    return QString("Config: Set sensor interval to %1s").arg(interval);
}

QString CANLogger::interpretStatusRequest(const QByteArray &data)
{
    Q_UNUSED(data);
    return "Config: Status request";
}

QString CANLogger::interpretStatusResponse(const QByteArray &data)
{
    if (data.size() < 8) {
        return "Status Response (insufficient data)";
    }
    
    quint8 state = static_cast<quint8>(data[0]);
    quint8 errorFlags = static_cast<quint8>(data[1]);
    quint8 sensorInterval = static_cast<quint8>(data[2]);
    quint8 valveStates = static_cast<quint8>(data[3]);
    quint8 outputStates = static_cast<quint8>(data[4]);
    
    QString stateStr;
    switch (state) {
        case 0x00: stateStr = "INIT"; break;
        case 0x01: stateStr = "RUNNING"; break;
        case 0x02: stateStr = "ERROR"; break;
        case 0x03: stateStr = "SHUTDOWN"; break;
        default: stateStr = QString("UNKNOWN(0x%1)").arg(state, 2, 16, QChar('0')); break;
    }
    
    return QString("Status Response: state=%1, errors=0x%2, interval=%3s, valves=0x%4, outputs=0x%5")
        .arg(stateStr)
        .arg(errorFlags, 2, 16, QChar('0'))
        .arg(sensorInterval)
        .arg(valveStates, 2, 16, QChar('0'))
        .arg(outputStates, 2, 16, QChar('0'));
}

// ════════════════════════════════════════════════════════════════════════════
// Utility Methods
// ════════════════════════════════════════════════════════════════════════════

float CANLogger::bytesToFloat(const QByteArray &data, int offset) const
{
    if (offset + 4 > data.size()) {
        return 0.0f;
    }
    
    float result;
    std::memcpy(&result, data.constData() + offset, sizeof(float));
    return result;
}

quint16 CANLogger::bytesToUint16(const QByteArray &data, int offset) const
{
    if (offset + 2 > data.size()) {
        return 0;
    }
    
    return static_cast<quint16>(static_cast<quint8>(data[offset])) |
           (static_cast<quint16>(static_cast<quint8>(data[offset + 1])) << 8);
}

// ════════════════════════════════════════════════════════════════════════════
// Log Rotation Methods
// ════════════════════════════════════════════════════════════════════════════

void CANLogger::checkAndRotateIfNeeded()
{
    if (m_currentFileSize >= MAX_FILE_SIZE_BYTES) {
        qInfo() << "[CANLogger] Log file size limit reached (" 
                << (m_currentFileSize / 1024 / 1024) << "MB), rotating...";
        rotateLogFile();
    }
}

bool CANLogger::rotateLogFile()
{
    if (!m_isActive) {
        return false;
    }
    
    // Close current file
    m_logStream.setDevice(nullptr);
    m_logFile.close();
    
    qInfo() << "[CANLogger] Rotated log file:" << m_logFilePath 
            << "Final size:" << (m_currentFileSize / 1024) << "KB";
    
    // Generate new log file path
    m_logFilePath = generateLogFilePath();
    
    // Open new file
    m_logFile.setFileName(m_logFilePath);
    if (!m_logFile.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Append)) {
        qCritical() << "[CANLogger] Failed to open new log file:" << m_logFilePath;
        m_isActive = false;
        return false;
    }
    
    // Setup stream
    m_logStream.setDevice(&m_logFile);
    
    // Write header
    m_logStream << "# CAN Bus Log - Started: " << QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss.zzz") << "\n";
    m_logStream << "# Format: Timestamp,Direction,CAN_ID,DLC,Data,Interpretation\n";
    m_logStream << "# ────────────────────────────────────────────────────────────────────────────────────\n";
    m_logStream.flush();
    
    // Reset file size
    m_currentFileSize = m_logFile.size();
    
    qInfo() << "[CANLogger] New log file created:" << m_logFilePath;
    
    // Clean up old logs
    cleanupOldLogs();
    
    return true;
}

void CANLogger::cleanupOldLogs()
{
    // Get /tmp directory
    QDir tmpDir("/tmp");
    
    // Find all can_log_*.csv files
    QStringList filters;
    filters << "can_log_*.csv";
    QFileInfoList logFiles = tmpDir.entryInfoList(filters, QDir::Files, QDir::Time);
    
    // Remove oldest files if we have more than MAX_LOG_FILES
    int filesToRemove = logFiles.size() - MAX_LOG_FILES;
    if (filesToRemove > 0) {
        qInfo() << "[CANLogger] Cleaning up" << filesToRemove << "old log files";
        
        // Files are sorted by time (newest first), so remove from the end
        for (int i = logFiles.size() - 1; i >= logFiles.size() - filesToRemove; --i) {
            QString filePath = logFiles[i].absoluteFilePath();
            
            // Don't remove the current log file
            if (filePath == m_logFilePath) {
                continue;
            }
            
            if (QFile::remove(filePath)) {
                qInfo() << "[CANLogger] Removed old log:" << logFiles[i].fileName();
            } else {
                qWarning() << "[CANLogger] Failed to remove:" << filePath;
            }
        }
    }
}
