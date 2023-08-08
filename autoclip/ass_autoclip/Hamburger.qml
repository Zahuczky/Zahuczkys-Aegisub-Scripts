import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic

Item {
    width: 30
    height: 30

    property color inactive_colour

    Item {
        width: 19
        height: 13.5
        anchors.centerIn: parent

        Column {
            spacing: 4.5

            Repeater {
                model: 3

                Rectangle {
                    width: 19
                    height: 1.5

                    color: inactive_colour
                }
            }
        }
    }
}
