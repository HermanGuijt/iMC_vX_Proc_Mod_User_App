/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2021 PHYTEC Messtechnik GmbH
 */

import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import Qt.labs.folderlistmodel 2.15
import PhyTheme 1.0

Rectangle {
    id: dialog
    width: parent.width - 2 * PhyTheme.marginBig
    height: parent.height - 2 * PhyTheme.marginBig
    anchors.centerIn: parent
    visible: false
    color: PhyTheme.white
    property string selectedFile: ""
    property string currentFile: "file:///"
    property alias nameFilters: folderListModel.nameFilters

    FolderListModel {
        id: folderListModel
        showDotAndDotDot: true
        showDirsFirst: true
    }

    Component {
        id: fileDelegate

        Item {
            width: listView.width
            height: labelFileName.implicitHeight

            RowLayout {
                anchors.fill: parent
                spacing: PhyTheme.marginSmall

                Label {
                    text: folderListModel.isFolder(index) ? PhyTheme.iconFont.folder : PhyTheme.iconFont.file
                    font.family: icons.font.family
                    Layout.leftMargin: PhyTheme.marginSmall
                }
                Label {
                    id: labelFileName
                    text: fileName
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
                Label {
                    text: fileSize + " B"
                    Layout.rightMargin: PhyTheme.marginSmall
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    listView.currentIndex = index

                    if (folderListModel.isFolder(index)) {
                        if (fileName === ".") {
                            return
                        } else if (fileName === "..") {
                            if (folderListModel.folder == "file:///") {
                                return
                            }
                            dialog.currentFile = folderListModel.parentFolder
                        } else {
                            if (folderListModel.folder == "file:///") {
                                dialog.currentFile = "file:///" + fileName
                            } else {
                                dialog.currentFile = folderListModel.folder + "/" + fileName
                            }
                        }
                        folderListModel.folder = dialog.currentFile
                        listView.currentIndex = -1
                    } else {
                        dialog.currentFile = fileURL
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: dialog
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            spacing: PhyTheme.marginRegular
            Layout.margins: PhyTheme.marginSmall

            Button {
                text: "Cancel"
                flat: true
                onClicked: dialog.visible = false
            }
            Label {
                Layout.fillWidth: true
                text: folderListModel.folder.toString().replace("file://", "")
                elide: Text.ElideLeft
                Layout.leftMargin: PhyTheme.marginRegular
                Layout.rightMargin: PhyTheme.marginRegular
            }
            Button {
                text: "Open"
                flat: true
                onClicked: {
                    dialog.selectedFile = dialog.currentFile
                    dialog.visible = false
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            color: PhyTheme.gray2
            implicitHeight: labelHeaderName.implicitHeight

            RowLayout {
                anchors.fill: parent

                Label {
                    id: labelHeaderName
                    text: "Name"
                    Layout.fillWidth: true
                    Layout.leftMargin: PhyTheme.marginSmall
                }
                Label {
                    text: "Size"
                    Layout.rightMargin: PhyTheme.marginSmall
                }
            }
        }

        ListView {
            id: listView
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: folderListModel
            delegate: fileDelegate
            highlight: Rectangle {
                color: PhyTheme.gray1
            }
        }
    }
}
