/*
 * SPDX-License-Identifier: MIT
 * Restyled for HB Watertechnologie (HBWT) — www.EmbedTech.nl
 */

import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import QtQuick.Window 2.2
import PhyTheme 1.0

ApplicationWindow {
    visible: true
    visibility: Window.FullScreen
    width: 640
    height: 480

    property int itemSize: 0.4 * width

    FontLoader {
        id: icons
        source: "qrc:///fonts/MaterialIcons-Regular.ttf"
    }

    ListModel {
        id: pageModel

        ListElement {
            icon: "\ue871"
            name: "Dashboard"
            description: "Irrigatie zones, bodemvocht en waterverbruik"
            page: "qrc:///pages/dashboard.qml"
        }
        ListElement {
            icon: "\ue1bd"
            name: "Widget Factory"
            description: "Qt bedieningselementen en invoervelden"
            page: "qrc:///pages/widget_factory.qml"
        }
        ListElement {
            icon: "\ue1e8"
            name: "CAN Bus Status"
            description: "CAN bus status en IO Module health"
            page: "qrc:///pages/can_status.qml"
        }
        ListElement {
            icon: "\ue85d"
            name: "Sensor Data"
            description: "Vochtigheid, druk, temperatuur en inputs"
            page: "qrc:///pages/sensor_data.qml"
        }
        ListElement {
            icon: "\ue429"
            name: "Actuator Control"
            description: "Ventiel en output besturing"
            page: "qrc:///pages/actuator_control.qml"
        }
        ListElement {
            icon: "\ue88e"
            name: "About HBWT"
            description: "Over HB Watertechnologie"
            page: "qrc:///pages/about.qml"
        }
    }

    StackView {
        id: stack
        initialItem: mainView
        anchors.fill: parent

        popEnter: Transition {
            YAnimator { from: 0; to: 0; duration: 250; easing.type: Easing.OutCubic }
        }
        popExit: Transition {
            YAnimator { from: 0; to: stack.height; duration: 250; easing.type: Easing.OutCubic }
        }
        pushEnter: Transition {
            YAnimator { from: stack.height; to: 0; duration: 250; easing.type: Easing.OutCubic }
        }
        pushExit: Transition {
            YAnimator { from: 0; to: 0; duration: 250; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        id: mainView

        // Dark green gradient background
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#102518" }
            GradientStop { position: 1.0; color: "#0d1a20" }
        }

        // ── Top brand bar ──────────────────────────────────────────────────
        Rectangle {
            id: brandBar
            width: parent.width
            height: 52
            color: PhyTheme.teal3

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: PhyTheme.marginBig
                anchors.rightMargin: PhyTheme.marginBig
                spacing: PhyTheme.marginRegular

                Label {
                    text: "\ue91c"            // spa / leaf icon
                    font.family: icons.font.family
                    font.pointSize: PhyTheme.font.pointSize * 1.1
                    color: PhyTheme.teal1
                }
                ColumnLayout {
                    spacing: 0
                    Label {
                        text: "HB Watertechnologie"
                        font.bold: true
                        color: PhyTheme.white
                        font.pointSize: PhyTheme.font.pointSize * 0.7
                    }
                    Label {
                        text: "Irrigatie Control System"
                        color: PhyTheme.gray2
                        font.pointSize: PhyTheme.font.pointSize * 0.45
                    }
                }
                Item { Layout.fillWidth: true }
                Label {
                    id: clockLabel
                    color: PhyTheme.gray2
                    font.pointSize: PhyTheme.font.pointSize * 0.5
                    Timer {
                        interval: 10000; running: true; repeat: true
                        onTriggered: clockLabel.text = Qt.formatTime(new Date(), "hh:mm")
                    }
                    Component.onCompleted: text = Qt.formatTime(new Date(), "hh:mm")
                }
            }
        }

        // ── Page cards (PathView) ──────────────────────────────────────────
        Component {
            id: pageDelegate

            Rectangle {
                id: itemRectangle
                color: PhyTheme.cardDark
                radius: 10
                z: PathView.onPath ? PathView.z : 0
                opacity: PathView.onPath ? PathView.pageOpacity : 0
                width: 0.3 * pathView.width
                height: Math.min(0.36 * pathView.width, 0.9 * pathView.height)

                // Subtle green top-border accent
                Rectangle {
                    width: parent.width * 0.6
                    height: 3
                    radius: 2
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: PhyTheme.teal1
                    opacity: parent.PathView.pageOpacity
                }

                function showPage() {
                    if (page) {
                        pageLoader.source = page
                        stack.push(pageLoader)
                    }
                }

                RowLayout {
                    spacing: 0
                    anchors.fill: parent

                    ColumnLayout {
                        spacing: PhyTheme.marginRegular
                        Layout.margins: PhyTheme.marginRegular
                        Layout.fillWidth: true

                        Label {
                            text: icon
                            color: PhyTheme.teal1
                            font.family: icons.font.family
                            font.pointSize: icons.font.pointSize * 3
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Label {
                            text: "<h2>" + name + "</h2>"
                            wrapMode: Text.WordWrap
                            color: PhyTheme.white
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Label {
                            text: description
                            elide: Text.ElideRight
                            wrapMode: Text.WordWrap
                            color: PhyTheme.gray2
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }

        DelegateModel {
            id: displayDelegateModel
            delegate: pageDelegate
            model: pageModel

            groups: [
                DelegateModelGroup { name: "configured" }
            ]
            filterOnGroup: "configured"
            Component.onCompleted: {
                for (var i = 0; i < pageModel.count; i++) {
                    items.insert(pageModel.get(i), "configured")
                }
            }
        }

        PathView {
            id: pathView
            anchors.top: brandBar.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            model: displayDelegateModel
            pathItemCount: 4
            snapMode: PathView.SnapToItem
            preferredHighlightBegin: 0.5
            preferredHighlightEnd: 0.5

            MouseArea {
                id: mouseAreaShowPage
                x: 0.35 * parent.width
                y: (parent.height - Math.min(0.36 * parent.width, 0.9 * parent.height)) / 2
                width: 0.3 * parent.width
                height: Math.min(0.36 * parent.width, 0.9 * parent.height)
                onClicked: if (!parent.moving) pathView.currentItem.showPage()
            }
            MouseArea {
                x: 0.0325 * parent.width
                y: mouseAreaShowPage.y
                width: mouseAreaShowPage.width
                height: mouseAreaShowPage.height
                onClicked: pathView.currentIndex = pathView.currentIndex - 1
            }
            MouseArea {
                x: 0.6675 * parent.width
                y: mouseAreaShowPage.y
                width: mouseAreaShowPage.width
                height: mouseAreaShowPage.height
                onClicked: pathView.currentIndex = pathView.currentIndex + 1
            }

            path: Path {
                startX: 0
                startY: 0.5 * pathView.height

                PathAttribute { name: "pageOpacity"; value: 0 }
                PathAttribute { name: "z"; value: 0 }

                PathLine { x: 0.1 * pathView.width; y: 0.5 * pathView.height }
                PathPercent { value: 0.29 }
                PathAttribute { name: "pageOpacity"; value: 0.75 }
                PathAttribute { name: "z"; value: 10 }

                PathLine { x: 0.5 * pathView.width; y: 0.5 * pathView.height }
                PathPercent { value: 0.5 }
                PathAttribute { name: "pageOpacity"; value: 1 }
                PathAttribute { name: "z"; value: 20 }

                PathLine { x: 0.9 * pathView.width; y: 0.5 * pathView.height }
                PathPercent { value: 0.71 }
                PathAttribute { name: "pageOpacity"; value: 0.75 }
                PathAttribute { name: "z"; value: 10 }

                PathLine { x: pathView.width; y: 0.5 * pathView.height }
                PathAttribute { name: "pageOpacity"; value: 0 }
                PathAttribute { name: "z"; value: 0 }
            }
        }

        // ── Bottom hint ────────────────────────────────────────────────────
        Label {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 6
            text: "Tik op een kaart om te openen  ·  www.hbwt.nl"
            color: PhyTheme.teal3
            font.pointSize: PhyTheme.font.pointSize * 0.4
        }
    }

    Loader {
        id: pageLoader
        visible: false
    }
}

