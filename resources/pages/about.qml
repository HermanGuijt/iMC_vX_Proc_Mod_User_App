/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2021 PHYTEC Messtechnik GmbH
 */

import QtQuick 2.6
import QtQuick.Controls 2.9
import QtQuick.Layouts 1.0
import PhyTheme 1.0
import "../controls"

Page {
    header: PhyToolBar {
        title: "About PHYTEC"
        buttonBack.onClicked: stack.pop()
        buttonMenu.visible: false
    }

    Flickable {
        id: scrollView
        anchors.fill: parent
        contentWidth: content.width
        contentHeight: content.height

        Row {
            id: content
            spacing: PhyTheme.marginBig
            padding: PhyTheme.marginBig
            width: scrollView.width

            Column {
                Label {
                    id: labelTitle
                    text: "<h2>PHYTEC – your partner</h2><p>for embedded systems</p>"
                }
                Image {
                    source: "qrc:///images/company.jpg"
                    width: labelTitle.width
                    fillMode: Image.PreserveAspectCrop
                    height: labelDescription.height - labelTitle.height - 2 * content.padding
                }
            }
            Label {
                id: labelDescription
                wrapMode: Text.WordWrap
                width: content.width - labelTitle.width - 2 * content.padding - content.spacing
                text: "<p><b>" +
                "We have been developing and manufacturing embedded components for reliable electronic series products for more than 30 years." +
                "</b></p>" +
                "<p>" +
                "Processor modules such as systems on modules and single board computers are our core business. Customer-specific embedded systems including software, housing design and assembly expand our product range. With our specialized know-how in embedded imaging, IoT solutions, cloud services, embedded security and artificial intelligence, we are ideally positioned to support you professionally in the development of your product ideas." +
                "</p>" +
                "<p><b>" +
                "Our products and services shorten your time-to-market, reduce your development costs and your risk in the development and production of industrial embedded systems." +
                "</b></p>"
            }
        }
    }
}
