import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic

Item {
    height: 30

    property string name
    property real value
    property real from
    property real to
    signal newValue(real value_)
    property bool enabled: true

    property color background_colour
    property color inactive_colour
    property color active_colour
    property color active_colour_pressed
    property color active_colour_highlighted

    Text {
        id: label
        width: 192
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        z: 0

        font.pointSize: 13
        color: parent.inactive_colour

        text: parent.name
    }

    Text {
        id: edit
        width: 54
        anchors.left: label.right
        anchors.verticalCenter: parent.verticalCenter
        z: 0

        font.pointSize: 13
        color: parent.enabled ? parent.active_colour : parent.inactive_colour

        function foramtValue(value) {
            if(value >= 10000) {
                return Math.round(value).toString()
            }
            else if(value >= 1) {
                return value.toPrecision(4)
            }
            else if(value > 0) {
                return value.toFixed(3)
            }
            else if(value === 0) {
                return value.toString()
            }
            else if(value >= -1) {
                return value.toFixed(3)
            }
            else if(value > -10000) {
                return value.toPrecision(4)
            }
            else {
                return Math.round(value).toString()
            }
        }

        text: foramtValue(parent.value)
    }

    Slider {
        id: slider
        anchors.left: edit.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: 12
        z: 0

        from: parent.from
        to: parent.to
        value: parent.value
        snapMode: Slider.NoSnap
        enabled: parent.enabled

        onValueChanged: {
            parent.newValue(this.value)
        }

        background: Rectangle {
            x: slider.leftPadding + 4
            y: slider.topPadding + slider.availableHeight / 2 - height / 2 + 3
            width: slider.availableWidth - 8
            height: 2

            radius: height / 2
            color: parent.parent.inactive_colour
        }

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2 + 3
            width: 16
            height: width

            radius: width / 2
            color: parent.parent.enabled ? (slider.pressed ? parent.parent.active_colour_pressed : parent.parent.active_colour)
                                         : parent.parent.inactive_colour
            border.width: 1
            border.color: parent.parent.background_colour
        }
    }
}
