/*
 * SPDX-License-Identifier: MIT
 * Restyled for HB Watertechnologie (HBWT) — www.EmbedTech.nl
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0
import PhyTheme 1.0
import "../controls"

Page {
    background: Rectangle { color: PhyTheme.bgDark }

    // ── Text field ───────────────────────────────────────────────────────
    component HbwtField: TextField {
        color: PhyTheme.gray1
        placeholderTextColor: PhyTheme.gray3
        selectionColor: PhyTheme.teal1; selectedTextColor: PhyTheme.white
        leftPadding: 12
        background: Rectangle {
            implicitHeight: 44; radius: 6
            color: parent.enabled ? "#1e3328" : "#162a20"
            border.color: parent.activeFocus ? PhyTheme.teal1 : PhyTheme.teal3
            border.width: parent.activeFocus ? 2 : 1
        }
    }

    // ── Text area ────────────────────────────────────────────────────────
    component HbwtArea: TextArea {
        color: PhyTheme.gray1
        placeholderTextColor: PhyTheme.gray3
        selectionColor: PhyTheme.teal1; selectedTextColor: PhyTheme.white
        leftPadding: 12; topPadding: 10
        background: Rectangle {
            implicitHeight: 100; radius: 6
            color: parent.enabled ? "#1e3328" : "#162a20"
            border.color: parent.activeFocus ? PhyTheme.teal1 : PhyTheme.teal3
            border.width: parent.activeFocus ? 2 : 1
        }
    }

    // ── Checkbox ─────────────────────────────────────────────────────────
    component HbwtCheck: CheckBox {
        indicator: Rectangle {
            x: parent.leftPadding
            y: parent.topPadding + (parent.availableHeight - height) / 2
            width: 22; height: 22; radius: 5
            color: parent.checked ? PhyTheme.teal1 : "#1e3328"
            border.color: parent.checked ? PhyTheme.teal1 : PhyTheme.teal3
            border.width: 1
            Text {
                anchors.centerIn: parent; text: "\u2714"
                color: PhyTheme.white; font.bold: true; font.pixelSize: 13
                visible: parent.parent.checked
            }
        }
        contentItem: Text {
            leftPadding: 30; text: parent.text; font: parent.font
            color: parent.enabled ? PhyTheme.gray1 : PhyTheme.gray3
            verticalAlignment: Text.AlignVCenter
        }
    }

    // ── Button ───────────────────────────────────────────────────────────
    component HbwtButton: Button {
        background: Rectangle {
            implicitWidth: 100; implicitHeight: 40; radius: 6
            visible: !parent.flat || parent.checked || parent.down
            color: {
                if (!parent.enabled)               return "#1a3327"
                if (parent.flat)                   return "transparent"
                if (parent.down || parent.checked) return PhyTheme.teal1
                return PhyTheme.teal2
            }
            border.color: parent.flat ? PhyTheme.teal1 : "transparent"
            border.width: parent.flat ? 1 : 0
        }
        contentItem: Text {
            text: parent.text; font: parent.font
            opacity: parent.enabled ? 1 : 0.4
            color: (parent.flat && parent.enabled) ? PhyTheme.teal1 : PhyTheme.white
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    // ── Slider ───────────────────────────────────────────────────────────
    component HbwtSlider: Slider {
        background: Rectangle {
            x: parent.leftPadding; y: parent.topPadding + (parent.availableHeight - height) / 2
            width: parent.availableWidth; height: 4; radius: 2
            color: PhyTheme.teal3
            Rectangle {
                width: parent.parent.visualPosition * parent.width
                height: parent.height; radius: 2; color: PhyTheme.teal1
            }
        }
        handle: Rectangle {
            x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
            y: parent.topPadding + (parent.availableHeight - height) / 2
            width: 22; height: 22; radius: 11
            color: parent.pressed ? PhyTheme.teal1 : PhyTheme.teal2
            border.color: PhyTheme.teal1; border.width: 2
        }
    }

    // ── RangeSlider ──────────────────────────────────────────────────────
    component HbwtRange: RangeSlider {
        background: Rectangle {
            x: parent.leftPadding; y: parent.topPadding + (parent.availableHeight - height) / 2
            width: parent.availableWidth; height: 4; radius: 2
            color: PhyTheme.teal3
            Rectangle {
                x: parent.parent.first.visualPosition * parent.width
                width: parent.parent.second.visualPosition * parent.width - x
                height: parent.height; radius: 2; color: PhyTheme.teal1
            }
        }
        first.handle: Rectangle {
            x: parent.leftPadding + parent.first.visualPosition * (parent.availableWidth - width)
            y: parent.topPadding + (parent.availableHeight - height) / 2
            width: 22; height: 22; radius: 11
            color: parent.first.pressed ? PhyTheme.teal1 : PhyTheme.teal2
            border.color: PhyTheme.teal1; border.width: 2
        }
        second.handle: Rectangle {
            x: parent.leftPadding + parent.second.visualPosition * (parent.availableWidth - width)
            y: parent.topPadding + (parent.availableHeight - height) / 2
            width: 22; height: 22; radius: 11
            color: parent.second.pressed ? PhyTheme.teal1 : PhyTheme.teal2
            border.color: PhyTheme.teal1; border.width: 2
        }
    }

    // ── ProgressBar ──────────────────────────────────────────────────────
    component HbwtProgress: ProgressBar {
        background: Rectangle {
            implicitWidth: 200; implicitHeight: 8; radius: 4; color: PhyTheme.teal3
        }
        contentItem: Item {
            Rectangle {
                width: parent.parent.indeterminate
                       ? parent.width * 0.35
                       : parent.parent.visualPosition * parent.width
                height: parent.height; radius: 4; color: PhyTheme.teal1
                NumberAnimation on x {
                    running: parent.parent.parent.indeterminate
                    from: -parent.width; to: parent.parent.width
                    duration: 1200; loops: Animation.Infinite
                }
            }
        }
    }

    // ── ComboBox ─────────────────────────────────────────────────────────
    component HbwtCombo: ComboBox {
        background: Rectangle {
            implicitHeight: 44; radius: 6
            color: parent.pressed ? "#243b2e" : "#1e3328"
            border.color: parent.activeFocus ? PhyTheme.teal1 : PhyTheme.teal3
            border.width: parent.activeFocus ? 2 : 1
        }
        contentItem: Text {
            leftPadding: 12; rightPadding: 30; text: parent.displayText; font: parent.font
            color: PhyTheme.gray1; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight
        }
        indicator: Text {
            x: parent.width - width - 10
            y: (parent.height - implicitHeight) / 2
            text: "\u25be"; color: PhyTheme.teal1
            font.pixelSize: 14; font.bold: true
        }
        delegate: ItemDelegate {
            width: parent.width
            contentItem: Text {
                text: modelData; font: parent.font
                color: PhyTheme.gray1; verticalAlignment: Text.AlignVCenter
                leftPadding: 12
            }
            background: Rectangle {
                color: parent.highlighted ? PhyTheme.teal3 : "#1e3328"
            }
        }
        popup: Popup {
            y: parent.height + 2; width: parent.width
            padding: 0
            contentItem: ListView {
                clip: true; model: parent.parent.delegateModel
                implicitHeight: contentHeight
            }
            background: Rectangle {
                color: "#1e3328"; radius: 6
                border.color: PhyTheme.teal3; border.width: 1
            }
        }
    }

    // ── SpinBox ──────────────────────────────────────────────────────────
    component HbwtSpin: SpinBox {
        background: Rectangle {
            implicitHeight: 44; radius: 6
            color: "#1e3328"
            border.color: parent.activeFocus ? PhyTheme.teal1 : PhyTheme.teal3
            border.width: parent.activeFocus ? 2 : 1
        }
        contentItem: TextInput {
            z: 2; text: parent.textFromValue(parent.value, parent.locale)
            font: parent.font; color: PhyTheme.gray1
            selectionColor: PhyTheme.teal1; selectedTextColor: PhyTheme.white
            horizontalAlignment: Qt.AlignHCenter; verticalAlignment: Qt.AlignVCenter
            readOnly: !parent.editable; validator: parent.validator
            inputMethodHints: Qt.ImhFormattedNumbersOnly
        }
        up.indicator: Rectangle {
            x: parent.width - width; height: parent.height; implicitWidth: 40
            radius: 6; color: parent.up.pressed ? PhyTheme.teal1 : "#243b2e"
            border.color: PhyTheme.teal3; border.width: 1
            Text {
                text: "+"; font.bold: true; color: PhyTheme.teal1
                anchors.centerIn: parent; font.pixelSize: 18
            }
        }
        down.indicator: Rectangle {
            x: 0; height: parent.height; implicitWidth: 40
            radius: 6; color: parent.down.pressed ? PhyTheme.teal1 : "#243b2e"
            border.color: PhyTheme.teal3; border.width: 1
            Text {
                text: "\u2212"; font.bold: true; color: PhyTheme.teal1
                anchors.centerIn: parent; font.pixelSize: 18
            }
        }
    }

    header: PhyToolBar {
        title: "Widget Factory"
        buttonBack.onClicked: stack.pop()
    }

    ScrollView {
        id: sv
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        Column {
            id: mainCol
            width: sv.availableWidth
            spacing: PhyTheme.marginRegular
            topPadding:    PhyTheme.marginBig
            bottomPadding: PhyTheme.marginBig

            // helper: sectie label + horizontale lijn
            function sW() { return sv.availableWidth - 2 * PhyTheme.marginBig }

            // ── Invoervelden ──────────────────────────────────────────
            Label { x: PhyTheme.marginBig; text: "Invoervelden"
                    color: PhyTheme.teal1; font.bold: true; font.pointSize: 8 }
            Rectangle { x: PhyTheme.marginBig; width: mainCol.sW(); height: 1; color: PhyTheme.teal3 }

            HbwtField { x: PhyTheme.marginBig; width: mainCol.sW(); placeholderText: "Regulier tekstveld" }
            HbwtField { x: PhyTheme.marginBig; width: mainCol.sW(); placeholderText: "Uitgeschakeld"; enabled: false }
            HbwtField { x: PhyTheme.marginBig; width: mainCol.sW(); placeholderText: "Wachtwoord"
                        echoMode: TextInput.Password
                        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhPreferLowercase | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText }
            HbwtField { x: PhyTheme.marginBig; width: mainCol.sW(); placeholderText: "Hoofdletters"; inputMethodHints: Qt.ImhUppercaseOnly }
            HbwtField { x: PhyTheme.marginBig; width: mainCol.sW(); placeholderText: "Kleine letters"; inputMethodHints: Qt.ImhLowercaseOnly }
            HbwtField { x: PhyTheme.marginBig; width: mainCol.sW(); placeholderText: "Telefoonnummer"; inputMethodHints: Qt.ImhDialableCharactersOnly }
            HbwtField { x: PhyTheme.marginBig; width: mainCol.sW(); placeholderText: "Getal (opgemaakt)"; inputMethodHints: Qt.ImhFormattedNumbersOnly }
            HbwtField { x: PhyTheme.marginBig; width: mainCol.sW(); placeholderText: "Alleen cijfers"; inputMethodHints: Qt.ImhDigitsOnly }

            // ── Knoppen ───────────────────────────────────────────────
            Item { width: 1; height: PhyTheme.marginSmall }
            Label { x: PhyTheme.marginBig; text: "Knoppen"
                    color: PhyTheme.teal1; font.bold: true; font.pointSize: 8 }
            Rectangle { x: PhyTheme.marginBig; width: mainCol.sW(); height: 1; color: PhyTheme.teal3 }

            Row {
                x: PhyTheme.marginBig
                spacing: PhyTheme.marginSmall
                HbwtButton { text: "Aanmaken" }
                HbwtButton { text: "Plat"; flat: true }
                HbwtButton { text: "Actie" }
            }

            // ── Irrigatiezones ────────────────────────────────────────
            Item { width: 1; height: PhyTheme.marginSmall }
            Label { x: PhyTheme.marginBig; text: "Irrigatiezones"
                    color: PhyTheme.teal1; font.bold: true; font.pointSize: 8 }
            Rectangle { x: PhyTheme.marginBig; width: mainCol.sW(); height: 1; color: PhyTheme.teal3 }

            HbwtCheck { x: PhyTheme.marginBig; text: "Zone 1 \u2013 Daktuin";       checked: true  }
            HbwtCheck { x: PhyTheme.marginBig; text: "Zone 2 \u2013 Voortuin";      checked: false }
            HbwtCheck { x: PhyTheme.marginBig; text: "Zone 3 \u2013 Gevel Noord";   checked: true  }
            HbwtCheck { x: PhyTheme.marginBig; text: "Zone 4 \u2013 Plantenbakken"; checked: false }

            // ── Schuifregelaars & voortgang ───────────────────────────
            Item { width: 1; height: PhyTheme.marginSmall }
            Label { x: PhyTheme.marginBig; text: "Schuifregelaars & voortgang"
                    color: PhyTheme.teal1; font.bold: true; font.pointSize: 8 }
            Rectangle { x: PhyTheme.marginBig; width: mainCol.sW(); height: 1; color: PhyTheme.teal3 }

            HbwtSlider   { id: slider; x: PhyTheme.marginBig; width: mainCol.sW(); value: 0.5 }
            HbwtRange    { x: PhyTheme.marginBig; width: mainCol.sW(); first.value: 0.2; second.value: 0.7 }
            HbwtProgress { x: PhyTheme.marginBig; width: mainCol.sW(); value: slider.value }
            HbwtProgress { x: PhyTheme.marginBig; width: mainCol.sW(); indeterminate: true }

            // ── Selectie & invoer ─────────────────────────────────────
            Item { width: 1; height: PhyTheme.marginSmall }
            Label { x: PhyTheme.marginBig; text: "Selectie & invoer"
                    color: PhyTheme.teal1; font.bold: true; font.pointSize: 8 }
            Rectangle { x: PhyTheme.marginBig; width: mainCol.sW(); height: 1; color: PhyTheme.teal3 }

            HbwtCombo {
                x: PhyTheme.marginBig; width: mainCol.sW()
                model: ["Irrigatie schema A", "Irrigatie schema B", "Druppel systeem", "Micro-sproei", "Vol sproei"]
            }
            HbwtCombo {
                x: PhyTheme.marginBig; width: mainCol.sW()
                model: ["Buiten seizoen", "Lente", "Zomer", "Herfst"]
                editable: true
            }
            HbwtSpin { x: PhyTheme.marginBig; width: mainCol.sW(); value: 42 }
            HbwtArea {
                x: PhyTheme.marginBig; width: mainCol.sW()
                height: 120
                placeholderText: "Opmerkingen / notities"
            }

            Item { width: 1; height: PhyTheme.marginBig }
        }
    }
}
