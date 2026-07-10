/*
 * SPDX-License-Identifier: MIT
 * Restyled for HB Watertechnologie (HBWT) — www.EmbedTech.nl
 */

import QtQuick 2.12
import QtQuick.Templates 2.12 as T
import PhyTheme 1.0

T.TextArea {
    id: control

    padding: 8
    leftPadding: 12

    color: PhyTheme.gray1
    selectionColor: PhyTheme.teal1
    selectedTextColor: PhyTheme.white
    placeholderTextColor: PhyTheme.gray3

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 100
        radius: 6
        color: control.enabled ? "#1e3328" : "#162a20"
        border.color: control.activeFocus ? PhyTheme.teal1 : PhyTheme.teal3
        border.width: control.activeFocus ? 2 : 1

        Text {
            x: control.leftPadding
            y: control.topPadding
            width: parent.width - control.leftPadding - control.rightPadding
            text: control.placeholderText
            font: control.font
            color: PhyTheme.gray3
            visible: !control.length && !control.preeditText &&
                     (!control.activeFocus || control.horizontalAlignment !== Qt.AlignHCenter)
        }
    }
}
