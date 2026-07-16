/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2026 HB Watertechnologie
 * 
 * CAN Bus Controller for iMC vX Processor Module
 * Implements CAN_Interface_Proc.md specification
 */

#ifndef CAN_CONTROLLER_HPP
#define CAN_CONTROLLER_HPP

#include <QObject>
#include <QSocketNotifier>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>
#include <QString>
#include <QDateTime>

// Forward declaration
class CANLogger;

/**
 * @brief Sensor Data Model
 * Holds all sensor readings from IO Module
 */
struct SensorData {
    QDateTime timestamp;
    float moisture[8];        // 8 moisture sensors (%)
    float pressure[3];        // 3 pressure sensors (hPa/mbar)
    float temperature;        // 1 temperature sensor (°C)
    bool binaryInputs[3];     // 3 binary inputs
    bool isValid;             // Data is recent (< timeout)
    
    SensorData() : temperature(0.0f), isValid(false) {
        for (int i = 0; i < 8; ++i) moisture[i] = 0.0f;
        for (int i = 0; i < 3; ++i) pressure[i] = 0.0f;
        for (int i = 0; i < 3; ++i) binaryInputs[i] = false;
    }
};

/**
 * @brief Actuator State Model
 * Tracks commanded and actual states of actuators
 */
struct ActuatorState {
    bool valves[8];           // Commanded valve states
    bool binaryOutputs[3];    // Commanded output states
    bool valvesActual[8];     // Actual valve states (from IO feedback)
    bool outputsActual[3];    // Actual output states (from IO feedback)
    
    ActuatorState() {
        for (int i = 0; i < 8; ++i) { valves[i] = false; valvesActual[i] = false; }
        for (int i = 0; i < 3; ++i) { binaryOutputs[i] = false; outputsActual[i] = false; }
    }
};

/**
 * @brief IO Module Health Model
 * Tracks IO Module online status and diagnostics
 */
struct IOModuleHealth {
    bool isOnline;
    QDateTime lastHeartbeat;
    quint8 hwVersion;
    quint8 swMajor;
    quint8 swMinor;
    quint16 uptime;           // seconds
    quint8 state;             // 0=INIT, 1=RUNNING, 2=ERROR, 3=SHUTDOWN
    quint8 errorFlags;
    quint8 sensorInterval;    // seconds
    
    IOModuleHealth() : isOnline(false), hwVersion(0), swMajor(0), swMinor(0), 
                       uptime(0), state(0), errorFlags(0), sensorInterval(10) {}
};

/**
 * @brief CAN Bus Controller for iMC vX Processor Module
 * 
 * Implements complete CAN 2.0A protocol per CAN_Interface_Proc.md:
 * - TX: Heartbeat (0x0F0), Node Announce (0x0F1), Valve/Output commands, Config
 * - RX: IO heartbeat, sensor data (0x100-0x107), actuator responses
 * - Data models: SensorData, ActuatorState, IOModuleHealth
 * - Error handling with retries and timeouts
 */
class CANController : public QObject
{
    Q_OBJECT
    
    // CAN Bus Status Properties
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(bool initialized READ initialized NOTIFY initializedChanged)
    
    // IO Module Health Properties
    Q_PROPERTY(bool ioModuleOnline READ ioModuleOnline NOTIFY ioModuleOnlineChanged)
    Q_PROPERTY(QString ioModuleVersion READ ioModuleVersion NOTIFY ioModuleVersionChanged)
    Q_PROPERTY(int ioModuleUptime READ ioModuleUptime NOTIFY ioModuleUptimeChanged)
    Q_PROPERTY(int ioModuleState READ ioModuleState NOTIFY ioModuleStateChanged)
    Q_PROPERTY(QString ioModuleStateText READ ioModuleStateText NOTIFY ioModuleStateChanged)
    
    // Sensor Data Properties
    Q_PROPERTY(QVariantList moistureSensors READ moistureSensors NOTIFY sensorDataChanged)
    Q_PROPERTY(QVariantList pressureSensors READ pressureSensors NOTIFY sensorDataChanged)
    Q_PROPERTY(float temperatureSensor READ temperatureSensor NOTIFY sensorDataChanged)
    Q_PROPERTY(QVariantList binaryInputs READ binaryInputs NOTIFY sensorDataChanged)
    Q_PROPERTY(bool sensorDataValid READ sensorDataValid NOTIFY sensorDataChanged)
    Q_PROPERTY(QString sensorDataTimestamp READ sensorDataTimestamp NOTIFY sensorDataChanged)
    
    // Actuator State Properties
    Q_PROPERTY(QVariantList valveStates READ valveStates NOTIFY valveStatesChanged)
    Q_PROPERTY(QVariantList outputStates READ outputStates NOTIFY outputStatesChanged)

public:
    explicit CANController(QObject *parent = nullptr);
    ~CANController();
    
    // ── Property Getters ────────────────────────────────────────────────────
    
    // CAN Bus Status
    QString status() const { return m_status; }
    bool initialized() const { return m_initialized; }
    
    // IO Module Health
    bool ioModuleOnline() const { return m_ioHealth.isOnline; }
    QString ioModuleVersion() const;
    int ioModuleUptime() const { return m_ioHealth.uptime; }
    int ioModuleState() const { return m_ioHealth.state; }
    QString ioModuleStateText() const;
    
    // Sensor Data
    QVariantList moistureSensors() const;
    QVariantList pressureSensors() const;
    float temperatureSensor() const { return m_sensorData.temperature; }
    QVariantList binaryInputs() const;
    bool sensorDataValid() const { return m_sensorData.isValid; }
    QString sensorDataTimestamp() const;
    
    // Actuator States
    QVariantList valveStates() const;
    QVariantList outputStates() const;
    
    // ── QML Invokable Methods ───────────────────────────────────────────────
    
    Q_INVOKABLE bool initCAN(const QString &interface = "can0", int bitrate = 10000);
    Q_INVOKABLE void shutdownCAN();
    Q_INVOKABLE bool resetCAN();
    
    // Actuator Commands
    Q_INVOKABLE bool setValve(int valveIndex, bool state);
    Q_INVOKABLE bool setAllValves(quint8 mask, quint8 states);
    Q_INVOKABLE bool setBinaryOutput(int outputIndex, bool state);
    Q_INVOKABLE bool setAllOutputs(quint8 mask, quint8 states);
    
    // Configuration
    Q_INVOKABLE bool setSensorInterval(quint8 intervalSeconds);
    Q_INVOKABLE bool requestStatus();
    
signals:
    // CAN Bus Status
    void statusChanged();
    void initializedChanged();
    void errorOccurred(const QString &error);
    
    // IO Module Health
    void ioModuleOnlineChanged();
    void ioModuleVersionChanged();
    void ioModuleUptimeChanged();
    void ioModuleStateChanged();
    
    // Sensor Data
    void sensorDataChanged();
    
    // Actuator States
    void valveStatesChanged();
    void outputStatesChanged();
    
    // Command Results
    void commandSuccess(const QString &message);
    void commandFailed(const QString &error);

private slots:
    void onCANReadable();
    void onHeartbeatTimer();
    void onHealthCheckTimer();
    void onCommandResponseTimeout();
    
private:
    // ── CAN Socket Management ───────────────────────────────────────────────
    bool openSocket(const QString &interface);
    void closeSocket();
    bool configureInterface(const QString &interface, int bitrate);
    bool bringInterfaceUp(const QString &interface);
    
    // ── CAN TX Methods ──────────────────────────────────────────────────────
    bool sendCANFrame(quint32 canId, const QByteArray &data);
    bool sendHeartbeat();
    bool sendNodeAnnounce();
    bool sendValveCommand(quint8 mask, quint8 states);
    bool sendOutputCommand(quint8 mask, quint8 states);
    bool sendConfigSetInterval(quint8 interval);
    bool sendStatusRequest();
    
    // ── CAN RX Processing ───────────────────────────────────────────────────
    void processCANFrame(quint32 canId, const QByteArray &data);
    void processIOHeartbeat(const QByteArray &data);
    void processIOAnnounce(const QByteArray &data);
    void processMoistureSensors(quint32 canId, const QByteArray &data);
    void processPressureSensors(quint32 canId, const QByteArray &data);
    void processTemperatureSensor(const QByteArray &data);
    void processBinaryInputs(const QByteArray &data);
    void processValveResponse(const QByteArray &data);
    void processOutputResponse(const QByteArray &data);
    void processConfigAck(const QByteArray &data);
    void processStatusResponse(const QByteArray &data);
    
    // ── Helper Methods ──────────────────────────────────────────────────────
    void updateIOModuleOnlineStatus();
    float bytesToFloat(const QByteArray &data, int offset) const;
    quint16 bytesToUint16(const QByteArray &data, int offset) const;
    void startCommandRetry(quint32 commandId, const QByteArray &commandData, const QString &commandName);
    void cancelCommandRetry();
    
    // ── State ───────────────────────────────────────────────────────────────
    int m_socketFd;
    QSocketNotifier *m_socketNotifier;
    QTimer *m_heartbeatTimer;
    QTimer *m_healthCheckTimer;
    QTimer *m_commandResponseTimer;
    CANLogger *m_logger;
    QString m_status;
    bool m_initialized;
    QString m_currentInterface;
    quint16 m_processorUptime;  // seconds, modulo 65536
    
    // Data Models
    SensorData m_sensorData;
    ActuatorState m_actuatorState;
    IOModuleHealth m_ioHealth;
    
    // Command Retry State
    struct PendingCommand {
        quint32 canId;
        QByteArray data;
        QString name;
        int retryCount;
        bool active;
        
        PendingCommand() : canId(0), retryCount(0), active(false) {}
    } m_pendingCommand;
    
    // ── CAN Protocol Constants (per CAN_Interface_Common.md) ────────────────
    
    // System Messages (0x0xx)
    static constexpr quint32 CAN_ID_IO_HEARTBEAT = 0x000;
    static constexpr quint32 CAN_ID_IO_ANNOUNCE = 0x001;
    static constexpr quint32 CAN_ID_PROC_HEARTBEAT = 0x0F0;
    static constexpr quint32 CAN_ID_PROC_ANNOUNCE = 0x0F1;
    
    // Sensor Data (0x1xx)
    static constexpr quint32 CAN_ID_MOISTURE_0_1 = 0x100;
    static constexpr quint32 CAN_ID_MOISTURE_2_3 = 0x101;
    static constexpr quint32 CAN_ID_MOISTURE_4_5 = 0x102;
    static constexpr quint32 CAN_ID_MOISTURE_6_7 = 0x103;
    static constexpr quint32 CAN_ID_PRESSURE_0_1 = 0x104;
    static constexpr quint32 CAN_ID_PRESSURE_2 = 0x105;
    static constexpr quint32 CAN_ID_TEMPERATURE = 0x106;
    static constexpr quint32 CAN_ID_BINARY_INPUTS = 0x107;
    
    // Actuator Commands (0x2xx)
    static constexpr quint32 CAN_ID_VALVE_CMD = 0x200;
    static constexpr quint32 CAN_ID_OUTPUT_CMD = 0x201;
    
    // Actuator Responses (0x3xx)
    static constexpr quint32 CAN_ID_VALVE_RESPONSE = 0x300;
    static constexpr quint32 CAN_ID_OUTPUT_RESPONSE = 0x301;
    
    // Configuration (0x4xx)
    static constexpr quint32 CAN_ID_CONFIG_SET_INTERVAL = 0x400;
    static constexpr quint32 CAN_ID_CONFIG_STATUS_REQ = 0x401;
    
    // Timing (per CAN_Interface_Proc.md)
    static constexpr int HEARTBEAT_INTERVAL_MS = 5000;  // 5 seconds
    static constexpr int HEALTH_CHECK_INTERVAL_MS = 1000;  // 1 second
    static constexpr int IO_HEARTBEAT_TIMEOUT_MS = 15000;  // 15 seconds (3× heartbeat)
    static constexpr int COMMAND_RESPONSE_TIMEOUT_MS = 1000;  // 1 second
    static constexpr int COMMAND_RETRY_MAX = 3;  // Max 3 retries
    static constexpr int COMMAND_RETRY_INTERVAL_MS = 500;  // 500ms between retries
    
    // Node Types
    static constexpr quint8 NODE_TYPE_IO_MODULE = 0x01;
    static constexpr quint8 NODE_TYPE_PROCESSOR = 0x02;
};

#endif // CAN_CONTROLLER_HPP
