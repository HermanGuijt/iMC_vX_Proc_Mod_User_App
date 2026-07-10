/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2021 PHYTEC Messtechnik GmbH
 */

import QtQuick 2.12
import QtQuick.Templates 2.12 as T
import PhyTheme 1.0

T.Button {
    id: control

    implicitWidth: Math.max(background.implicitWidth + leftInset + rightInset,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(background.implicitHeight + topInset + bottomInset,
                             contentItem.implicitHeight + topPadding + bottomPadding)

    padding: 6
    horizontalPadding: padding + 2
    spacing: 6

    background: Rectangle {
        implicitWidth: 100
        implicitHeight: 40
        radius: 6
        visible: !control.flat || control.checked || control.down
        color: {
            if (!control.enabled)             return "#1a3327"
            if (control.flat)                 return "transparent"
            if (control.down || control.checked) return PhyTheme.teal1
            return PhyTheme.teal2
        }
        border.color: control.flat ? PhyTheme.teal1 : "transparent"
        border.width: control.flat ? 1 : 0
    }

    contentItem: Text {
        text: control.text
        opacity: enabled ? 1 : 0.4
        color: (control.flat && control.enabled) ? PhyTheme.teal1 : PhyTheme.white
        font: PhyTheme.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
