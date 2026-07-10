/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2026 HB Watertechnologie
 * 
 * SocketCAN interface implementation
 */

#include "can_controller.hpp"
#include <QDebug>
#include <QProcess>

// Linux SocketCAN headers
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <linux/can.h>
#include <linux/can/raw.h>
#include <net/if.h>
#include <unistd.h>
#include <cstring>

CANController::CANController(QObject *parent)
    : QObject(parent)
    , m_socketFd(-1)
    , m_socketNotifier(nullptr)
    , m_scanTimer(nullptr)
    , m_status("Not initialized")
    , m_initialized(false)
    , m_scanning(false)
{
    m_scanTimer = new QTimer(this);
    m_scanTimer->setSingleShot(true);
    connect(m_scanTimer, &QTimer::timeout, this, &CANController::onScanTimeout);
}

CANController::~CANController()
{
    shutdownCAN();
}

QVariantList CANController::nodes() const
{
    QVariantList list;
    for (const CANNode &node : m_discoveredNodes) {
        QVariantMap map;
        map["nodeId"] = node.nodeId;
        map["deviceType"] = node.deviceType;
        map["deviceTypeName"] = node.deviceTypeName;
        map["fwVersion"] = QString("v%1.%2").arg(node.fwMajor).arg(node.fwMinor);
        map["status"] = node.status;
        map["statusText"] = node.statusText;
        list.append(map);
    }
    return list;
}

bool CANController::initCAN(const QString &interface, int bitrate)
{
    qDebug() << "[CAN] Initializing interface:" << interface << "at" << bitrate << "bps";
    
    if (m_initialized) {
        qWarning() << "[CAN] Already initialized!";
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
    
    qDebug() << "[CAN] Initialization successful";
    return true;
}

void CANController::shutdownCAN()
{
    if (!m_initialized) {
        return;
    }
    
    qDebug() << "[CAN] Shutting down";
    
    if (m_scanTimer->isActive()) {
        m_scanTimer->stop();
    }
    
    closeSocket();
    
    m_initialized = false;
    m_status = "Not initialized";
    
    emit initializedChanged();
    emit statusChanged();
}

void CANController::scanBus()
{
    if (!m_initialized) {
        qWarning() << "[CAN] Cannot scan: not initialized";
        emit errorOccurred("CAN interface not initialized");
        return;
    }
    
    if (m_scanning) {
        qWarning() << "[CAN] Scan already in progress";
        return;
    }
    
    qDebug() << "[CAN] Starting bus scan";
    
    // Clear previous results
    clearNodes();
    
    m_scanning = true;
    emit scanningChanged();
    
    // Send broadcast identification request
    if (!sendBroadcast()) {
        m_scanning = false;
        emit scanningChanged();
        emit errorOccurred("Failed to send broadcast");
        return;
    }
    
    // Start timeout timer for scan completion
    m_scanTimer->start(SCAN_TIMEOUT_MS);
    
    m_status = "Scanning...";
    emit statusChanged();
}

void CANController::clearNodes()
{
    if (!m_discoveredNodes.isEmpty()) {
        m_discoveredNodes.clear();
        emit discoveredCountChanged();
        emit nodesChanged();
    }
}

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

bool CANController::sendBroadcast()
{
    struct can_frame frame;
    std::memset(&frame, 0, sizeof(frame));
    
    frame.can_id = CAN_ID_BROADCAST;
    frame.can_dlc = 1;
    frame.data[0] = CMD_IDENTIFY;
    
    ssize_t nbytes = write(m_socketFd, &frame, sizeof(frame));
    if (nbytes != sizeof(frame)) {
        qCritical() << "[CAN] Failed to send broadcast:" << strerror(errno);
        return false;
    }
    
    qDebug() << "[CAN] Broadcast sent: ID 0x" << QString::number(frame.can_id, 16)
             << " Data: 0x" << QString::number(frame.data[0], 16);
    return true;
}

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
    
    qDebug() << "[CAN] Frame received: ID 0x" << QString::number(frame.can_id, 16)
             << " DLC:" << frame.can_dlc
             << " Data:" << data.toHex(' ');
    
    processCANFrame(frame.can_id, data);
}

void CANController::processCANFrame(quint32 canId, const QByteArray &data)
{
    // Check if this is a slave response (0x200-0x2FF)
    if (canId < CAN_ID_SLAVE_BASE || canId >= (CAN_ID_SLAVE_BASE + 0x100)) {
        // Not a slave response - ignore
        return;
    }
    
    // Parse slave response
    // Format: [Node_ID, Device_Type, FW_Major, FW_Minor, Status]
    if (data.size() < 5) {
        qWarning() << "[CAN] Invalid slave response: insufficient data";
        return;
    }
    
    CANNode node;
    node.nodeId = static_cast<quint8>(data[0]);
    node.deviceType = static_cast<quint8>(data[1]);
    node.fwMajor = static_cast<quint8>(data[2]);
    node.fwMinor = static_cast<quint8>(data[3]);
    node.status = static_cast<quint8>(data[4]);
    node.deviceTypeName = deviceTypeToString(node.deviceType);
    node.statusText = statusToString(node.status);
    
    qDebug() << "[CAN] Node discovered: ID" << node.nodeId
             << "Type:" << node.deviceTypeName
             << "FW:" << node.fwMajor << "." << node.fwMinor
             << "Status:" << node.statusText;
    
    addNode(node);
}

void CANController::addNode(const CANNode &node)
{
    // Check if node already exists (update instead of duplicate)
    for (int i = 0; i < m_discoveredNodes.size(); ++i) {
        if (m_discoveredNodes[i].nodeId == node.nodeId) {
            m_discoveredNodes[i] = node;
            emit nodesChanged();
            return;
        }
    }
    
    // New node - add to list
    m_discoveredNodes.append(node);
    
    emit discoveredCountChanged();
    emit nodesChanged();
}

void CANController::onScanTimeout()
{
    qDebug() << "[CAN] Scan timeout - found" << m_discoveredNodes.size() << "nodes";
    
    m_scanning = false;
    m_status = QString("Scan complete: %1 node(s) found").arg(m_discoveredNodes.size());
    
    emit scanningChanged();
    emit statusChanged();
    emit scanComplete(m_discoveredNodes.size());
}

QString CANController::deviceTypeToString(quint8 type) const
{
    switch (type) {
        case 0x10: return "Valve Controller";
        case 0x20: return "Moisture Sensor";
        case 0x30: return "Flow Meter";
        case 0x40: return "Pressure Sensor";
        case 0x50: return "Temperature Sensor";
        case 0x60: return "Pump Controller";
        default: return QString("Unknown (0x%1)").arg(type, 2, 16, QChar('0'));
    }
}

QString CANController::statusToString(quint8 status) const
{
    switch (status) {
        case 0x00: return "OK";
        case 0x01: return "Warning";
        case 0x02: return "Error";
        case 0xFF: return "Offline";
        default: return QString("Unknown (%1)").arg(status);
    }
}
