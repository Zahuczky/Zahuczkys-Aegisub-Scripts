import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Window


ApplicationWindow {
    id: window
    width: 1600
    height: 900
    minimumWidth: 1280
    minimumHeight: 720
    visible: true
    visibility: Window.Maximized

    title: "AutoClip"
    color: "#1B1B1B"

    property color background_colour: "#2E2E2E" // 19, 0, 0
    property color inactive_colour: "#5C5C5C" // 39, 0, 0
    property color active_colour: "#80585F" // 42, 18, 3
    property color active_colour_pressed: "#7B535A" // 40, 18, 3
    property color active_colour_highlighted: "#8B6269" // 46, 18, 3

    property int image_number: 0
    Connections {
        target: backend
        function onImageReady() {
            image_number++
            image.source = "image://backend/" + image_number
        }
    }

    Component.onCompleted: {
        if(speedtesting) {
            for(var i = 0; i < backend.frames; i++) {
                backend.active = i
            }
        }
    }
    
    Image {
        id: image
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: 0
        anchors.verticalCenterOffset: 0

        property real scale: 1
        property list<real> scale_list: [2/3, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
        width: sourceSize.width * scale
        height: sourceSize.height * scale
        source: "image://backend/" + image_number
        asynchronous: false
        smooth: false
        cache: false
    }
    
    MouseArea {
        anchors.fill: parent
        z: 10

        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        
        property bool pan: false
        property real last_x
        property real last_y
        property real lost_x
        property real lost_y

        property int previous_visibility: Window.AutomaticVisibility

        onPressed: (mouse) => {
            pan = true
            last_x = mouseX
            last_y = mouseY
            lost_x = 0
            lost_y = 0
        }
        onPositionChanged: (mouse) => {
            if(pan) {
                image.anchors.horizontalCenterOffset += lost_x + mouseX - last_x
                image.anchors.verticalCenterOffset += lost_y + mouseY - last_y
                last_x = mouseX
                last_y = mouseY

                if(Math.abs(Math.abs((window.width - image.width) / 2) - Math.abs(image.anchors.horizontalCenterOffset)) < 7 &&
                   Math.abs(Math.abs((window.height - image.height) / 2) - Math.abs(image.anchors.verticalCenterOffset)) < 7) {
                    lost_x = image.anchors.horizontalCenterOffset
                    lost_y = image.anchors.verticalCenterOffset
                    image.anchors.horizontalCenterOffset = image.anchors.horizontalCenterOffset >= 0 ? Math.abs(window.width - image.width) / 2 : -Math.abs(window.width - image.width) / 2
                    image.anchors.verticalCenterOffset = image.anchors.verticalCenterOffset >= 0 ? Math.abs(window.height - image.height) / 2 : -Math.abs(window.height - image.height) / 2
                    lost_x -= image.anchors.horizontalCenterOffset
                    lost_y -= image.anchors.verticalCenterOffset
                }
                else {
                    lost_x = 0
                    lost_y = 0
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
                for(var i = 0; i < image.scale_list.length - 1; i++) {
                    if(scale === image.scale_list[i]) {
                        image.scale = image.scale_list[i + 1]
                    }
                }
            }
            else if(wheel.angleDelta.y < 0) {
                for(var i = 1; i < image.scale_list.length; i++) {
                    if(scale === image.scale_list[i]) {
                        image.scale = image.scale_list[i - 1]
                    }
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

            else {
                event.accepted = false
            }
        }
    }

    Rectangle {
        id: frameBox
        height: 42
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: 27
        anchors.leftMargin: 71
        anchors.rightMargin: 71
        z: 20

        radius: 17
        color: window.background_colour

        MouseArea {
            anchors.fill: parent

            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            FrameSlider {
                id: frame
                anchors.fill: parent
                anchors.leftMargin: 35
                anchors.rightMargin: 35
                z: 21

                frame: backend.active
                frames: backend.frames - 1

                onNewFrame: (frame_) => {
                    backend.active = frame_
                }

                background_colour: window.background_colour
                inactive_colour: window.inactive_colour
                active_colour: window.active_colour
                active_colour_pressed: window.active_colour_pressed
            }
        }
    }

    Item {
        id: settingsZone
        anchors.top: parent.top
        anchors.bottom: frameBox.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 27
        anchors.bottomMargin: 11
        anchors.leftMargin: 71
        anchors.rightMargin: 71
        z: 20

        Rectangle {
            id: settingsBox
            anchors.centerIn: parent
            anchors.verticalCenterOffset: settingsZone.height / 2 - height / 2
            width: 919
            height: 83

            radius: 17
            color: window.background_colour

            MouseArea {
                anchors.fill: parent

                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                Row {
                    anchors.fill: parent

                    Item {
                        width: 53
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

                        Hamburger {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: 1

                            inactive_colour: window.inactive_colour
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.topMargin: 2
                            anchors.bottomMargin: 2
                            anchors.leftMargin: 2
                            z: 30

                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton

                            property bool pan: false
                            property real start_x
                            property real start_y

                            onPressed: (mouse) => {
                                pan = true
                                start_x = mouseX
                                start_y = mouseY
                            }
                            onPositionChanged: (mouse) => {
                                if(pan) {
                                    settingsBox.anchors.horizontalCenterOffset = Math.min(Math.max(-settingsZone.width / 2 + settingsBox.width / 2, settingsBox.anchors.horizontalCenterOffset + mouseX - start_x), settingsZone.width / 2 - settingsBox.width / 2)
                                    settingsBox.anchors.verticalCenterOffset = Math.min(Math.max(-settingsZone.height / 2 + settingsBox.height / 2, settingsBox.anchors.verticalCenterOffset + mouseY - start_y), settingsZone.height / 2 - settingsBox.height / 2)
                                }
                            }
                            onReleased: (mouse) => {
                                if(pan) {
                                    pan = false
                                }
                            }
                        }
                    }

                    Item {
                        width: 758
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.topMargin: 10
                        anchors.bottomMargin: 11

                        ValueSlider {
                            id: lumaThreshold
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            z: 21

                            name: "Luma Threshold"
                            value: backend.lumaThreshold * 10000
                            from: 0
                            to: 4000

                            onNewValue: (value_) => {
                                backend.lumaThreshold = value_ / 10000
                            }

                            background_colour: window.background_colour
                            inactive_colour: window.inactive_colour
                            active_colour: window.active_colour
                            active_colour_pressed: window.active_colour_pressed
                            active_colour_highlighted: window.active_colour_highlighted
                        }

                        ValueSlider {
                            id: chromaThreshold
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            z: 21

                            name: "Chroma Threshold"
                            value: backend.chromaThreshold * 10000
                            from: 0
                            to: 2000

                            onNewValue: (value_) => {
                                backend.chromaThreshold = value_ / 10000
                            }

                            background_colour: window.background_colour
                            inactive_colour: window.inactive_colour
                            active_colour: window.active_colour
                            active_colour_pressed: window.active_colour_pressed
                            active_colour_highlighted: window.active_colour_highlighted
                        }
                    }

                    Rectangle {
                        width: 1
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

                        color: window.inactive_colour
                    }


                    Item {
                        width: 106
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

                        Text {
                            id: applyText
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: -0.5
                            anchors.verticalCenterOffset: -0.5

                            font.pointSize: 13
                            color: window.active_colour

                            text: "Apply"
                        }

                        MouseArea {
                            width: 87
                            height: 59
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: -1
                            z: 30

                            acceptedButtons: Qt.LeftButton

                            onPressed: (mouse) => {
                                applyText.color = window.active_colour_highlighted
                            }
                            onCanceled: (mouse) => {
                                applyText.color = window.active_colour
                            }
                            onReleased: (mouse) => {
                                applyText.color = window.active_colour
                            }
                            onClicked: (mouse) => {
                                window.close()
                            }
                        }
                    }
                }
            }
        }
    }

    onWidthChanged: {
        settingsBox.anchors.horizontalCenterOffset = Math.min(Math.max(-settingsZone.width / 2 + settingsBox.width / 2, settingsBox.anchors.horizontalCenterOffset), settingsZone.width / 2 - settingsBox.width / 2)
    }

    onHeightChanged: {
        settingsBox.anchors.verticalCenterOffset = Math.min(Math.max(-settingsZone.height / 2 + settingsBox.height / 2, settingsBox.anchors.verticalCenterOffset), settingsZone.height / 2 - settingsBox.height / 2)
    }
}
