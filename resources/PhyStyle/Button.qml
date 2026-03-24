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
        visible: !control.flat || control.checked || control.down
        color: control.checked || control.down ? PhyTheme.black : PhyTheme.gray4
    }

    contentItem: Text {
        text: control.text
        opacity: enabled ? 1 : 0.3
        color: !control.flat ? PhyTheme.white : PhyTheme.black &&
               control.checked || control.down ? PhyTheme.white : PhyTheme.black
        font: PhyTheme.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
