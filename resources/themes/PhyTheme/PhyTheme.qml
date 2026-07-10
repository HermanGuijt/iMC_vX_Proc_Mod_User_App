/*
 * SPDX-License-Identifier: MIT
 * Restyled for HB Watertechnologie (HBWT) — www.EmbedTech.nl
 */

pragma Singleton

import QtQuick 2.0

QtObject {
    // Base
    readonly property color white: "#ffffff"
    readonly property color gray1: "#eef4f0"
    readonly property color gray2: "#b2d8c2"
    readonly property color gray3: "#7aad92"
    readonly property color gray4: "#4d7a62"
    readonly property color black: "#000000"

    // HBWT primary palette — fresh green / water
    readonly property color teal1: "#52b788"   // main accent (fresh green)
    readonly property color teal2: "#40916c"   // mid green
    readonly property color teal3: "#2d6a4f"   // deep green
    readonly property color teal:  "#52b788"
    readonly property color water: "#48cae4"   // water blue
    readonly property color waterDark: "#0096c7"

    // Backgrounds
    readonly property color bgDark:   "#0d1f17"  // main dark canvas
    readonly property color cardDark: "#1a3327"  // card surface

    // Status / chart colours
    readonly property color red:    "#e63946"
    readonly property color orange: "#f4a261"
    readonly property color yellow: "#f7d06e"
    readonly property color green:  "#52b788"
    readonly property color cyan:   "#48cae4"
    readonly property color blue:   "#0096c7"
    readonly property color indigo: "#5e60ce"
    readonly property color purple: "#7400b8"
    readonly property color pink:   "#e83e8c"

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
