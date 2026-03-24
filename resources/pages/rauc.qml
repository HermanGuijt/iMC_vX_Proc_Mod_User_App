/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2021 PHYTEC Messtechnik GmbH
 */

import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import Phytec.Rauc 1.0
import PhyTheme 1.0
import "../controls"

Page {
    header: PhyToolBar {
        title: "RAUC – Update Client"
        buttonBack.onClicked: stack.pop()
        buttonMenu.visible: false
    }

    Rauc {
        id: rauc
        clientConfigPath: raucHawkbitConfigPath

        onPrimaryChanged: {
            activeA.checked = rauc.isActiveSlot("A")
            activeB.checked = rauc.isActiveSlot("B")
        }
    }

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: PhyTheme.marginRegular

            ColumnLayout {
                Label {
                    text: "Target Name"
                    color: PhyTheme.gray3
                    Layout.fillWidth: true
                }
                Label {
                    text: "<h1>" + rauc.targetName + "</h1>"
                    Layout.fillWidth: true
                }
            }
            RowLayout {
                ButtonGroup {
                    id: activeGroup
                }
                Rectangle {
                    width: font.pointSize * 12
                    height: width
                    color: rauc.isBootedSlot("A") ? PhyTheme.teal2 : PhyTheme.gray3
                    RadioButton {
                        id: activeA
                        anchors.left: parent.left
                        anchors.top: parent.top
                        ButtonGroup.group: activeGroup
                        checked: rauc.primary.endsWith("0")
                        enabled: false
                    }
                    Label {
                        anchors.centerIn: parent
                        text: "<h1>A</h1>system0"
                        color: PhyTheme.white
                        horizontalAlignment: Text.AlignHCenter
                    }
                    ProgressBar {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        opacity: rauc.bootSlot.endsWith("1") && rauc.operation != "idle"
                        value: rauc.toPercentage(rauc.progress) / 100
                    }
                }
                Rectangle {
                    width: font.pointSize * 12
                    height: width
                    color: rauc.isBootedSlot("B") ? PhyTheme.teal2 : PhyTheme.gray3
                    RadioButton {
                        id: activeB
                        anchors.left: parent.left
                        anchors.top: parent.top
                        ButtonGroup.group: activeGroup
                        checked: rauc.primary.endsWith("1")
                        enabled: false
                    }
                    Label {
                        anchors.centerIn: parent
                        text: "<h1>B</h1>system1"
                        color: PhyTheme.white
                        horizontalAlignment: Text.AlignHCenter
                    }
                    ProgressBar {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        opacity: rauc.bootSlot.endsWith("0") && rauc.operation != "idle"
                        value: rauc.toPercentage(rauc.progress) / 100
                    }
                }
            }
        }

        RowLayout {
            Layout.margins: PhyTheme.marginRegular

            GridLayout {
                columns: 2
                columnSpacing: PhyTheme.marginBig
                rowSpacing: 0
                Layout.fillWidth: true

                Label { text: "Release Name"; color: PhyTheme.gray3 }
                Label { text: rauc.releaseName }
                Label { text: "Activated Slot"; color: PhyTheme.gray3 }
                Label { text: rauc.primary }
                Label { text: "Booted From"; color: PhyTheme.gray3 }
                Label { text: rauc.bootSlot }
                Label { text: "Compatible Name"; color: PhyTheme.gray3 }
                Label { text: rauc.compatible }
                Label { text: "Operation"; color: PhyTheme.gray3 }
                Label { text: rauc.operation }
                Label { text: "Progress"; color: PhyTheme.gray3 }
                Label { text: rauc.toPercentage(rauc.progress) + "%" }
            }
        }
    }
}
