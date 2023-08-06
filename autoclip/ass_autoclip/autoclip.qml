import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: window
    width: 1280
    height: 720
    visible: true
    visibility: Window.Maximized

    title: "AutoClip"
    color: "#101818"

    // onClosing: (close) => {
    // }

    property int image_number: 0
    Connections {
        target: backend
        function onImageReady() {
            image_number++
            image.source = "image://backend/" + image_number
        }
    }

    // Component.onCompleted: {
    //     for(let i = 0; i < 103; i++) {
    //         backend.active = i
    //     }
    // }
    
    Image {
        id: image
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: 0
        anchors.verticalCenterOffset: 0

        property real scale: 1
        width: sourceSize.width * scale
        height: sourceSize.height * scale
        source: "image://backend/" + image_number
        asynchronous: false
        smooth: false
        cache: false
    }
    
    MouseArea {
        id: mousearea
        z: 10
        focus: true
        anchors.fill: parent

        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        
        property bool pan: false
        property real offset_before_start_x
        property real offset_before_start_y
        property real start_x
        property real start_y

        property int previous_visibility: Window.AutomaticVisibility

        onPressed: (mouse) => {
            pan = true
            offset_before_start_x = image.anchors.horizontalCenterOffset
            offset_before_start_y = image.anchors.verticalCenterOffset
            start_x = mouseX
            start_y = mouseY
        }
        onPositionChanged: (mouse) => {
            if(pan) {
                image.anchors.horizontalCenterOffset = mouseX - start_x + offset_before_start_x
                image.anchors.verticalCenterOffset = mouseY - start_y + offset_before_start_y

                if(Math.abs(Math.abs((window.width - image.width) / 2) - Math.abs(image.anchors.horizontalCenterOffset)) < 7 &&
                   Math.abs(Math.abs((window.height - image.height) / 2) - Math.abs(image.anchors.verticalCenterOffset)) < 7) {
                    image.anchors.horizontalCenterOffset = image.anchors.horizontalCenterOffset >= 0 ? -(window.width - image.width) / 2 : (window.width - image.width) / 2
                    image.anchors.verticalCenterOffset = image.anchors.verticalCenterOffset >= 0 ? -(window.height - image.height) / 2 : (window.height - image.height) / 2
                }
            }
        }
        onReleased: (mouse) => {
            if(pan) {
                pan = false
            }
        }

        onWheel: (wheel) => {
            let image_x = image.x
            let image_y = image.y
            let image_width = image.width
            let image_height = image.height
            let scale = image.scale

            if(wheel.angleDelta.y > 0) {
                if(scale < 12) {
                    image.scale = scale + 1
                }
            }
            else if(wheel.angleDelta.y < 0) {
                if(scale > 1) {
                    image.scale = scale - 1
                }
            }

            if(mouseX > image_x && mouseX < image_x + image_width &&
               mouseY > image_y && mouseY < image_y + image_height) {
                image.anchors.horizontalCenterOffset = image.anchors.horizontalCenterOffset - (mouseX - image_x - image_width/2) * (image.scale / scale - 1)
                image.anchors.verticalCenterOffset = image.anchors.verticalCenterOffset - (mouseY - image_y - image_height/2) * (image.scale / scale - 1)
            }
            else {
                image.anchors.horizontalCenterOffset = image.anchors.horizontalCenterOffset - (window.width/2 - image_x - image_width/2) * (image.scale / scale - 1)
                image.anchors.verticalCenterOffset = image.anchors.verticalCenterOffset - (window.height/2 - image_y - image_height/2) * (image.scale / scale - 1)
            }
        }

        Keys.onPressed: (event) => {
            if(event.key === Qt.Key_F11) {
                if(window.visibility === Window.Windowed ||
                   window.visibility === Window.Maximized) {
                    previous_visibility = window.visibility
                    window.visibility = Window.FullScreen
                }
                else if(window.visibility === Window.FullScreen) {
                    window.visibility = previous_visibility
                }
            }

            else if(event.key === Qt.Key_Right) {
                backend.active = Math.min(backend.active + 1, backend.frames - 1)
            }
            else if(event.key === Qt.Key_Left) {
                backend.active = Math.max(0, backend.active - 1)
            }

            else {
                event.accepted = false
            }
        }
    }





    Slider {
        id: frame
        x: 100
        y: 100
        width: 500
        z: 11

        from: 0
        to: backend.frames - 1
        value: backend.active
        stepSize: 1
        snapMode: Slider.SnapAlways

        onValueChanged: {
            backend.active = this.value
        }
    }

    Slider {
        id: differnce
        x: 100
        y: 200
        width: 500
        z: 11

        from: 0
        to: 2000
        value: backend.difference * 10000
        stepSize: 50

        onValueChanged: {
            backend.difference = this.value / 10000
        }
    }

    //    Label {
    //        id: label
    //        font.pixelSize: 35
    //        color: "#B0FFFFFF"
    //        antialiasing: true
    //        anchors.bottom: parent.bottom
    //        anchors.bottomMargin: 54
    //        anchors.left: parent.left
    //        anchors.leftMargin: 84

    //        text: ""
    //        onTextChanged: {
    //            if(text) {
    //                visible = true
    //            }
    //            else {
    //                visible = false
    //            }
    //        }

    //        background: Rectangle {
    //            color: "#40000000"
    //        }
    //    }
}
