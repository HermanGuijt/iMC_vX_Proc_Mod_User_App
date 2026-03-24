/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2021 PHYTEC Messtechnik GmbH
 */

import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import QtMultimedia 5.15
import PhyTheme 1.0
import "../controls"

import org.freedesktop.gstreamer.Qt6GLVideoItem 1.0

Page {
    header: PhyToolBar {
        id: header
        title: "Multimedia GST"
        subTitle: !fileDialog.selectedFile ? "" : fileDialog.selectedFile.toString()
        buttonBack.onClicked: {
            multimediaGST.pause()
            stack.pop()
        }
        buttonMenu {
            text: PhyTheme.iconFont.folderOpen
            font.family: icons.font.family
            onClicked: fileDialog.visible = true
            visible: true
        }
    }
    background: Rectangle {
        color: PhyTheme.black
    }
    footer: ToolBar {
        ColumnLayout {
            anchors.fill: parent

            RowLayout {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

                ToolButton {
                    text: PhyTheme.iconFont.play
                    font.family: icons.font.family
                    onClicked: multimediaGST.play()
                }
                ToolButton {
                    text: PhyTheme.iconFont.pause
                    font.family: icons.font.family
                    onClicked: multimediaGST.pause()
                }
                ToolButton {
                    text: PhyTheme.iconFont.skipBack
                    font.family: icons.font.family
                    onClicked: multimediaGST.seek(slider.value - 5000)
                }
                ToolButton {
                    text: PhyTheme.iconFont.skipForward
                    font.family: icons.font.family
                    onClicked: multimediaGST.seek(slider.value + 5000)
                }
                Label {
                    id: video_time_cur
                    text: "00:00"
                }
                Slider {
                    id: slider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: 0
                    onMoved: multimediaGST.seek(value)
                    onPressedChanged: {
                        if (pressed)
                            multimediaGST.positionStop()
                        else
                            multimediaGST.positionStart()
                    }
                }
                Label {
                    id: video_time_len
                    text: "00:00"
                }
                Connections {
                    target: multimediaGST
                    function onDurationChanged(len) {
                        slider.to = len
                        if (len >= 3600000) {
                            video_time_len.text = new Date(len).toLocaleTimeString(Qt.locale(), "hh:" + "mm:" + "ss")
                        } else {
                            video_time_len.text = new Date(len).toLocaleTimeString(Qt.locale(), "mm:" + "ss")
                        }
                    }
                    function onPositionChanged(pos) {
                        slider.value = pos
                        if (slider.to >= 3600000) {
                            video_time_cur.text = new Date(pos).toLocaleTimeString(Qt.locale(), "hh:" + "mm:" + "ss")
                        } else {
                            video_time_cur.text = new Date(pos).toLocaleTimeString(Qt.locale(), "mm:" + "ss")
                        }
                    }
                }
            }
        }
    }

    Item {
        anchors.fill: parent

        GstGLQt6VideoItem {
            id: video
            objectName: "videoItem"
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            Component.onCompleted:
                multimediaGST.setupNewPipeline(fileDialog.selectedFile)
        }
    }

    PhyFileDialog {
        id: fileDialog
        selectedFile: "file:///usr/share/qtphy/videos/caminandes_3_llamigos_720p_vp9.webm"
        nameFilters: ["*.webm", "*.mp4"]
        onSelectedFileChanged:
            multimediaGST.setupNewPipeline(fileDialog.selectedFile)
    }
}
