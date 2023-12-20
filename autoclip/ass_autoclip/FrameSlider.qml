import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic

Item {
    height: 24

    property int frame
    property int frames
    signal newFrame(int frame_)

    property color background_colour
    property color inactive_colour
    property color active_colour
    property color active_colour_pressed

    Text {
        id: text
        width: 64
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 0.6
        z: 0

        font.pointSize: 13
        color: parent.inactive_colour

        text: parent.frame + "/" + parent.frames
    }

    Slider {
        id: slider
        anchors.left: text.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        z: 0

        from: 0
        to: parent.frames
        value: parent.frame
        stepSize: 1
        snapMode: Slider.SnapAlways

        onValueChanged: {
            parent.newFrame(this.value)
        }

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2 + 0.8
            width: slider.availableWidth
            height: 2

            radius: height / 2
            color: parent.parent.inactive_colour
        }

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2 + 0.8
            width: 15
            height: width

            radius: width / 2
            color: slider.pressed ? parent.parent.active_colour_pressed : parent.parent.active_colour
            border.width: 2
            border.color: parent.parent.background_colour
        }
    }
}
