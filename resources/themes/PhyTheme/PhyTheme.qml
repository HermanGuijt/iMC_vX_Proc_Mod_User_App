/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2021 PHYTEC Messtechnik GmbH
 */

pragma Singleton

import QtQuick 2.0

QtObject {
    readonly property color white: "#ffffff"
    readonly property color gray1: "#f5f5f5"
    readonly property color gray2: "#d0d2d3"
    readonly property color gray3: "#95989a"
    readonly property color gray4: "#707070"
    readonly property color black: "#000000"
    readonly property color teal1: "#03c9d6"
    readonly property color teal2: "#02a6b1"
    readonly property color teal3: "#16969e"
    readonly property color red: "#dc3545"
    readonly property color orange: "#fd7e14"
    readonly property color yellow: "#ffc107"
    readonly property color green: "#28a745"
    readonly property color teal: "#20c997"
    readonly property color cyan: "#17a2b8"
    readonly property color blue: "#007bff"
    readonly property color indigo: "#6610f2"
    readonly property color purple: "#6f42c1"
    readonly property color pink: "#e83e8c"

    readonly property int marginSmall: 6
    readonly property int marginRegular: 12
    readonly property int marginBig: 24

    property font font
    font.family: "Roboto"
    font.pointSize: 20

    property QtObject iconFont: QtObject {
        readonly property string arrowLeft: "\ue5c4"
        readonly property string dotsThreeVertical: "\ue5d4"
        readonly property string code: "\ue86f"
        readonly property string cpu: "\ue322"
        readonly property string file: "\ue66d"
        readonly property string folder: "\ue2c7"
        readonly property string folderOpen: "\ue2c8"
        readonly property string frameCorners: "\ue3c2"
        readonly property string image: "\ue3f4"
        readonly property string lightbulb: "\ue0f0"
        readonly property string list: "\ue896"
        readonly property string magnifyingGlassMinus: "\ue900"
        readonly property string magnifyingGlassPlus: "\ue8ff"
        readonly property string numberSquareOne: "\ue400"
        readonly property string play: "\ue037"
        readonly property string pause: "\ue034"
        readonly property string stop: "\ue047"
        readonly property string skipBack: "\ue045"
        readonly property string skipForward: "\ue044"
    }
}
