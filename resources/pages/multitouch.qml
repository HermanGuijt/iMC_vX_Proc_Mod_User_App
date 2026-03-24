/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2021 PHYTEC Messtechnik GmbH
 */

import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import PhyTheme 1.0
import "../controls"

Page {
    header: PhyToolBar {
        title: "Multitouch"
        buttonBack.onClicked: stack.pop()
        buttonMenu.visible: false
    }

    MultiPointTouchArea {
        id: mt
        anchors.fill: parent

        property int touchPointPressCount: 0
        property int touchPointReleaseCount: 0
        property int touchActiveCount: 0

        touchPoints: [
            TouchPoint { id: touch1 },
            TouchPoint { id: touch2 },
            TouchPoint { id: touch3 },
            TouchPoint { id: touch4 },
            TouchPoint { id: touch5 }
        ]
        property variant offsets: [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]
        property variant points: [ touch1.x, touch1.y,
                                   touch2.x, touch2.y,
                                   touch3.x, touch3.y,
                                   touch4.x, touch4.y,
                                   touch5.x, touch5.y ]
        property variant ap: [ 0, 0 ]

        Component.onCompleted: {
            clearCounts()
        }

        function clearCounts() {
            var cx = width / 2
            var outy = height / 2
            touchPointPressCount = 0
            touchPointReleaseCount = 0
            touchActiveCount = 0
            if (btn_forces.checked) {
                offsets = [ cx, outy,
                            cx - 40, outy,
                            cx - 80, outy,
                            cx + 40, outy,
                            cx + 80, outy ]
            } else {
                offsets = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]
            }
            updateText()
        }

        function updateText() {
            output.text = "Down/Up/Active: " + touchPointPressCount + "/" +
                          touchPointReleaseCount + "/" + touchActiveCount
        }

        onPressed: {
            touchPointPressCount += touchPoints.length
            if (btn_forces.checked)
                forceTimer.running = true
            updateText()
        }
        onReleased: {
            touchPointReleaseCount += touchPoints.length
            updateText()
        }
        onTouchUpdated: {
            touchActiveCount = touchPoints.length
            ap = touchPoints
            if (touchActiveCount === 0) {
                forceTimer.running = false
            }
            updateText()
        }

        Timer {
            id: forceTimer
            interval: 100; running: false; repeat: true
            onTriggered: mt.physics()
        }
        function physics() {
            var dx = 0
            var dy = 0
            var ds = 0
            var a = 0
            var b = 0
            var f = 0
            var i = 0
            var j = 0
            var k = 0

            // In QML Javascript we cannot directly write to the QML properties
            var new_offsets = offsets

            // Calculate weak attraction force
            for (i = 0; i < offsets.length; i += 2) {
                for (j = 0; j < ap.length; j++) {
                    if (j !== (i / 2)) {
                        var tp = ap[j]
                        dx = tp.x - (points[i] + offsets[i])
                        dy = tp.y - (points[i + 1] + offsets[i + 1])
                        ds = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2))
                        // Guard against singularity
                        if (ds === 0) {
                            ds = 0.1
                        }
                        a = Math.sin(dx / ds)
                        b = Math.sin(dy / ds)
                        f = ds * 0.2
                        new_offsets[i] += f * a
                        new_offsets[i + 1] += f * b
                    }
                }
            }

            // Calculate strong repellent force. It acts symmetrically between points
            for (i = 0; i < offsets.length; i += 2) {
                for (j = 0; j < offsets.length; j += 2) {
                    if (j !== i) {
                        dx = (points[j] + offsets[j]) - (points[i] + offsets[i])
                        dy = (points[j + 1] + offsets[j + 1]) - (points[i + 1] + offsets[i + 1])
                        ds = Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2))
                        // Guard against singularity
                        if (ds === 0) {
                            ds = 0.1
                        }
                        a = Math.sin(dx / ds)
                        b = Math.sin(dy / ds)
                        f = 1000 / ds
                        new_offsets[i] -= f * a
                        new_offsets[i + 1] -= f * b
                        new_offsets[j] += f * a
                        new_offsets[j + 1] += f * b
                    }
                }
            }
            // touchPoints have no offset
            for (i = 0; i < ap.length; i++) {
                new_offsets[i * 2] = 0
                new_offsets[i * 2 + 1] = 0
            }
            offsets = new_offsets
        }
    }

    RowLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 20
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        height: parent.height / 14

        Button {
            id: btn_reset
            text: "Reset"
            onClicked: mt.clearCounts()
        }
        CheckBox {
            id: btn_forces
            text: "Forces"
            checked: true
            onClicked: mt.clearCounts()
        }
        Item {
            Layout.fillWidth: true
        }
        Label {
            id: output
            text: "Down/Up/Active: 0/0/0"
        }
    }

    Rectangle {
        width: font.pixelSize * 2
        height: width
        color: PhyTheme.blue
        border.width: 2
        border.color: "black"
        x: touch1.x - width / 2 + mt.offsets[0]
        y: touch1.y - width / 2 + mt.offsets[1]
        radius: width * 0.5
        Behavior on x { SpringAnimation { spring: 3; damping: 0.3; mass: 1.0 } }
        Behavior on y { SpringAnimation { spring: 3; damping: 0.3; mass: 1.0 } }
    }
    Rectangle {
        width: font.pixelSize * 2
        height: width
        color: PhyTheme.green
        border.width: 2
        border.color: "black"
        x: touch2.x - width / 2 + mt.offsets[2]
        y: touch2.y - width / 2 + mt.offsets[3]
        radius: width * 0.5
        Behavior on x { SpringAnimation { spring: 3; damping: 0.3; mass: 1.0 } }
        Behavior on y { SpringAnimation { spring: 3; damping: 0.3; mass: 1.0 } }
    }
    Rectangle {
        width: font.pixelSize * 2
        height: width
        color: PhyTheme.orange
        border.width: 2
        border.color: "black"
        x: touch3.x - width / 2 + mt.offsets[4]
        y: touch3.y - width / 2 + mt.offsets[5]
        radius: width * 0.5
        Behavior on x { SpringAnimation { spring: 3; damping: 0.3; mass: 1.0 } }
        Behavior on y { SpringAnimation { spring: 3; damping: 0.3; mass: 1.0 } }
    }
    Rectangle {
        width: font.pixelSize * 2
        height: width
        color: PhyTheme.yellow
        border.width: 2
        border.color: "black"
        x: touch4.x - width / 2 + mt.offsets[6]
        y: touch4.y - width / 2 + mt.offsets[7]
        radius: width * 0.5
        Behavior on x { SpringAnimation { spring: 3; damping: 0.3; mass: 1.0 } }
        Behavior on y { SpringAnimation { spring: 3; damping: 0.3; mass: 1.0 } }
    }
    Rectangle {
        width: font.pixelSize * 2
        height: width
        color: PhyTheme.teal
        border.width: 2
        border.color: "black"
        x: touch5.x - width / 2 + mt.offsets[8]
        y: touch5.y - width / 2 + mt.offsets[9]
        radius: width * 0.5
        Behavior on x { SpringAnimation { spring: 3; damping: 0.3; mass: 1.0 } }
        Behavior on y { SpringAnimation { spring: 3; damping: 0.3; mass: 1.0 } }
    }
}
