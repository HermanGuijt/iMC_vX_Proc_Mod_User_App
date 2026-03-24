/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2021 PHYTEC Messtechnik GmbH
 */

import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import Qt.labs.folderlistmodel 2.15
import PhyTheme 1.0
import "../controls"

Page {
    header: PhyToolBar {
        title: "Image Viewer"
        buttonBack.onClicked: {
            if (detailedImageView.visible) {
                detailedImageView.visible = false
                gridViewGallery.visible = true
            } else {
                stack.pop()
            }
        }
        buttonMenu.enabled: false
    }
    background: Image {
        source: "qrc:///images/background.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    FolderListModel {
        id: folderModel
        nameFilters: ["*.jpg", "*.JPG", "*.jpeg", "*.png", "*.webp", "*.bmp"]
        showDirs: false
        folder: "file:///usr/share/qtphy/images"
    }

    Component {
        id: imageDelegate

        RowLayout {
            width: gridViewGallery.cellWidth
            height: gridViewGallery.cellHeight

            Rectangle {
                color: PhyTheme.white
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.rightMargin: PhyTheme.marginSmall
                Layout.bottomMargin: PhyTheme.marginSmall

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        detailedImageView.filename = fileURL
                        detailedImageView.title = fileName
                        detailedImageView.visible = true
                        gridViewGallery.visible = false
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: PhyTheme.marginRegular

                    Image {
                        source: fileURL
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }
                    Label {
                        text: fileName
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent

        GridView {
            id: gridViewGallery
            model: folderModel
            delegate: imageDelegate
            cellWidth: parent.width / 4 - PhyTheme.marginBig / 2
            cellHeight: cellWidth / 4 * 3 - PhyTheme.marginBig / 2
            Layout.margins: PhyTheme.marginBig
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    Item {
        id: detailedImageView
        anchors.fill: parent
        anchors.margins: PhyTheme.marginBig
        visible: false
        property string filename: ""
        property string title: ""

        RowLayout {
            anchors.fill: parent
            spacing: PhyTheme.marginSmall

            Rectangle {
                color: PhyTheme.white
                Layout.fillHeight: true
                Layout.fillWidth: true

                Flickable {
                    id: detailedImageContainer
                    clip: true
                    contentWidth: detailedImage.width
                    contentHeight: detailedImage.height
                    anchors.fill: parent

                    Image {
                        id: detailedImage
                        asynchronous: true
                        source: detailedImageView.filename
                        onStatusChanged: {
                            if (status == Image.Ready) {
                                detailedImage.width = detailedImageContainer.width
                                detailedImage.height = detailedImageContainer.width
                                                       / (detailedImage.sourceSize.width
                                                          / detailedImage.sourceSize.height)
                            }
                        }
                    }
                }
            }
            Rectangle {
                color: PhyTheme.white
                Layout.fillHeight: true
                Layout.preferredWidth: toolButtonLayout.width * 2

                ColumnLayout {
                    RowLayout {
                        id: toolButtonLayout
                        Layout.alignment: Qt.AlignHCenter
                        Layout.margins: PhyTheme.marginRegular

                        ToolButton {
                            text: PhyTheme.iconFont.magnifyingGlassPlus
                            font.family: icons.font.family
                            horizontalPadding: PhyTheme.marginRegular
                            onClicked: {
                                detailedImage.width *= 1.2
                                detailedImage.height *= 1.2
                            }
                        }
                        ToolButton {
                            text: PhyTheme.iconFont.magnifyingGlassMinus
                            font.family: icons.font.family
                            horizontalPadding: PhyTheme.marginRegular
                            onClicked: {
                                detailedImage.width *= 0.8333
                                detailedImage.height *= 0.8333
                            }
                        }
                        ToolButton {
                            text: PhyTheme.iconFont.frameCorners
                            font.family: icons.font.family
                            horizontalPadding: PhyTheme.marginRegular
                            onClicked: {
                                detailedImage.width = detailedImageContainer.width
                                detailedImage.height = detailedImageContainer.width
                                                       / (detailedImage.sourceSize.width
                                                          / detailedImage.sourceSize.height)
                            }
                        }
                        ToolButton {
                            text: PhyTheme.iconFont.numberSquareOne
                            font.family: icons.font.family
                            horizontalPadding: PhyTheme.marginRegular
                            onClicked: {
                                detailedImage.width = detailedImage.sourceSize.width
                                detailedImage.height = detailedImage.sourceSize.height
                            }
                        }
                    }
                    GridLayout {
                        columns: 2
                        Layout.alignment: Qt.AlignHCenter
                        Layout.margins: PhyTheme.marginRegular

                        Label {
                            id: textFilename
                            text: "Filename"
                            color: PhyTheme.gray3
                            Layout.alignment: Qt.AlignRight
                        }
                        Label {
                            text: detailedImageView.title
                            elide: Text.ElideMiddle
                            Layout.preferredWidth: 2 * toolButtonLayout.width
                                                   - textFilename.width
                                                   - 2 * PhyTheme.marginRegular
                        }
                        Label {
                            text: "Size"
                            color: PhyTheme.gray3
                            Layout.alignment: Qt.AlignRight
                        }
                        Label {
                            text: detailedImage.sourceSize.width + " × " + detailedImage.sourceSize.height + " px"
                        }
                    }
                }
            }
        }
    }
}
