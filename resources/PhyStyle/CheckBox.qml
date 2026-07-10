/*
 * SPDX-License-Identifier: MIT
 * Restyled for HB Watertechnologie (HBWT) — www.EmbedTech.nl
 */

import QtQuick 2.12
import QtQuick.Templates 2.12 as T
import PhyTheme 1.0

T.CheckBox {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    padding: 4
    spacing: 8

    indicator: Rectangle {
        implicitWidth: 22
        implicitHeight: 22
        x: control.text ? (control.mirrored ? control.width - width - control.rightPadding
                                            : control.leftPadding)
                        : control.leftPadding + (control.availableWidth - width) / 2
        y: control.topPadding + (control.availableHeight - height) / 2
        radius: 5
        color: control.checked || control.down ? PhyTheme.teal1 : "#1e3328"
        border.color: control.checked || control.down ? PhyTheme.teal1 : PhyTheme.teal3
        border.width: 1

        Text {
            anchors.centerIn: parent
            visible: control.checked || control.partially
            text: "\u2714"
            font.bold: true
            font.pixelSize: 14
            color: PhyTheme.white
        }
    }

    contentItem: Text {
        leftPadding: control.indicator && !control.mirrored ? control.indicator.width + control.spacing : 0
        rightPadding: control.indicator && control.mirrored  ? control.indicator.width + control.spacing : 0
        text: control.text
        font: control.font
        color: control.enabled ? PhyTheme.gray1 : PhyTheme.gray3
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }
}
