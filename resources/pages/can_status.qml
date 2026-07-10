/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2026 HB Watertechnologie — www.EmbedTech.nl
 * 
 * CAN Bus Status and IO Module Health Page
 * Per CAN_Interface_Proc.md Section 9.1
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0
import PhyTheme 1.0
import "../controls"
import HBWT.CAN 1.0

Page {
    id: canPage
    background: Rectangle { color: PhyTheme.bgDark }

    header: PhyToolBar {
        title: "CAN Bus Status"
        buttonBack.onClicked: stack.pop()
        buttonMenu.visible: false
    }

    // CAN Controller instance
    CANController {
        id: canController
        
        Component.onCompleted: {
            // Initialize CAN interface on page load (10 kbit/s per spec)
            if (!canController.initialized) {
                canController.initCAN("can1", 10000)
            }
        }
        
        onErrorOccurred: function(error) {
            errorText.text = error
            errorText.visible = true
            errorTimer.start()
        }
        
        onCommandSuccess: function(message) {
            successText.text = message
            successText.visible = true
            successTimer.start()
        }
    }

    // Hide error message after 5 seconds
    Timer {
        id: errorTimer
        interval: 5000
        onTriggered: errorText.visible = false
    }

    // Hide success message after 3 seconds
    Timer {
        id: successTimer
        interval: 3000
        onTriggered: successText.visible = false
    }

    // Format uptime in human-readable format
    function formatUptime(seconds) {
        if (seconds === 0) return "N/A"
        
        var days = Math.floor(seconds / 86400)
        var hours = Math.floor((seconds % 86400) / 3600)
        var mins = Math.floor((seconds % 3600) / 60)
        var secs = seconds % 60
        
        var parts = []
        if (days > 0) parts.push(days + "d")
        if (hours > 0) parts.push(hours + "h")
        if (mins > 0) parts.push(mins + "m")
        if (secs > 0 || parts.length === 0) parts.push(secs + "s")
        
        return parts.join(" ")
    }

    // ── Main Layout ──────────────────────────────────────────────────────────
    ScrollView {
        anchors.fill: parent
        anchors.margins: PhyTheme.marginBig
        clip: true

        ColumnLayout {
            width: parent.width - PhyTheme.marginBig * 2
            spacing: PhyTheme.marginBig

            // ── CAN Interface Status ────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: statusCol.implicitHeight + PhyTheme.marginBig * 2
                radius: 10
                color: PhyTheme.cardDark

                ColumnLayout {
                    id: statusCol
                    anchors.fill: parent
                    anchors.margins: PhyTheme.marginBig
                    spacing: PhyTheme.marginRegular

                    Label {
                        text: "CAN Interface"
                        font.bold: true
                        color: PhyTheme.white
                        font.pointSize: PhyTheme.font.pointSize * 0.72
                    }

                    // Status indicator
                    RowLayout {
                        spacing: 12
                        
                        Rectangle {
                            width: 16; height: 16
                            radius: 8
                            color: canController.initialized ? PhyTheme.teal1 : PhyTheme.gray4
                            
                            SequentialAnimation on opacity {
                                running: canController.initialized
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 0.3; duration: 800 }
                                NumberAnimation { from: 0.3; to: 1.0; duration: 800 }
                            }
                        }
                        
                        Label {
                            text: canController.status
                            color: canController.initialized ? PhyTheme.teal1 : PhyTheme.gray2
                            font.pointSize: PhyTheme.font.pointSize * 0.55
                        }
                    }

                    // Interface settings
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: PhyTheme.marginBig
                        rowSpacing: 6

                        Label {
                            text: "Interface:"
                            color: PhyTheme.gray2
                            font.pointSize: PhyTheme.font.pointSize * 0.5
                        }
                        
                        Label {
                            text: "can1"
                            color: PhyTheme.white
                            font.pointSize: PhyTheme.font.pointSize * 0.5
                            font.bold: true
                        }

                        Label {
                            text: "Bitrate:"
                            color: PhyTheme.gray2
                            font.pointSize: PhyTheme.font.pointSize * 0.5
                        }
                        
                        Label {
                            text: "10 kbit/s"
                            color: PhyTheme.white
                            font.pointSize: PhyTheme.font.pointSize * 0.5
                            font.bold: true
                        }
                    }

                    // Success message
                    Label {
                        id: successText
                        Layout.fillWidth: true
                        visible: false
                        text: ""
                        color: PhyTheme.teal1
                        wrapMode: Text.WordWrap
                        font.pointSize: PhyTheme.font.pointSize * 0.5
                        background: Rectangle {
                            color: "#1f3d2f"
                            radius: 6
                            border.color: PhyTheme.teal1
                            border.width: 1
                        }
                        padding: 10
                    }

                    // Error display
                    Label {
                        id: errorText
                        Layout.fillWidth: true
                        visible: false
                        text: ""
                        color: "#ff6b6b"
                        wrapMode: Text.WordWrap
                        font.pointSize: PhyTheme.font.pointSize * 0.5
                        background: Rectangle {
                            color: "#3d1f1f"
                            radius: 6
                            border.color: "#ff6b6b"
                            border.width: 1
                        }
                        padding: 10
                    }
                }
            }

            // ── IO Module Health ────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: ioModuleCol.implicitHeight + PhyTheme.marginBig * 2
                radius: 10
                color: PhyTheme.cardDark
                border.color: canController.ioModuleOnline ? PhyTheme.teal2 : "#ff6b6b"
                border.width: 2

                ColumnLayout {
                    id: ioModuleCol
                    anchors.fill: parent
                    anchors.margins: PhyTheme.marginBig
                    spacing: PhyTheme.marginRegular

                    RowLayout {
                        Layout.fillWidth: true
                        
                        Label {
                            text: "IO Module Status"
                            font.bold: true
                            color: PhyTheme.white
                            font.pointSize: PhyTheme.font.pointSize * 0.72
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        // Online indicator
                        RowLayout {
                            spacing: 8
                            
                            Rectangle {
                                width: 14; height: 14
                                radius: 7
                                color: canController.ioModuleOnline ? PhyTheme.teal1 : "#ff6b6b"
                                
                                SequentialAnimation on opacity {
                                    running: canController.ioModuleOnline
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 1.0; to: 0.4; duration: 1000 }
                                    NumberAnimation { from: 0.4; to: 1.0; duration: 1000 }
                                }
                            }
                            
                            Label {
                                text: canController.ioModuleOnline ? "ONLINE" : "OFFLINE"
                                color: canController.ioModuleOnline ? PhyTheme.teal1 : "#ff6b6b"
                                font.pointSize: PhyTheme.font.pointSize * 0.6
                                font.bold: true
                            }
                        }
                    }

                    // Firmware version
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: PhyTheme.marginBig
                        rowSpacing: 10

                        Label {
                            text: "Firmware Version:"
                            color: PhyTheme.gray2
                            font.pointSize: PhyTheme.font.pointSize * 0.52
                        }
                        
                        Label {
                            text: canController.ioModuleVersion !== "" 
                                ? canController.ioModuleVersion 
                                : "N/A"
                            color: PhyTheme.white
                            font.pointSize: PhyTheme.font.pointSize * 0.52
                            font.bold: true
                        }

                        // Uptime
                        Label {
                            text: "Uptime:"
                            color: PhyTheme.gray2
                            font.pointSize: PhyTheme.font.pointSize * 0.52
                        }
                        
                        Label {
                            text: formatUptime(canController.ioModuleUptime)
                            color: PhyTheme.white
                            font.pointSize: PhyTheme.font.pointSize * 0.52
                            font.bold: true
                        }

                        // State
                        Label {
                            text: "Current State:"
                            color: PhyTheme.gray2
                            font.pointSize: PhyTheme.font.pointSize * 0.52
                        }
                        
                        RowLayout {
                            spacing: 8
                            
                            Rectangle {
                                width: 24; height: 24
                                radius: 4
                                color: {
                                    if (canController.ioModuleState === 0) return "#1a4d2e"      // Init - green
                                    if (canController.ioModuleState === 1) return "#1a3a4d"      // Ready - blue
                                    if (canController.ioModuleState === 2) return "#4d3a1a"      // Error - orange
                                    return PhyTheme.gray4                                        // Unknown - gray
                                }
                                border.color: {
                                    if (canController.ioModuleState === 0) return PhyTheme.teal1
                                    if (canController.ioModuleState === 1) return "#3498db"
                                    if (canController.ioModuleState === 2) return "#f39c12"
                                    return PhyTheme.gray3
                                }
                                border.width: 1

                                Label {
                                    anchors.centerIn: parent
                                    text: canController.ioModuleState.toString()
                                    color: parent.border.color
                                    font.pointSize: PhyTheme.font.pointSize * 0.5
                                    font.bold: true
                                }
                            }
                            
                            Label {
                                text: canController.ioModuleStateText
                                color: PhyTheme.white
                                font.pointSize: PhyTheme.font.pointSize * 0.52
                                font.bold: true
                            }
                        }
                    }

                    // Action buttons
                    RowLayout {
                        Layout.alignment: Qt.AlignLeft
                        Layout.topMargin: 10
                        spacing: 10
                        
                        Button {
                            id: requestStatusBtn
                            text: "Request Status"
                            enabled: canController.initialized
                            font.pointSize: PhyTheme.font.pointSize * 0.55
                            
                            property bool touching: false
                            
                            scale: touching ? 0.95 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                            
                            background: Rectangle {
                                implicitWidth: 160
                                implicitHeight: 45
                                radius: 6
                                color: requestStatusBtn.touching
                                    ? (requestStatusBtn.enabled ? Qt.darker(PhyTheme.teal2, 1.4) : PhyTheme.gray4)
                                    : (requestStatusBtn.enabled ? PhyTheme.teal2 : PhyTheme.gray4)
                                border.color: requestStatusBtn.enabled ? PhyTheme.teal1 : PhyTheme.gray3
                                border.width: 2
                                
                                Behavior on color { ColorAnimation { duration: 80 } }
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                color: parent.enabled ? PhyTheme.white : PhyTheme.gray2
                                font.pointSize: PhyTheme.font.pointSize * 0.55
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            onPressed: touching = true
                            onReleased: touching = false
                            onCanceled: touching = false
                            onClicked: canController.requestStatus()
                        }
                        
                        Button {
                            id: resetCanBtn
                            text: "Reset CAN Bus"
                            enabled: canController.initialized
                            font.pointSize: PhyTheme.font.pointSize * 0.55
                            
                            property bool touching: false
                            
                            scale: touching ? 0.95 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                            
                            background: Rectangle {
                                implicitWidth: 160
                                implicitHeight: 45
                                radius: 6
                                color: resetCanBtn.touching
                                    ? (resetCanBtn.enabled ? Qt.darker("#e67e22", 1.4) : PhyTheme.gray4)
                                    : (resetCanBtn.enabled ? "#e67e22" : PhyTheme.gray4)
                                border.color: resetCanBtn.enabled ? "#d35400" : PhyTheme.gray3
                                border.width: 2
                                
                                Behavior on color { ColorAnimation { duration: 80 } }
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                color: parent.enabled ? PhyTheme.white : PhyTheme.gray2
                                font.pointSize: PhyTheme.font.pointSize * 0.55
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            onPressed: touching = true
                            onReleased: touching = false
                            onCanceled: touching = false
                            onClicked: canController.resetCAN()
                        }
                    }
                }
            }

            // Footer spacer
            Item { implicitHeight: PhyTheme.marginBig }
        }
    }
}
