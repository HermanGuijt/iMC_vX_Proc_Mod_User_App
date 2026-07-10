/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2026 HB Watertechnologie — www.EmbedTech.nl
 * 
 * CAN Bus Status and Node Discovery Page
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
            // Initialize CAN interface on page load
            if (!canController.initialized) {
                canController.initCAN("can0", 500000)
            }
        }
        
        onScanComplete: function(nodeCount) {
            scanResultText.text = nodeCount > 0 
                ? `Gevonden: ${nodeCount} node${nodeCount > 1 ? 's' : ''}`
                : "Geen nodes gevonden"
        }
        
        onErrorOccurred: function(error) {
            errorText.text = error
            errorText.visible = true
            errorTimer.start()
        }
    }

    // Hide error message after 5 seconds
    Timer {
        id: errorTimer
        interval: 5000
        onTriggered: errorText.visible = false
    }

    // ── Main Layout ──────────────────────────────────────────────────────────
    ScrollView {
        anchors.fill: parent
        anchors.margins: PhyTheme.marginBig
        clip: true

        ColumnLayout {
            width: parent.width - PhyTheme.marginBig * 2
            spacing: PhyTheme.marginBig

            // ── Status Card ──────────────────────────────────────────────────
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
                        text: "Interface Status"
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

                    // Scan button
                    Button {
                        Layout.alignment: Qt.AlignLeft
                        text: canController.scanning ? "Scanning..." : "Scan CAN Bus"
                        enabled: canController.initialized && !canController.scanning
                        font.pointSize: PhyTheme.font.pointSize * 0.55
                        
                        background: Rectangle {
                            implicitWidth: 180
                            implicitHeight: 44
                            radius: 8
                            color: parent.enabled ? PhyTheme.teal2 : PhyTheme.gray4
                            border.color: parent.enabled ? PhyTheme.teal1 : PhyTheme.gray3
                            border.width: 1
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            color: parent.enabled ? PhyTheme.white : PhyTheme.gray2
                            font: parent.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onClicked: canController.scanBus()
                    }

                    // Scan result
                    Label {
                        id: scanResultText
                        text: ""
                        color: PhyTheme.gray2
                        font.pointSize: PhyTheme.font.pointSize * 0.5
                        visible: text !== ""
                    }
                }
            }

            // ── Discovered Nodes ────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 300
                radius: 10
                color: PhyTheme.cardDark

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: PhyTheme.marginBig
                    spacing: PhyTheme.marginRegular

                    RowLayout {
                        Layout.fillWidth: true
                        
                        Label {
                            text: "Ontdekte Nodes"
                            font.bold: true
                            color: PhyTheme.white
                            font.pointSize: PhyTheme.font.pointSize * 0.72
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Label {
                            text: canController.discoveredCount + " node(s)"
                            color: PhyTheme.teal1
                            font.pointSize: PhyTheme.font.pointSize * 0.6
                            font.bold: true
                        }
                    }

                    // Table header
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: 6
                        color: PhyTheme.teal3

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Label {
                                Layout.preferredWidth: 50
                                text: "ID"
                                color: PhyTheme.white
                                font.bold: true
                                font.pointSize: PhyTheme.font.pointSize * 0.5
                            }
                            Label {
                                Layout.fillWidth: true
                                text: "Type"
                                color: PhyTheme.white
                                font.bold: true
                                font.pointSize: PhyTheme.font.pointSize * 0.5
                            }
                            Label {
                                Layout.preferredWidth: 80
                                text: "Firmware"
                                color: PhyTheme.white
                                font.bold: true
                                font.pointSize: PhyTheme.font.pointSize * 0.5
                            }
                            Label {
                                Layout.preferredWidth: 80
                                text: "Status"
                                color: PhyTheme.white
                                font.bold: true
                                font.pointSize: PhyTheme.font.pointSize * 0.5
                            }
                        }
                    }

                    // Node list
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 6
                        
                        model: canController.nodes
                        
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 50
                            radius: 6
                            color: index % 2 === 0 ? "#1a2a30" : "#152328"
                            border.color: PhyTheme.teal3
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                Label {
                                    Layout.preferredWidth: 50
                                    text: String(modelData.nodeId).padStart(3, '0')
                                    color: PhyTheme.teal1
                                    font.bold: true
                                    font.pointSize: PhyTheme.font.pointSize * 0.55
                                }
                                
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.deviceTypeName
                                    color: PhyTheme.gray1
                                    font.pointSize: PhyTheme.font.pointSize * 0.52
                                    elide: Text.ElideRight
                                }
                                
                                Label {
                                    Layout.preferredWidth: 80
                                    text: modelData.fwVersion
                                    color: PhyTheme.gray2
                                    font.pointSize: PhyTheme.font.pointSize * 0.5
                                }
                                
                                Rectangle {
                                    Layout.preferredWidth: 80
                                    height: 26
                                    radius: 4
                                    color: {
                                        if (modelData.status === 0) return "#1a4d2e"      // OK - dark green
                                        if (modelData.status === 1) return "#4d3a1a"      // Warning - dark orange
                                        if (modelData.status === 2) return "#4d1a1a"      // Error - dark red
                                        return PhyTheme.gray4                              // Unknown - gray
                                    }
                                    border.color: {
                                        if (modelData.status === 0) return PhyTheme.teal1  // OK
                                        if (modelData.status === 1) return "#f39c12"       // Warning
                                        if (modelData.status === 2) return "#e74c3c"       // Error
                                        return PhyTheme.gray3
                                    }
                                    border.width: 1

                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData.statusText
                                        color: parent.border.color
                                        font.pointSize: PhyTheme.font.pointSize * 0.48
                                        font.bold: true
                                    }
                                }
                            }
                        }

                        // Empty state
                        Label {
                            anchors.centerIn: parent
                            visible: canController.discoveredCount === 0
                            text: canController.initialized 
                                ? "Druk op 'Scan CAN Bus' om nodes te detecteren"
                                : "CAN interface niet geïnitialiseerd"
                            color: PhyTheme.gray3
                            font.pointSize: PhyTheme.font.pointSize * 0.55
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }

            // Spacer
            Item { implicitHeight: PhyTheme.marginBig }
        }
    }
}
