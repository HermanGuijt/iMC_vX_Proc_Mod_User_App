/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2021 PHYTEC Messtechnik GmbH
 */

import QtQuick 2.12
import QtQuick.Templates 2.12 as T
import PhyTheme 1.0

T.ToolButton {
    id: control

    implicitWidth: Math.max(background.implicitWidth + leftInset + rightInset,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(background.implicitHeight + topInset + bottomInset,
                             contentItem.implicitHeight + topPadding + bottomPadding)

    padding: 6
    spacing: 6

    background: Rectangle {
        implicitWidth: 40
        implicitHeight: 40
        radius: 6
        visible: !control.flat || control.checked || control.down
        color: (control.checked || control.down) ? PhyTheme.teal1 : PhyTheme.teal3
    }

    contentItem: Text {
        text: control.text
        opacity: enabled ? 1 : 0.5
        color: PhyTheme.white
        font: control.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
