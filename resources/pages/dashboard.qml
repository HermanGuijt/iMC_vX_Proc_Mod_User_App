/*
 * SPDX-License-Identifier: MIT
 * HBWT Irrigatie Control Dashboard — www.EmbedTech.nl
 */

import QtQuick 2.15
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import PhyTheme 1.0
import "../controls"

Page {
    id: dashPage
    background: Rectangle { color: PhyTheme.bgDark }

    header: PhyToolBar {
        title: "Irrigatie Dashboard"
        buttonBack.onClicked: stack.pop()
        buttonMenu.visible: false
    }

    // ── Simulated live data ──────────────────────────────────────────────────
    property var zoneData: [
        { name: "Zone 1", label: "Daktuin",     moisture: 68, active: true,  litres: 42 },
        { name: "Zone 2", label: "Voortuin",    moisture: 45, active: false, litres: 28 },
        { name: "Zone 3", label: "Gevel N",     moisture: 72, active: false, litres: 15 },
        { name: "Zone 4", label: "Gevel Z",     moisture: 38, active: true,  litres: 33 },
        { name: "Zone 5", label: "Plantenbak",  moisture: 81, active: false, litres: 10 },
        { name: "Zone 6", label: "Vijver",      moisture: 92, active: false, litres: 0  }
    ]

    // 24 soil-moisture readings per zone (simplified — 2-hourly)
    property var moistureHistory: [
        [60,62,65,68,70,72,69,66,64,62,65,68],   // Zone 1
        [40,42,44,46,48,45,43,41,42,44,46,45],   // Zone 2
        [70,72,74,73,72,71,70,69,71,72,73,72],   // Zone 3
        [35,36,37,38,38,39,38,37,36,37,38,38],   // Zone 4
        [78,79,80,81,82,81,80,80,81,82,81,81],   // Zone 5
        [90,91,92,93,92,92,91,90,91,92,93,92]    // Zone 6
    ]

    // Animate the "active" blinking indicator
    Timer {
        id: blinkTimer
        interval: 800; running: true; repeat: true
        onTriggered: blinkState = !blinkState
    }
    property bool blinkState: true

    // ── Layout ───────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: PhyTheme.marginRegular
        spacing: PhyTheme.marginRegular

        // ── Zone status strip ─────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: PhyTheme.marginSmall

            Repeater {
                model: zoneData.length

                Rectangle {
                    property var zone: zoneData[index]
                    property color barColor: zone.moisture >= 70 ? PhyTheme.water
                                           : zone.moisture >= 50 ? PhyTheme.teal1
                                           : zone.moisture >= 35 ? PhyTheme.yellow
                                           : PhyTheme.red

                    Layout.fillWidth: true
                    height: 82
                    radius: 8
                    color: PhyTheme.cardDark

                    // Top moisture bar
                    Rectangle {
                        width: parent.width * (zone.moisture / 100)
                        height: 3
                        radius: 2
                        color: barColor
                        Behavior on width { NumberAnimation { duration: 600 } }
                    }

                    // Active blink dot
                    Rectangle {
                        visible: zone.active
                        width: 8; height: 8; radius: 4
                        color: PhyTheme.teal1
                        opacity: blinkState ? 1.0 : 0.2
                        anchors { top: parent.top; right: parent.right; margins: 5 }
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 3

                        Label {
                            text: zone.moisture + "%"
                            color: barColor
                            font.bold: true
                            font.pointSize: PhyTheme.font.pointSize * 0.65
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Label {
                            text: zone.label
                            color: PhyTheme.gray2
                            font.pointSize: PhyTheme.font.pointSize * 0.38
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Label {
                            text: zone.active ? "● actief" : "○ wacht"
                            color: zone.active ? PhyTheme.teal1 : PhyTheme.gray3
                            font.pointSize: PhyTheme.font.pointSize * 0.35
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
        }

        // ── Soil moisture chart ───────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 150
            radius: 10
            color: PhyTheme.cardDark

            // Chart title
            Label {
                id: chartTitle
                text: "Bodemvochtigheid 24u  (zones 1 – 3)"
                color: PhyTheme.teal1
                font.pointSize: PhyTheme.font.pointSize * 0.42
                anchors { top: parent.top; left: parent.left; margins: PhyTheme.marginSmall + 2 }
            }

            // Y-axis labels
            Column {
                anchors { left: parent.left; top: chartTitle.bottom; bottom: parent.bottom; leftMargin: 4 }
                width: 24
                spacing: 0

                Repeater {
                    model: ["100", "75", "50", "25", "0"]
                    Label {
                        text: modelData
                        color: PhyTheme.gray3
                        font.pointSize: PhyTheme.font.pointSize * 0.3
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        height: (moistureChart.height) / 4
                    }
                }
            }

            Canvas {
                id: moistureChart
                anchors {
                    top: chartTitle.bottom; left: parent.left; right: parent.right; bottom: parent.bottom
                    leftMargin: 32; rightMargin: 8; bottomMargin: 6; topMargin: 4
                }

                property var lineColors: [PhyTheme.teal1, PhyTheme.water, PhyTheme.yellow]
                property var labels: ["Z1 Daktuin", "Z2 Voortuin", "Z3 Gevel N"]

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    var pad = 2
                    var W = width - 2 * pad
                    var H = height - 2 * pad

                    // Grid lines
                    ctx.strokeStyle = "#1e3d2c"
                    ctx.lineWidth = 1
                    for (var g = 0; g <= 4; g++) {
                        var gy = pad + (H / 4) * g
                        ctx.beginPath(); ctx.moveTo(pad, gy); ctx.lineTo(pad + W, gy); ctx.stroke()
                    }

                    // Zone lines (zones 0-2)
                    for (var z = 0; z < 3; z++) {
                        var data = moistureHistory[z]
                        var pts = data.length

                        // Filled area under curve
                        ctx.beginPath()
                        for (var i = 0; i < pts; i++) {
                            var x = pad + (W / (pts - 1)) * i
                            var y = pad + H - (data[i] / 100) * H
                            if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
                        }
                        ctx.lineTo(pad + W, pad + H)
                        ctx.lineTo(pad, pad + H)
                        ctx.closePath()
                        ctx.globalAlpha = 0.12
                        ctx.fillStyle = lineColors[z]
                        ctx.fill()
                        ctx.globalAlpha = 1.0

                        // Line
                        ctx.beginPath()
                        ctx.strokeStyle = lineColors[z]
                        ctx.lineWidth = 2
                        for (var j = 0; j < pts; j++) {
                            var lx = pad + (W / (pts - 1)) * j
                            var ly = pad + H - (data[j] / 100) * H
                            if (j === 0) ctx.moveTo(lx, ly); else ctx.lineTo(lx, ly)
                        }
                        ctx.stroke()
                    }
                }

                Component.onCompleted: requestPaint()

                // Legend
                Row {
                    anchors { bottom: parent.bottom; right: parent.right; bottomMargin: 4; rightMargin: 4 }
                    spacing: PhyTheme.marginSmall

                    Repeater {
                        model: ["Z1 Daktuin", "Z2 Voortuin", "Z3 Gevel N"]
                        Row {
                            spacing: 3
                            property var lColors: [PhyTheme.teal1, PhyTheme.water, PhyTheme.yellow]
                            Rectangle { width: 10; height: 2; radius: 1; color: lColors[index]; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: modelData; color: lColors[index]; font.pointSize: PhyTheme.font.pointSize * 0.3 }
                        }
                    }
                }
            }
        }

        // ── Bottom stats row ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: PhyTheme.marginRegular

            // Water usage bar chart
            Rectangle {
                Layout.fillWidth: true
                height: 110
                radius: 10
                color: PhyTheme.cardDark

                Label {
                    id: usageTitle
                    text: "Verbruik vandaag (L)"
                    color: PhyTheme.water
                    font.pointSize: PhyTheme.font.pointSize * 0.4
                    anchors { top: parent.top; left: parent.left; margins: PhyTheme.marginSmall }
                }

                Canvas {
                    id: usageChart
                    anchors {
                        top: usageTitle.bottom; left: parent.left; right: parent.right; bottom: parent.bottom
                        margins: PhyTheme.marginSmall
                    }

                    property var litres: [42, 28, 15, 33, 10, 0]
                    property var maxLitres: 50
                    property var zoneColors: [PhyTheme.teal1, PhyTheme.water, PhyTheme.teal2, PhyTheme.yellow, PhyTheme.teal3, PhyTheme.gray3]
                    property var zoneNames: ["Z1","Z2","Z3","Z4","Z5","Z6"]

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        var n = litres.length
                        var barW = (width - 8) / n - 4
                        var maxH = height - 16

                        for (var i = 0; i < n; i++) {
                            var barH = (litres[i] / maxLitres) * maxH
                            var x = 4 + i * ((width - 8) / n)
                            var y = maxH - barH

                            // Bar
                            ctx.fillStyle = zoneColors[i]
                            ctx.globalAlpha = litres[i] > 0 ? 0.85 : 0.25
                            var r = 3
                            ctx.beginPath()
                            ctx.moveTo(x, y + r)
                            ctx.arcTo(x, y, x + r, y, r)
                            ctx.arcTo(x + barW, y, x + barW, y + r, r)
                            ctx.lineTo(x + barW, maxH)
                            ctx.lineTo(x, maxH)
                            ctx.closePath()
                            ctx.fill()
                            ctx.globalAlpha = 1.0

                            // Value above bar
                            ctx.fillStyle = litres[i] > 0 ? zoneColors[i] : "#4d7a62"
                            ctx.font = "bold " + Math.floor(height * 0.18) + "px sans-serif"
                            ctx.textAlign = "center"
                            if (litres[i] > 0)
                                ctx.fillText(litres[i], x + barW / 2, y - 2)

                            // Zone label below
                            ctx.fillStyle = "#7aad92"
                            ctx.font = Math.floor(height * 0.15) + "px sans-serif"
                            ctx.fillText(zoneNames[i], x + barW / 2, height - 1)
                        }
                    }

                    Component.onCompleted: requestPaint()
                }
            }

            // Summary stats column
            Column {
                spacing: PhyTheme.marginSmall

                Repeater {
                    model: [
                        { label: "Totaal vandaag", value: "128 L",    color: PhyTheme.teal1 },
                        { label: "Actieve zones",  value: "2 / 6",    color: PhyTheme.water  },
                        { label: "Volgende run",   value: "14:30",    color: PhyTheme.yellow }
                    ]

                    Rectangle {
                        width: 140
                        height: 28
                        radius: 6
                        color: PhyTheme.cardDark

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8

                            Label {
                                text: modelData.label
                                color: PhyTheme.gray3
                                font.pointSize: PhyTheme.font.pointSize * 0.38
                                Layout.fillWidth: true
                            }
                            Label {
                                text: modelData.value
                                color: modelData.color
                                font.bold: true
                                font.pointSize: PhyTheme.font.pointSize * 0.42
                            }
                        }
                    }
                }
            }
        }
    }
}
