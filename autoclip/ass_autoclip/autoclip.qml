// vsquickview
// Copyright (c) Akatsumekusa and contributors

/* Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: window
    width: 1280
    height: 720
    visible: true
    visibility: Window.FullScreen

    title: "vsquickview"
    
    Material.theme: Material.Dark

    onClosing: (close) => {
        window.visible = false
        close.accepted = false
    }

    Connections {
        target: windowcontrol
        function onShow() {
            window.visible = true
        }
        function onHide() {
            window.visible = false
        }
    }

    Connections {
        target: backend
        function onImageChanged() {
            image.source = "image://backend/" + Math.random().toExponential()
        }
    }
    
    Image {
        id: image
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: 0
        anchors.verticalCenterOffset: 0

        width: sourceSize.width * scale
        height: sourceSize.height * scale
        source: "image://backend/" + Math.random().toExponential()
        property real scale: 1
        smooth: false
        cache: false
    }

    property bool showLabelText: false
    property string extraLabelText: ""
    function updateLabelText() {
        if(extraLabelText) {
            label.text = extraLabelText
        }
        else if(showLabelText) {
            label.text = "Index " + backend.index.toString() + (backend.name ? ": " + backend.name : "") + " / Frame " + backend.frame.toString() + (backend.frameInPreviewGroup() ? " (Preview Group)" : "")
        }
        else {
            label.text = ""
        }
    }
    Connections {
        target: window
        function onShowLabelTextChanged() {
            updateLabelText()
        }
        function onExtraLabelTextChanged() {
            updateLabelText()
        }
    }
    Connections {
        target: backend
        function onIndexChanged() {
            updateLabelText()
        }
    }
    Connections {
        target: backend
        function onFrameChanged() {
            updateLabelText()
        }
    }
    Connections {
        target: backend
        function onNameChanged() {
            updateLabelText()
        }
    }
    Connections {
        target: backend
        function onPreviewGroupChanged() {
            updateLabelText()
        }
    }

    Label {
        id: label
        font.pixelSize: 35
        color: "#B0FFFFFF"
        antialiasing: true
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 54
        anchors.left: parent.left
        anchors.leftMargin: 84

        text: ""
        onTextChanged: {
            if(text) {
                visible = true
            }
            else {
                visible = false
            }
        }

        background: Rectangle {
            color: "#40000000"
        }
    }
    
    MouseArea {
        id: mousearea
        z: 100
        focus: true
        anchors.fill: parent

        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        
        property bool pan: false
        property real offset_before_start_x
        property real offset_before_start_y
        property real start_x
        property real start_y
        
        property bool altPressed: false

        onPressed: (mouse) => {
            if(true) {
                altPressed = false
            }

            if(mouse.button === Qt.LeftButton || mouse.button === Qt.MiddleButton) {
                pan = true
                offset_before_start_x = image.anchors.horizontalCenterOffset
                offset_before_start_y = image.anchors.verticalCenterOffset
                start_x = mouseX
                start_y = mouseY
            }

            else if(mouse.button === Qt.RightButton) {
                if(!(mouse.modifiers & Qt.ShiftModifier)) {
                    backend.cycleIndex()
                }
                else {
                    backend.cycleIndexBackwards()
                }
            }
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
            if(pan && (mouse.button === Qt.LeftButton || mouse.button === Qt.MiddleButton)) {
                pan = false
            }
        }

        onWheel: (wheel) => {
            if(true) {
                altPressed = false
            }

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
        }

        property int previous_visibility: Window.AutomaticVisibility
        property string gotoFrame: "NaN"
        onGotoFrameChanged: {
            if(gotoFrame !== "NaN") {
                extraLabelText = "Goto frame " + gotoFrame
            }
            else {
                extraLabelText = ""
            }
        }

        Keys.onPressed: (event) => {
            if(true) {
                altPressed = false
            }

            if(event.key === Qt.Key_F11 || event.key === Qt.Key_F) {
                if(window.visibility === Window.Windowed ||
                   window.visibility === Window.Maximized) {
                    previous_visibility = window.visibility
                    window.visibility = Window.FullScreen
                }
                else if(window.visibility === Window.FullScreen) {
                    window.visibility = previous_visibility
                }
            }

            else if(event.key === Qt.Key_Space) {
                if(!(event.modifiers & Qt.ShiftModifier)) {
                    backend.cycleIndex()
                }
                else {
                    backend.cycleIndexBackwards()
                }
            }
            else if(event.key === Qt.Key_Up) {
                backend.nextIndex()
            }
            else if(event.key === Qt.Key_Down) {
                backend.prevIndex()
            }

            else if(event.key === Qt.Key_Alt) {
                if(event.modifiers === Qt.AltModifier) {
                    altPressed = true
                }
            }

            else if(event.key === Qt.Key_Right) {
                if(event.modifiers === Qt.ShiftModifier) {
                    backend.nextTwelveFrames()
                }
                else if(event.modifiers === Qt.ControlModifier) {
                    backend.nextPreviewGroupFrame()
                }
                else {
                    backend.nextFrame()
                }
            }
            else if(event.key === Qt.Key_Left) {
                if(event.modifiers === Qt.ShiftModifier) {
                    backend.prevTwelveFrames()
                }
                else if(event.modifiers === Qt.ControlModifier) {
                    backend.prevPreviewGroupFrame()
                }
                else {
                    backend.prevFrame()
                }
            }

            else if(event.key === Qt.Key_G) {
                gotoFrame = ""
            }
            else if(gotoFrame !== "NaN" && event.key === Qt.Key_0) {
                if(gotoFrame === "0");
                else {
                    gotoFrame = gotoFrame + "0"
                }
            }
            else if(gotoFrame !== "NaN" && event.key === Qt.Key_1) {
                if(gotoFrame === "0") {
                    gotoFrame = "1"
                }
                else {
                    gotoFrame = gotoFrame + "1"
                }
            }
            else if(gotoFrame !== "NaN" && event.key === Qt.Key_2) {
                if(gotoFrame === "0") {
                    gotoFrame = "2"
                }
                else {
                    gotoFrame = gotoFrame + "2"
                }
            }
            else if(gotoFrame !== "NaN" && event.key === Qt.Key_3) {
                if(gotoFrame === "0") {
                    gotoFrame = "3"
                }
                else {
                    gotoFrame = gotoFrame + "3"
                }
            }
            else if(gotoFrame !== "NaN" && event.key === Qt.Key_4) {
                if(gotoFrame === "0") {
                    gotoFrame = "4"
                }
                else {
                    gotoFrame = gotoFrame + "4"
                }
            }
            else if(gotoFrame !== "NaN" && event.key === Qt.Key_5) {
                if(gotoFrame === "0") {
                    gotoFrame = "5"
                }
                else {
                    gotoFrame = gotoFrame + "5"
                }
            }
            else if(gotoFrame !== "NaN" && event.key === Qt.Key_6) {
                if(gotoFrame === "0") {
                    gotoFrame = "6"
                }
                else {
                    gotoFrame = gotoFrame + "6"
                }
            }
            else if(gotoFrame !== "NaN" && event.key === Qt.Key_7) {
                if(gotoFrame === "0") {
                    gotoFrame = "7"
                }
                else {
                    gotoFrame = gotoFrame + "7"
                }
            }
            else if(gotoFrame !== "NaN" && event.key === Qt.Key_8) {
                if(gotoFrame === "0") {
                    gotoFrame = "8"
                }
                else {
                    gotoFrame = gotoFrame + "8"
                }
            }
            else if(gotoFrame !== "NaN" && event.key === Qt.Key_9) {
                if(gotoFrame === "0") {
                    gotoFrame = "9"
                }
                else {
                    gotoFrame = gotoFrame + "9"
                }
            }
            else if(gotoFrame !== "NaN" && event.key === Qt.Key_Backspace) {
                gotoFrame = gotoFrame.substring(0, gotoFrame.length - 1)
            }
            else if(gotoFrame !== "NaN" && event.key === Qt.Key_Escape) {
                gotoFrame = "NaN"
            }
            else if(gotoFrame !== "NaN" && event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                backend.switchFrame(+gotoFrame)
                gotoFrame = "NaN"
            }

            else if(event.key === Qt.Key_0) {
                backend.switchIndex(0)
            }
            else if(event.key === Qt.Key_1) {
                backend.switchIndex(1)
            }
            else if(event.key === Qt.Key_2) {
                backend.switchIndex(2)
            }
            else if(event.key === Qt.Key_3) {
                backend.switchIndex(3)
            }
            else if(event.key === Qt.Key_4) {
                backend.switchIndex(4)
            }
            else if(event.key === Qt.Key_5) {
                backend.switchIndex(5)
            }
            else if(event.key === Qt.Key_6) {
                backend.switchIndex(6)
            }
            else if(event.key === Qt.Key_7) {
                backend.switchIndex(7)
            }
            else if(event.key === Qt.Key_8) {
                backend.switchIndex(8)
            }
            else if(event.key === Qt.Key_9) {
                backend.switchIndex(9)
            }

            else if(event.key === Qt.Key_R) {
                backend.toggleFrameInPreviewGroup()
            }

            else {
                event.accepted = false
            }
        }
        Keys.onReleased: (event) => {
            if(altPressed && event.key === Qt.Key_Alt) {
                window.showLabelText = !window.showLabelText
                altPressed = false
            }
        }
    }
}
