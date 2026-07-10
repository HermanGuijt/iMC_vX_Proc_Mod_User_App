/*
 * SPDX-License-Identifier: MIT
 * Restyled for HB Watertechnologie (HBWT) — www.EmbedTech.nl
 */

import QtQuick 2.6
import QtQuick.Controls 2.9
import QtQuick.Layouts 1.0
import PhyTheme 1.0
import "../controls"

Page {
    background: Rectangle { color: PhyTheme.bgDark }

    // Local font loader — pages are loaded in their own QML scope
    FontLoader {
        id: localIcons
        source: "qrc:///fonts/MaterialIcons-Regular.ttf"
    }

    header: PhyToolBar {
        title: "Over HBWT"
        buttonBack.onClicked: stack.pop()
        buttonMenu.visible: false
    }

    // Dark fill behind Flickable
    Rectangle {
        anchors.fill: parent
        color: PhyTheme.bgDark
    }

    Flickable {
        id: scrollView
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.height + PhyTheme.marginBig * 2
        clip: true

        Column {
            id: col
            x: PhyTheme.marginBig
            y: PhyTheme.marginBig
            width: scrollView.width - PhyTheme.marginBig * 2
            spacing: PhyTheme.marginRegular

            // ── Header block ──────────────────────────────────────
            Rectangle {
                width: parent.width
                height: 70
                radius: 10
                color: PhyTheme.teal3

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Label {
                        text: "HB Watertechnologie"
                        color: PhyTheme.white
                        font.bold: true
                        font.pointSize: PhyTheme.font.pointSize * 0.75
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Label {
                        text: "Specialist in watertechnische activiteiten  ·  www.hbwt.nl"
                        color: PhyTheme.gray2
                        font.pointSize: PhyTheme.font.pointSize * 0.42
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // ── About text ────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: aboutLabel.implicitHeight + PhyTheme.marginBig
                radius: 10
                color: PhyTheme.cardDark

                Label {
                    id: aboutLabel
                    anchors {
                        top: parent.top; left: parent.left; right: parent.right
                        margins: PhyTheme.marginRegular
                    }
                    wrapMode: Text.WordWrap
                    color: PhyTheme.gray1
                    font.pointSize: PhyTheme.font.pointSize * 0.46
                    text: "<b>HB Watertechnologie</b> is een familiebedrijf gespecialiseerd in "
                        + "watertechnische activiteiten voor hoogwaardig groen en waterpartijen.<br><br>"
                        + "Onze activiteiten omvatten irrigatiesystemen en beregeningsinstallaties voor "
                        + "daktuinen, verticale tuinen, binnentuinen, plantenbakken en andere hoogwaardige "
                        + "groenprojecten.<br><br>"
                        + "Wij verzorgen ook waterretentiemanagement, hemelwateropvang- en hergebruiksystemen, "
                        + "waterbehandelingen, filtersystemen en andere watertechnische oplossingen."
                }
            }

            // ── Three strengths ───────────────────────────────────
            Row {
                width: parent.width
                spacing: PhyTheme.marginSmall

                Repeater {
                    model: [
                        { lbl: "Groen",   sub: "Dak & gevel",   icon: "\ue91c" },
                        { lbl: "Water",   sub: "Slim beheer",    icon: "\ue798" },
                        { lbl: "Service", sub: "Nazorg & beheer",icon: "\ue8b8" }
                    ]

                    Rectangle {
                        width: (parent.width - 2 * PhyTheme.marginSmall) / 3
                        height: 72
                        radius: 8
                        color: PhyTheme.cardDark

                        Column {
                            anchors.centerIn: parent
                            spacing: 3

                            Label {
                                text: modelData.icon
                                font.family: localIcons.font.family
                                font.pointSize: PhyTheme.font.pointSize * 1.1
                                color: PhyTheme.teal1
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Label {
                                text: modelData.lbl
                                color: PhyTheme.white
                                font.bold: true
                                font.pointSize: PhyTheme.font.pointSize * 0.44
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Label {
                                text: modelData.sub
                                color: PhyTheme.gray3
                                font.pointSize: PhyTheme.font.pointSize * 0.36
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }

            // ── Contact ───────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: 62
                radius: 10
                color: PhyTheme.cardDark

                Row {
                    anchors.centerIn: parent
                    spacing: 40

                    Column {
                        spacing: 3
                        Label { text: "Adres";               color: PhyTheme.teal1; font.bold: true; font.pointSize: PhyTheme.font.pointSize * 0.42 }
                        Label { text: "Proostwetering 27h";  color: PhyTheme.gray1; font.pointSize: PhyTheme.font.pointSize * 0.42 }
                        Label { text: "3543 AB  Utrecht";    color: PhyTheme.gray1; font.pointSize: PhyTheme.font.pointSize * 0.42 }
                    }
                    Column {
                        spacing: 3
                        Label { text: "Contact";           color: PhyTheme.teal1; font.bold: true; font.pointSize: PhyTheme.font.pointSize * 0.42 }
                        Label { text: "0348 – 44 46 93";   color: PhyTheme.gray1; font.pointSize: PhyTheme.font.pointSize * 0.42 }
                        Label { text: "info@hbwt.nl";      color: PhyTheme.gray1; font.pointSize: PhyTheme.font.pointSize * 0.42 }
                    }
                }
            }
        }
    }
}

