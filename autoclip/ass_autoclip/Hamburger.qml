import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic

Item {
    width: 24
    height: 24

    property color inactive_colour

    Item {
        width: 15
        height: 11.5
        anchors.centerIn: parent

        Column {
            spacing: 3.5

            Repeater {
                model: 3

                Rectangle {
                    width: 15
                    height: 1.5

                    color: inactive_colour
                }
            }
        }
    }
}
