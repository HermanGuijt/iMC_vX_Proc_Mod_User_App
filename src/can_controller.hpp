/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2026 HB Watertechnologie
 * 
 * SocketCAN interface for CAN bus communication
 */

#ifndef CAN_CONTROLLER_HPP
#define CAN_CONTROLLER_HPP

#include <QObject>
#include <QSocketNotifier>
#include <QTimer>
#include <QVariantList>
#include <QString>

/**
 * CAN Node information structure
 */
struct CANNode {
    quint8 nodeId;
    quint8 deviceType;
    quint8 fwMajor;
    quint8 fwMinor;
    quint8 status;
    QString deviceTypeName;
    QString statusText;
};

Q_DECLARE_METATYPE(CANNode)

/**
 * @brief CAN Bus Controller using Linux SocketCAN
 * 
 * Provides async CAN communication with slave nodes:
 * - Broadcast identification requests
 * - Receive and parse slave responses
 * - Manage discovered nodes list
 * - Expose status to QML via Q_PROPERTY
 */
class CANController : public QObject
{
    Q_OBJECT
    
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(bool initialized READ initialized NOTIFY initializedChanged)
    Q_PROPERTY(int discoveredCount READ discoveredCount NOTIFY discoveredCountChanged)
    Q_PROPERTY(QVariantList nodes READ nodes NOTIFY nodesChanged)
    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)

public:
    explicit CANController(QObject *parent = nullptr);
    ~CANController();
    
    // Property getters
    QString status() const { return m_status; }
    bool initialized() const { return m_initialized; }
    int discoveredCount() const { return m_discoveredNodes.size(); }
    QVariantList nodes() const;
    bool scanning() const { return m_scanning; }
    
    // QML invokable methods
    Q_INVOKABLE bool initCAN(const QString &interface = "can0", int bitrate = 10000);
    Q_INVOKABLE void shutdownCAN();
    Q_INVOKABLE void scanBus();
    Q_INVOKABLE void clearNodes();
    
signals:
    void statusChanged();
    void initializedChanged();
    void discoveredCountChanged();
    void nodesChanged();
    void scanningChanged();
    void errorOccurred(const QString &error);
    void scanComplete(int nodeCount);

private slots:
    void onCANReadable();
    void onScanTimeout();
    
private:
    // CAN socket management
    bool openSocket(const QString &interface);
    void closeSocket();
    bool configureInterface(const QString &interface, int bitrate);
    bool bringInterfaceUp(const QString &interface);
    
    // CAN messaging
    bool sendBroadcast();
    void processCANFrame(quint32 canId, const QByteArray &data);
    void addNode(const CANNode &node);
    QString deviceTypeToString(quint8 type) const;
    QString statusToString(quint8 status) const;
    
    // State
    int m_socketFd;
    QSocketNotifier *m_socketNotifier;
    QTimer *m_scanTimer;
    QString m_status;
    bool m_initialized;
    bool m_scanning;
    QList<CANNode> m_discoveredNodes;
    QString m_currentInterface;
    
    // CAN protocol constants
    static constexpr quint32 CAN_ID_BROADCAST = 0x100;
    static constexpr quint32 CAN_ID_SLAVE_BASE = 0x200;
    static constexpr quint8 CMD_IDENTIFY = 0x01;
    static constexpr int SCAN_TIMEOUT_MS = 2000;
};

#endif // CAN_CONTROLLER_HPP
