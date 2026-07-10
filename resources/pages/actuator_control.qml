/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2026 HB Watertechnologie — www.EmbedTech.nl
 * 
 * Actuator Control Page
 * Per CAN_Interface_Proc.md Section 9.3
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0
import PhyTheme 1.0
import "../controls"
import HBWT.CAN 1.0

Page {
    id: actuatorPage
    background: Rectangle { color: PhyTheme.bgDark }

    header: PhyToolBar {
        title: "Actuator Control"
        buttonBack.onClicked: stack.pop()
        buttonMenu.visible: false
    }

    // CAN Controller instance
    CANController {
        id: canController
        
        Component.onCompleted: {
            // Initialize CAN interface on page load
            if (!canController.initialized) {
                canController.initCAN("can1", 10000)
            }
        }
        
        onCommandSuccess: function(message) {
            feedback.text = "✓ " + message
            feedback.messageType = "success"
            feedback.visible = true
            feedbackTimer.restart()
        }
        
        onCommandFailed: function(error) {
            feedback.text = "✗ " + error
            feedback.messageType = "error"
            feedback.visible = true
            feedbackTimer.restart()
        }
    }

    // Hide feedback message after 5 seconds
    Timer {
        id: feedbackTimer
        interval: 5000
        onTriggered: feedback.visible = false
    }

    // ── Main Layout ──────────────────────────────────────────────────────────
    ScrollView {
        anchors.fill: parent
        anchors.margins: PhyTheme.marginBig
        clip: true

        ColumnLayout {
            width: parent.width - PhyTheme.marginBig * 2
            spacing: PhyTheme.marginBig

            // ── Feedback Message ────────────────────────────────────────────
            Rectangle {
                id: feedback
                Layout.fillWidth: true
                implicitHeight: feedbackText.implicitHeight + 20
                radius: 6
                color: feedback.messageType === "success" ? "#1f3d2f" : "#3d1f1f"
                border.color: feedback.messageType === "success" ? PhyTheme.teal1 : "#ff6b6b"
                border.width: 1
                visible: false
                
                property alias text: feedbackText.text
                property string messageType: "success"  // "success" or "error"

                Label {
                    id: feedbackText
                    anchors.centerIn: parent
                    text: ""
                    color: feedback.messageType === "success" ? PhyTheme.teal1 : "#ff6b6b"
                    font.pointSize: PhyTheme.font.pointSize * 0.55
                }
            }

            // ── Valve Control (8 valves) ────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: valveCol.implicitHeight + PhyTheme.marginBig * 2
                radius: 10
                color: PhyTheme.cardDark

                ColumnLayout {
                    id: valveCol
                    anchors.fill: parent
                    anchors.margins: PhyTheme.marginBig
                    spacing: PhyTheme.marginRegular

                    RowLayout {
                        Layout.fillWidth: true
                        
                        Label {
                            text: "Valve Control (8×)"
                            font.bold: true
                            color: PhyTheme.white
                            font.pointSize: PhyTheme.font.pointSize * 0.72
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Button {
                            id: allCloseBtn
                            text: "All CLOSE"
                            enabled: canController.initialized && canController.ioModuleOnline
                            font.pointSize: PhyTheme.font.pointSize * 0.5
                            
                            property bool touching: false
                            
                            scale: touching ? 0.95 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                            
                            background: Rectangle {
                                implicitWidth: 120
                                implicitHeight: 38
                                radius: 6
                                color: allCloseBtn.touching
                                    ? (allCloseBtn.enabled ? Qt.darker("#d63031", 1.4) : PhyTheme.gray4)
                                    : (allCloseBtn.enabled ? "#d63031" : PhyTheme.gray4)
                                border.color: allCloseBtn.enabled ? "#c0392b" : PhyTheme.gray3
                                border.width: 2
                                
                                Behavior on color { ColorAnimation { duration: 80 } }
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                color: parent.enabled ? PhyTheme.white : PhyTheme.gray2
                                font.pointSize: PhyTheme.font.pointSize * 0.5
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            onPressed: touching = true
                            onReleased: touching = false
                            onCanceled: touching = false
                            onClicked: canController.setAllValves(0xFF, 0x00)
                        }
                    }

                    // Table header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Label {
                            Layout.preferredWidth: 80
                            text: "Valve"
                            color: PhyTheme.gray2
                            font.pointSize: PhyTheme.font.pointSize * 0.5
                            font.bold: true
                        }
                        
                        Label {
                            Layout.fillWidth: true
                            text: "Control"
                            color: PhyTheme.gray2
                            font.pointSize: PhyTheme.font.pointSize * 0.5
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                        
                        Label {
                            Layout.preferredWidth: 80
                            text: "Status"
                            color: PhyTheme.gray2
                            font.pointSize: PhyTheme.font.pointSize * 0.5
                            font.bold: true
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    // Valves 0-7
                    Repeater {
                        model: 8
                        
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 50
                            radius: 6
                            color: PhyTheme.bgDarker
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                // Valve label
                                Label {
                                    Layout.preferredWidth: 60
                                    text: "Valve " + index
                                    color: PhyTheme.white
                                    font.pointSize: PhyTheme.font.pointSize * 0.55
                                }

                                // Control buttons
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 8
                                    
                                    Button {
                                        id: openBtn
                                        text: "OPEN"
                                        enabled: canController.initialized && canController.ioModuleOnline
                                        font.pointSize: PhyTheme.font.pointSize * 0.5
                                        
                                        property bool touching: false
                                        
                                        scale: touching ? 0.95 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 100 } }
                                        
                                        background: Rectangle {
                                            implicitWidth: 150
                                            implicitHeight: 38
                                            radius: 6
                                            color: openBtn.touching
                                                ? (openBtn.enabled ? Qt.darker(PhyTheme.teal2, 1.4) : PhyTheme.gray4)
                                                : (openBtn.enabled ? PhyTheme.teal2 : PhyTheme.gray4)
                                            border.color: openBtn.enabled ? PhyTheme.teal1 : PhyTheme.gray3
                                            border.width: 2
                                            
                                            Behavior on color { ColorAnimation { duration: 80 } }
                                        }
                                        
                                        contentItem: Text {
                                            text: parent.text
                                            color: parent.enabled ? PhyTheme.white : PhyTheme.gray2
                                            font.pointSize: PhyTheme.font.pointSize * 0.5
                                            font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        
                                        onPressed: touching = true
                                        onReleased: touching = false
                                        onCanceled: touching = false
                                        onClicked: canController.setValve(index, true)
                                    }
                                    
                                    Button {
                                        id: closeBtn
                                        text: "CLOSE"
                                        enabled: canController.initialized && canController.ioModuleOnline
                                        font.pointSize: PhyTheme.font.pointSize * 0.5
                                        
                                        property bool touching: false
                                        
                                        scale: touching ? 0.95 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 100 } }
                                        
                                        background: Rectangle {
                                            implicitWidth: 150
                                            implicitHeight: 38
                                            radius: 6
                                            color: closeBtn.touching
                                                ? (closeBtn.enabled ? Qt.darker(PhyTheme.gray5, 1.4) : PhyTheme.gray4)
                                                : (closeBtn.enabled ? PhyTheme.gray5 : PhyTheme.gray4)
                                            border.color: closeBtn.enabled ? PhyTheme.gray3 : PhyTheme.gray3
                                            border.width: 2
                                            
                                            Behavior on color { ColorAnimation { duration: 80 } }
                                        }
                                        
                                        contentItem: Text {
                                            text: parent.text
                                            color: parent.enabled ? PhyTheme.white : PhyTheme.gray2
                                            font.pointSize: PhyTheme.font.pointSize * 0.5
                                            font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        
                                        onPressed: touching = true
                                        onReleased: touching = false
                                        onCanceled: touching = false
                                        onClicked: canController.setValve(index, false)
                                    }
                                }

                                // Status indicator
                                RowLayout {
                                    Layout.preferredWidth: 60
                                    Layout.alignment: Qt.AlignRight
                                    spacing: 6
                                    
                                    Rectangle {
                                        width: 12
                                        height: 12
                                        radius: 6
                                        color: canController.valveStates[index] && canController.valveStates[index].actual
                                            ? PhyTheme.teal1
                                            : PhyTheme.gray4
                                    }
                                    
                                    Label {
                                        text: canController.valveStates[index] && canController.valveStates[index].actual
                                            ? "Open"
                                            : "Closed"
                                        color: canController.valveStates[index] && canController.valveStates[index].actual
                                            ? PhyTheme.teal1
                                            : PhyTheme.gray3
                                        font.pointSize: PhyTheme.font.pointSize * 0.45
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Binary Output Control (3 outputs) ───────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: outputCol.implicitHeight + PhyTheme.marginBig * 2
                radius: 10
                color: PhyTheme.cardDark

                ColumnLayout {
                    id: outputCol
                    anchors.fill: parent
                    anchors.margins: PhyTheme.marginBig
                    spacing: PhyTheme.marginRegular

                    RowLayout {
                        Layout.fillWidth: true
                        
                        Label {
                            text: "Binary Outputs (3×)"
                            font.bold: true
                            color: PhyTheme.white
                            font.pointSize: PhyTheme.font.pointSize * 0.72
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Button {
                            id: allOffBtn
                            text: "All OFF"
                            enabled: canController.initialized && canController.ioModuleOnline
                            font.pointSize: PhyTheme.font.pointSize * 0.5
                            
                            property bool touching: false
                            
                            scale: touching ? 0.95 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                            
                            background: Rectangle {
                                implicitWidth: 120
                                implicitHeight: 38
                                radius: 6
                                color: allOffBtn.touching
                                    ? (allOffBtn.enabled ? Qt.darker("#d63031", 1.4) : PhyTheme.gray4)
                                    : (allOffBtn.enabled ? "#d63031" : PhyTheme.gray4)
                                border.color: allOffBtn.enabled ? "#c0392b" : PhyTheme.gray3
                                border.width: 2
                                
                                Behavior on color { ColorAnimation { duration: 80 } }
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                color: parent.enabled ? PhyTheme.white : PhyTheme.gray2
                                font.pointSize: PhyTheme.font.pointSize * 0.5
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            onPressed: touching = true
                            onReleased: touching = false
                            onCanceled: touching = false
                            onClicked: canController.setAllOutputs(0x07, 0x00)
                        }
                    }

                    // Table header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Label {
                            Layout.preferredWidth: 80
                            text: "Output"
                            color: PhyTheme.gray2
                            font.pointSize: PhyTheme.font.pointSize * 0.5
                            font.bold: true
                        }
                        
                        Label {
                            Layout.fillWidth: true
                            text: "Control"
                            color: PhyTheme.gray2
                            font.pointSize: PhyTheme.font.pointSize * 0.5
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                        
                        Label {
                            Layout.preferredWidth: 80
                            text: "Status"
                            color: PhyTheme.gray2
                            font.pointSize: PhyTheme.font.pointSize * 0.5
                            font.bold: true
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    // Outputs 0-2
                    Repeater {
                        model: 3
                        
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 50
                            radius: 6
                            color: PhyTheme.bgDarker
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                // Output label
                                Label {
                                    Layout.preferredWidth: 60
                                    text: "Output " + index
                                    color: PhyTheme.white
                                    font.pointSize: PhyTheme.font.pointSize * 0.55
                                }

                                // Control buttons
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 8
                                    
                                    Button {
                                        id: onBtn
                                        text: "ON"
                                        enabled: canController.initialized && canController.ioModuleOnline
                                        font.pointSize: PhyTheme.font.pointSize * 0.5
                                        
                                        property bool touching: false
                                        
                                        scale: touching ? 0.95 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 100 } }
                                        
                                        background: Rectangle {
                                            implicitWidth: 150
                                            implicitHeight: 38
                                            radius: 6
                                            color: onBtn.touching
                                                ? (onBtn.enabled ? Qt.darker(PhyTheme.teal2, 1.4) : PhyTheme.gray4)
                                                : (onBtn.enabled ? PhyTheme.teal2 : PhyTheme.gray4)
                                            border.color: onBtn.enabled ? PhyTheme.teal1 : PhyTheme.gray3
                                            border.width: 2
                                            
                                            Behavior on color { ColorAnimation { duration: 80 } }
                                        }
                                        
                                        contentItem: Text {
                                            text: parent.text
                                            color: parent.enabled ? PhyTheme.white : PhyTheme.gray2
                                            font.pointSize: PhyTheme.font.pointSize * 0.5
                                            font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        
                                        onPressed: touching = true
                                        onReleased: touching = false
                                        onCanceled: touching = false
                                        onClicked: canController.setBinaryOutput(index, true)
                                    }
                                    
                                    Button {
                                        id: offBtn
                                        text: "OFF"
                                        enabled: canController.initialized && canController.ioModuleOnline
                                        font.pointSize: PhyTheme.font.pointSize * 0.5
                                        
                                        property bool touching: false
                                        
                                        scale: touching ? 0.95 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 100 } }
                                        
                                        background: Rectangle {
                                            implicitWidth: 150
                                            implicitHeight: 38
                                            radius: 6
                                            color: offBtn.touching
                                                ? (offBtn.enabled ? Qt.darker(PhyTheme.gray5, 1.4) : PhyTheme.gray4)
                                                : (offBtn.enabled ? PhyTheme.gray5 : PhyTheme.gray4)
                                            border.color: offBtn.enabled ? PhyTheme.gray3 : PhyTheme.gray3
                                            border.width: 2
                                            
                                            Behavior on color { ColorAnimation { duration: 80 } }
                                        }
                                        
                                        contentItem: Text {
                                            text: parent.text
                                            color: parent.enabled ? PhyTheme.white : PhyTheme.gray2
                                            font.pointSize: PhyTheme.font.pointSize * 0.5
                                            font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        
                                        onPressed: touching = true
                                        onReleased: touching = false
                                        onCanceled: touching = false
                                        onClicked: canController.setBinaryOutput(index, false)
                                    }
                                }

                                // Status indicator
                                RowLayout {
                                    Layout.preferredWidth: 60
                                    Layout.alignment: Qt.AlignRight
                                    spacing: 6
                                    
                                    Rectangle {
                                        width: 12
                                        height: 12
                                        radius: 6
                                        color: canController.outputStates[index] && canController.outputStates[index].actual
                                            ? PhyTheme.teal1
                                            : PhyTheme.gray4
                                    }
                                    
                                    Label {
                                        text: canController.outputStates[index] && canController.outputStates[index].actual
                                            ? "ON"
                                            : "OFF"
                                        color: canController.outputStates[index] && canController.outputStates[index].actual
                                            ? PhyTheme.teal1
                                            : PhyTheme.gray3
                                        font.pointSize: PhyTheme.font.pointSize * 0.45
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Warning Message ─────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: warningLabel.implicitHeight + 20
                radius: 6
                color: "#3d1f1f"
                border.color: "#ff6b6b"
                border.width: 1
                visible: !canController.ioModuleOnline

                Label {
                    id: warningLabel
                    anchors.centerIn: parent
                    text: "⚠ IO Module offline - Commands disabled"
                    color: "#ff6b6b"
                    font.pointSize: PhyTheme.font.pointSize * 0.55
                }
            }
        }
    }
}
