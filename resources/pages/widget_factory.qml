/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2021 PHYTEC Messtechnik GmbH
 */

import QtQuick 2.15
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import PhyTheme 1.0
import "../controls"

Page {
    header: PhyToolBar {
        title: "Widget Factory"
        buttonBack.onClicked: stack.pop()
    }
    Flickable {
        id: scrollView
        anchors.fill: parent
        contentWidth: content.width
        contentHeight: content.height

        RowLayout {
            id: content
            spacing: PhyTheme.marginBig
            width: Math.max(scrollView.width, implicitWidth)

            ColumnLayout {
                Layout.topMargin: PhyTheme.marginBig
                Layout.leftMargin: PhyTheme.marginBig
                Layout.bottomMargin: PhyTheme.marginBig
                Layout.fillWidth: true

                TextField {
                    Layout.fillWidth: true
                    placeholderText: "Regular text field"
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "Disabled text field"
                    enabled: false
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "Password text field"
                    echoMode: TextInput.Password
                    inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhPreferLowercase |
                                      Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "Uppercase text field"
                    inputMethodHints: Qt.ImhUppercaseOnly
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "Lowercase text field"
                    inputMethodHints: Qt.ImhLowercaseOnly
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "Phone number field"
                    inputMethodHints: Qt.ImhDialableCharactersOnly
                    validator: RegularExpressionValidator { regularExpression: /^[0-9\+\-\#\*\ ]{6,}$/ }
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "Formatted number field"
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "Digits only field"
                    inputMethodHints: Qt.ImhDigitsOnly
                }
                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: "Normal Button"
                    }
                    Button {
                        text: "Flat Button"
                        flat: true
                    }
                    ToolButton {
                        text: "Tool Button"
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    CheckBox {
                        text: "phyCORE-i.MX 6"
                        checked: true
                    }
                    CheckBox {
                        text: "phyCORE-i.MX 6 UL"
                    }
                    CheckBox {
                        text: "phyCORE-i.MX 8M Mini/Nano"
                        checked: true
                    }
                    CheckBox {
                        text: "phyCORE-i.MX 8M Plus"
                    }
                }
            }
            ColumnLayout {
                Layout.topMargin: PhyTheme.marginBig
                Layout.rightMargin: PhyTheme.marginBig
                Layout.bottomMargin: PhyTheme.marginBig
                Layout.fillWidth: true

                Slider {
                    id: slider
                    value: 0.5
                    Layout.fillWidth: true
                }
                RangeSlider {
                    first.value: 0.2
                    second.value: 0.7
                    Layout.fillWidth: true
                }
                ProgressBar {
                    value: slider.value
                    Layout.fillWidth: true
                }
                ProgressBar {
                    indeterminate: true
                    Layout.fillWidth: true
                }
                ComboBox {
                    Layout.fillWidth: true
                    model: ["phyCORE-i.MX 6",
                            "phyCORE-i.MX 6 UL",
                            "phyCORE-i.MX 8M Mini",
                            "phyCORE-i.MX 8M Nano",
                            "phyCORE-i.MX 8M Plus"]
                }
                ComboBox {
                    Layout.fillWidth: true
                    model: ["phyCORE", "phyBOARD", "phyCAM", "phyGATE"]
                    editable: true
                }
                SpinBox {
                    value: 42
                    Layout.fillWidth: true
                }
                TextArea {
                    placeholderText: "Multiline text field"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}
