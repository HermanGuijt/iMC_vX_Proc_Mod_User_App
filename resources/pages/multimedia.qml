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

Page {
    header: PhyToolBar {
        id: header
        title: "Multimedia"
        subTitle: !fileDialog.selectedFile ? "" : fileDialog.selectedFile.toString()
        buttonBack.onClicked: {
            video.pause()
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
                    onClicked: video.play()
                }
                ToolButton {
                    text: PhyTheme.iconFont.pause
                    font.family: icons.font.family
                    onClicked: video.pause()
                }
                ToolButton {
                    text: PhyTheme.iconFont.skipBack
                    font.family: icons.font.family
                    onClicked: video.seek(video.position - 5000)
                }
                ToolButton {
                    text: PhyTheme.iconFont.skipForward
                    font.family: icons.font.family
                    onClicked: video.seek(video.position + 5000)
                }
                Slider {
                    Layout.fillWidth: true
                    from: 0
                    to: video.duration
                    value: video.position
                    onMoved: video.seek(value)
                }
            }
        }
    }

    Video {
        id: video
        anchors.fill: parent
        source: fileDialog.selectedFile
    }

    PhyFileDialog {
        id: fileDialog
        selectedFile: "file:///usr/share/qtphy/videos/caminandes_3_llamigos_720p_vp9.webm"
        nameFilters: ["*.webm", "*.mp4"]
    }
}
