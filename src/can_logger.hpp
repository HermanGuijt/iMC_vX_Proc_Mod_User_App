/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2026 HB Watertechnologie
 * 
 * CAN Bus Logger for iMC vX Processor Module
 * Logs all CAN traffic with human-readable interpretation
 */

#ifndef CAN_LOGGER_HPP
#define CAN_LOGGER_HPP

#include <QObject>
#include <QFile>
#include <QTextStream>
#include <QMutex>
#include <QString>
#include <QByteArray>
#include <QDateTime>

/**
 * @brief CAN Bus Logger
 * 
 * Logs all CAN bus traffic (TX and RX) to a file with:
 * - Timestamps
 * - Direction (TX/RX)
 * - CAN ID (hex)
 * - Raw data (hex)
 * - Human-readable interpretation based on protocol
 * 
 * Thread-safe for concurrent TX/RX logging.
 * Automatically flushes to disk for reliability.
 */
class CANLogger : public QObject
{
    Q_OBJECT

public:
    explicit CANLogger(QObject *parent = nullptr);
    ~CANLogger();
    
    /**
     * @brief Start logging to a file
     * @param logFilePath Path to log file (default: /tmp/can_log_TIMESTAMP.csv)
     * @return true if log file opened successfully
     */
    bool start(const QString &logFilePath = QString());
    
    /**
     * @brief Stop logging and close file
     */
    void stop();
    
    /**
     * @brief Check if logger is active
     */
    bool isActive() const { return m_isActive; }
    
    /**
     * @brief Get current log file path
     */
    QString logFilePath() const { return m_logFilePath; }
    
    /**
     * @brief Log a transmitted CAN frame
     * @param canId CAN identifier
     * @param data Frame data (max 8 bytes)
     */
    void logTx(quint32 canId, const QByteArray &data);
    
    /**
     * @brief Log a received CAN frame
     * @param canId CAN identifier
     * @param data Frame data (max 8 bytes)
     */
    void logRx(quint32 canId, const QByteArray &data);

private:
    /**
     * @brief Write a log entry to file
     * @param timestamp Entry timestamp
     * @param direction "TX" or "RX"
     * @param canId CAN identifier
     * @param data Frame data
     * @param interpretation Human-readable interpretation
     */
    void writeLogEntry(const QDateTime &timestamp, 
                      const QString &direction,
                      quint32 canId, 
                      const QByteArray &data,
                      const QString &interpretation);
    
    /**
     * @brief Interpret CAN frame data based on CAN ID
     * @param canId CAN identifier
     * @param data Frame data
     * @return Human-readable interpretation
     */
    QString interpretFrame(quint32 canId, const QByteArray &data);
    
    /**
     * @brief Generate default log file path with timestamp
     */
    QString generateLogFilePath();
    
    // Helper methods for interpreting specific message types
    QString interpretHeartbeat(const QByteArray &data, bool isIO);
    QString interpretAnnounce(const QByteArray &data, bool isIO);
    QString interpretMoistureSensors(quint32 canId, const QByteArray &data);
    QString interpretPressureSensors(quint32 canId, const QByteArray &data);
    QString interpretTemperatureSensor(const QByteArray &data);
    QString interpretBinaryInputs(const QByteArray &data);
    QString interpretValveCommand(const QByteArray &data);
    QString interpretOutputCommand(const QByteArray &data);
    QString interpretValveResponse(const QByteArray &data);
    QString interpretOutputResponse(const QByteArray &data);
    QString interpretConfigSetInterval(const QByteArray &data);
    QString interpretStatusRequest(const QByteArray &data);
    QString interpretStatusResponse(const QByteArray &data);
    
    // Utility methods
    float bytesToFloat(const QByteArray &data, int offset) const;
    quint16 bytesToUint16(const QByteArray &data, int offset) const;
    
    /**
     * @brief Check if log rotation is needed and perform rotation
     */
    void checkAndRotateIfNeeded();
    
    /**
     * @brief Rotate to a new log file
     * @return true if rotation succeeded
     */
    bool rotateLogFile();
    
    /**
     * @brief Clean up old log files, keeping only MAX_LOG_FILES newest
     */
    void cleanupOldLogs();
    
    // State
    QFile m_logFile;
    QTextStream m_logStream;
    QMutex m_mutex;
    bool m_isActive;
    QString m_logFilePath;
    qint64 m_currentFileSize;  // Track current log file size
    
    // Log rotation configuration
    static constexpr qint64 MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024;  // 10 MB
    static constexpr int MAX_LOG_FILES = 3;  // Keep max 3 log files (30 MB total)
    
    // CAN Protocol Constants (same as CANController)
    static constexpr quint32 CAN_ID_IO_HEARTBEAT = 0x000;
    static constexpr quint32 CAN_ID_IO_ANNOUNCE = 0x001;
    static constexpr quint32 CAN_ID_PROC_HEARTBEAT = 0x0F0;
    static constexpr quint32 CAN_ID_PROC_ANNOUNCE = 0x0F1;
    
    static constexpr quint32 CAN_ID_MOISTURE_0_1 = 0x100;
    static constexpr quint32 CAN_ID_MOISTURE_2_3 = 0x101;
    static constexpr quint32 CAN_ID_MOISTURE_4_5 = 0x102;
    static constexpr quint32 CAN_ID_MOISTURE_6_7 = 0x103;
    static constexpr quint32 CAN_ID_PRESSURE_0_1 = 0x104;
    static constexpr quint32 CAN_ID_PRESSURE_2 = 0x105;
    static constexpr quint32 CAN_ID_TEMPERATURE = 0x106;
    static constexpr quint32 CAN_ID_BINARY_INPUTS = 0x107;
    
    static constexpr quint32 CAN_ID_VALVE_CMD = 0x200;
    static constexpr quint32 CAN_ID_OUTPUT_CMD = 0x201;
    
    static constexpr quint32 CAN_ID_VALVE_RESPONSE = 0x300;
    static constexpr quint32 CAN_ID_OUTPUT_RESPONSE = 0x301;
    
    static constexpr quint32 CAN_ID_CONFIG_SET_INTERVAL = 0x400;
    static constexpr quint32 CAN_ID_CONFIG_STATUS_REQ = 0x401;
    
    static constexpr quint8 NODE_TYPE_IO_MODULE = 0x01;
    static constexpr quint8 NODE_TYPE_PROCESSOR = 0x02;
};

#endif // CAN_LOGGER_HPP
