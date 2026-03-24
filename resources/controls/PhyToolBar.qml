/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2021 PHYTEC Messtechnik GmbH
 */

import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import PhyTheme 1.0

ToolBar {
    property string title: ""
    property string subTitle: ""
    property alias buttonBack: buttonBack
    property alias buttonMenu: buttonMenu

    RowLayout {
        anchors.fill: parent

        ToolButton {
            id: buttonBack
            text: PhyTheme.iconFont.arrowLeft
            font.family: icons.font.family
            flat: true
            leftPadding: PhyTheme.marginBig
            rightPadding: PhyTheme.marginBig
            topPadding: PhyTheme.marginRegular
            bottomPadding: PhyTheme.marginRegular
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter

            Label {
                text: "<b>" + title + "</b>"
                elide: Text.ElideRight
                Layout.alignment: Qt.AlignHCenter
            }
            Label {
                text: subTitle
                color: PhyTheme.gray4
                visible: text !== ""
                elide: Text.ElideLeft
                scale: 0.8
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
            }
        }
        ToolButton {
            id: buttonMenu
            Layout.fillWidth: false
            text: PhyTheme.iconFont.list
            font.family: icons.font.family
            flat: true
            visible: false
            leftPadding: PhyTheme.marginBig
            rightPadding: PhyTheme.marginBig
            topPadding: PhyTheme.marginRegular
            bottomPadding: PhyTheme.marginRegular
        }
    }
}
