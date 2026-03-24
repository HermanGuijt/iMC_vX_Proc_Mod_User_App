/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2021 PHYTEC Messtechnik GmbH
 */

import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import Phytec.DeviceInfo 1.0
import PhyTheme 1.0
import "../controls"

Page {
    header: PhyToolBar {
        title: "Device Information"
        buttonBack.onClicked: stack.pop()
        buttonMenu.visible: false
    }

    ColumnLayout {
        anchors.fill: parent

        GridLayout {
            columns: 2
            columnSpacing: PhyTheme.marginBig
            rowSpacing: 0
            Layout.margins: PhyTheme.marginRegular
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop | Qt.AlignLeft

            Row {
                spacing: PhyTheme.marginRegular
                Label {
                    text: "  " + PhyTheme.iconFont.code + "  "
                    font.family: icons.font.family
                    color: PhyTheme.white
                    background: Rectangle { color: PhyTheme.teal2 }
                }
                Label { text: "<h3>Software</h3>" }
            }
            Label {}
            Label { text: "Board Description"; color: PhyTheme.gray3 }
            Label { text: DeviceInfo.boardDescription }
            Label { text: "Machine"; color: PhyTheme.gray3 }
            Label { text: DeviceInfo.machine }
            Label { text: "Distribution"; color: PhyTheme.gray3 }
            Label { text: DeviceInfo.distribution }
            Label { text: "Release"; color: PhyTheme.gray3 }
            Label { text: DeviceInfo.release }
            Label { text: "Codename"; color: PhyTheme.gray3 }
            Label { text: DeviceInfo.codename }
            Label { text: "Kernel"; color: PhyTheme.gray3 }
            Label { text: DeviceInfo.kernelRelease }
            Row {
                Layout.topMargin: 2 * PhyTheme.marginBig
                spacing: PhyTheme.marginRegular
                Label {
                    text: "  " + PhyTheme.iconFont.cpu + "  "
                    font.family: icons.font.family
                    color: PhyTheme.white
                    background: Rectangle { color: PhyTheme.teal2 }
                }
                Label { text: "<h3>Hardware</h3>" }
            }
            Label {}
            Label { text: "CPU"; color: PhyTheme.gray3 }
            Label { text: DeviceInfo.cpuModelName }
            Label { text: "RAM"; color: PhyTheme.gray3 }
            Label { text: DeviceInfo.ram }
            Label { text: "Architecture"; color: PhyTheme.gray3 }
            Label { text: DeviceInfo.architecture }
        }
    }
}
