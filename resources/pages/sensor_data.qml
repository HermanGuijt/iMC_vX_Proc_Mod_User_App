/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2026 HB Watertechnologie — www.EmbedTech.nl
 * 
 * Sensor Data Display Page
 * Per CAN_Interface_Proc.md Section 9.2
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0
import PhyTheme 1.0
import "../controls"
import HBWT.CAN 1.0

Page {
    id: sensorPage
    background: Rectangle { color: PhyTheme.bgDark }

    header: PhyToolBar {
        title: "Sensor Data"
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
    }

    // ── Main Layout ──────────────────────────────────────────────────────────
    ScrollView {
        anchors.fill: parent
        anchors.margins: PhyTheme.marginBig
        clip: true

        ColumnLayout {
            width: parent.width - PhyTheme.marginBig * 2
            spacing: PhyTheme.marginBig

            // ── Moisture Sensors (8 stuks) ──────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: moistureCol.implicitHeight + PhyTheme.marginBig * 2
                radius: 10
                color: PhyTheme.cardDark

                ColumnLayout {
                    id: moistureCol
                    anchors.fill: parent
                    anchors.margins: PhyTheme.marginBig
                    spacing: PhyTheme.marginRegular

                    RowLayout {
                        Layout.fillWidth: true
                        
                        Label {
                            text: "Moisture Sensors (8×)"
                            font.bold: true
                            color: PhyTheme.white
                            font.pointSize: PhyTheme.font.pointSize * 0.72
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Rectangle {
                            width: 12; height: 12
                            radius: 6
                            color: canController.sensorDataValid ? PhyTheme.teal1 : PhyTheme.gray4
                            
                            SequentialAnimation on opacity {
                                running: canController.sensorDataValid
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 0.3; duration: 800 }
                                NumberAnimation { from: 0.3; to: 1.0; duration: 800 }
                            }
                        }
                    }

                    // 8 moisture sensors in 2 rows of 4
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 4
                        columnSpacing: PhyTheme.marginRegular
                        rowSpacing: PhyTheme.marginRegular

                        Repeater {
                            model: 8
                            
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 60
                                radius: 6
                                color: PhyTheme.bgDarker
                                
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 4
                                    
                                    Label {
                                        text: "Moisture " + index
                                        color: PhyTheme.gray2
                                        font.pointSize: PhyTheme.font.pointSize * 0.5
                                    }
                                    
                                    Label {
                                        text: canController.moistureSensors[index] 
                                            ? canController.moistureSensors[index].toFixed(1) + " %"
                                            : "---"
                                        color: canController.sensorDataValid 
                                            ? PhyTheme.white 
                                            : PhyTheme.gray3
                                        font.pointSize: PhyTheme.font.pointSize * 0.65
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }

                    Label {
                        text: "Last update: " + canController.sensorDataTimestamp
                        color: PhyTheme.gray2
                        font.pointSize: PhyTheme.font.pointSize * 0.45
                    }
                }
            }

            // ── Pressure Sensors (3 stuks) ──────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: pressureCol.implicitHeight + PhyTheme.marginBig * 2
                radius: 10
                color: PhyTheme.cardDark

                ColumnLayout {
                    id: pressureCol
                    anchors.fill: parent
                    anchors.margins: PhyTheme.marginBig
                    spacing: PhyTheme.marginRegular

                    Label {
                        text: "Pressure Sensors (3×)"
                        font.bold: true
                        color: PhyTheme.white
                        font.pointSize: PhyTheme.font.pointSize * 0.72
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: PhyTheme.marginRegular

                        Repeater {
                            model: 3
                            
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 80
                                radius: 6
                                color: PhyTheme.bgDarker
                                
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 6
                                    
                                    Label {
                                        text: "Pressure " + index
                                        color: PhyTheme.gray2
                                        font.pointSize: PhyTheme.font.pointSize * 0.5
                                    }
                                    
                                    Label {
                                        text: canController.pressureSensors[index]
                                            ? canController.pressureSensors[index].toFixed(1) + " mbar"
                                            : "---"
                                        color: canController.sensorDataValid 
                                            ? PhyTheme.teal1 
                                            : PhyTheme.gray3
                                        font.pointSize: PhyTheme.font.pointSize * 0.7
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }

                    Label {
                        text: "Last update: " + canController.sensorDataTimestamp
                        color: PhyTheme.gray2
                        font.pointSize: PhyTheme.font.pointSize * 0.45
                    }
                }
            }

            // ── Temperature Sensor (1 stuk) ─────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: tempCol.implicitHeight + PhyTheme.marginBig * 2
                radius: 10
                color: PhyTheme.cardDark

                ColumnLayout {
                    id: tempCol
                    anchors.fill: parent
                    anchors.margins: PhyTheme.marginBig
                    spacing: PhyTheme.marginRegular

                    Label {
                        text: "Temperature Sensor"
                        font.bold: true
                        color: PhyTheme.white
                        font.pointSize: PhyTheme.font.pointSize * 0.72
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 100
                        radius: 6
                        color: PhyTheme.bgDarker
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            
                            Label {
                                text: canController.temperatureSensor
                                    ? canController.temperatureSensor.toFixed(1) + " °C"
                                    : "---"
                                Layout.alignment: Qt.AlignHCenter
                                color: canController.sensorDataValid 
                                    ? PhyTheme.orange 
                                    : PhyTheme.gray3
                                font.pointSize: PhyTheme.font.pointSize * 1.0
                                font.bold: true
                            }
                            
                            Label {
                                text: "Last update: " + canController.sensorDataTimestamp
                                Layout.alignment: Qt.AlignHCenter
                                color: PhyTheme.gray2
                                font.pointSize: PhyTheme.font.pointSize * 0.45
                            }
                        }
                    }
                }
            }

            // ── Binary Inputs (3 stuks) ─────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: binCol.implicitHeight + PhyTheme.marginBig * 2
                radius: 10
                color: PhyTheme.cardDark

                ColumnLayout {
                    id: binCol
                    anchors.fill: parent
                    anchors.margins: PhyTheme.marginBig
                    spacing: PhyTheme.marginRegular

                    Label {
                        text: "Binary Inputs (3×)"
                        font.bold: true
                        color: PhyTheme.white
                        font.pointSize: PhyTheme.font.pointSize * 0.72
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: PhyTheme.marginBig

                        Repeater {
                            model: 3
                            
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 70
                                radius: 6
                                color: PhyTheme.bgDarker
                                
                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    
                                    Label {
                                        text: "Input " + index
                                        Layout.alignment: Qt.AlignHCenter
                                        color: PhyTheme.gray2
                                        font.pointSize: PhyTheme.font.pointSize * 0.5
                                    }
                                    
                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 10
                                        Layout.alignment: Qt.AlignHCenter
                                        color: canController.binaryInputs[index] 
                                            ? PhyTheme.teal1 
                                            : PhyTheme.gray4
                                        border.color: canController.binaryInputs[index]
                                            ? PhyTheme.teal2
                                            : PhyTheme.gray3
                                        border.width: 2
                                    }
                                    
                                    Label {
                                        text: canController.binaryInputs[index] ? "HIGH" : "LOW"
                                        Layout.alignment: Qt.AlignHCenter
                                        color: canController.binaryInputs[index]
                                            ? PhyTheme.teal1
                                            : PhyTheme.gray3
                                        font.pointSize: PhyTheme.font.pointSize * 0.5
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }

                    Label {
                        text: "Last update: " + canController.sensorDataTimestamp
                        color: PhyTheme.gray2
                        font.pointSize: PhyTheme.font.pointSize * 0.45
                    }
                }
            }

            // ── Data Validity Warning ───────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: warningLabel.implicitHeight + 20
                radius: 6
                color: "#3d1f1f"
                border.color: "#ff6b6b"
                border.width: 1
                visible: !canController.sensorDataValid

                Label {
                    id: warningLabel
                    anchors.centerIn: parent
                    text: "⚠ Sensor data is stale or not received"
                    color: "#ff6b6b"
                    font.pointSize: PhyTheme.font.pointSize * 0.55
                }
            }
        }
    }
}
