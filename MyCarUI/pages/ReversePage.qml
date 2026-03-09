import QtQuick
import QtQuick.Controls

Item {
    id: root

    Rectangle {
        anchors.fill: parent
        color: "#000000"

        Column {
            anchors.centerIn: parent
            spacing: 40

            Text {
                text: "🚗"
                font.pixelSize: 120
                anchors.horizontalCenter: parent.horizontalCenter

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 500 }
                    NumberAnimation { to: 1.0; duration: 500 }
                }
            }

            Text {
                text: "倒 车"
                font.pixelSize: 80
                font.weight: Font.Bold
                font.letterSpacing: 20
                color: "#FF4444"
                anchors.horizontalCenter: parent.horizontalCenter

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.5; duration: 500 }
                    NumberAnimation { to: 1.0; duration: 500 }
                }
            }

            Text {
                text: "请注意后方"
                font.pixelSize: 24
                font.letterSpacing: 4
                color: "#AAFFFFFF"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: "#FF4444"
            border.width: 8

            SequentialAnimation on border.width {
                loops: Animation.Infinite
                NumberAnimation { to: 4; duration: 500 }
                NumberAnimation { to: 8; duration: 500 }
            }
        }
    }
}
