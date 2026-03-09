import QtQuick
import QtQuick.Controls
import QtQuick.Shapes

Item {
    id: root

    readonly property real scaleFactor: (width > 0 && height > 0) ? Math.min(width / 1920, height / 1080) : 0.5
    function s(value) { return value * scaleFactor }

    property real currentSpeed: SerialHandler.connected ? SerialHandler.speed : 0
    property real currentRpm: SerialHandler.connected ? SerialHandler.rpm : 0.8
    property real fuelLevel: SerialHandler.connected ? SerialHandler.fuelLevel / 100.0 : 0.75
    property real batteryLevel: SerialHandler.connected ? SerialHandler.batteryLevel / 100.0 : 1

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: root.currentTime = Qt.formatTime(new Date(), "HH:mm")
    }

    property string currentTime: ""

    // 顶部时间
    Column {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: parent.height * 0.04
        spacing: s(12)

        Text {
            text: currentTime
            font.pixelSize: s(32)
            font.weight: Font.Light
            font.letterSpacing: 4
            color: "#FFFFFF"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: Qt.formatDate(new Date(), "MM月dd日 dddd")
            font.pixelSize: s(20)
            font.letterSpacing: 2
            color: "#80FFFFFF"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Row {
            spacing: s(12)
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                width: s(10)
                height: s(10)
                radius: s(5)
                color: SerialHandler.connected ? "#4ade80" : "#ef4444"
            }

            Text {
                text: SerialHandler.connected ? "已连接" : "未连接"
                font.pixelSize: s(18)
                color: "#80FFFFFF"
            }
        }
    }

    // 速度表
    Item {
        id: speedGauge
        width: Math.min(parent.width * 0.22, parent.height * 0.4)
        height: width
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.14
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -parent.height * 0.03

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 1.15
            height: width
            radius: width / 2
            color: "transparent"
            border.color: "#1A667eea"
            border.width: parent.width * 0.15
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.color: "#1AFFFFFF"
            border.width: s(3)
        }

        Shape {
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 8

            ShapePath {
                strokeColor: "#667eea"
                strokeWidth: s(8)
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: speedGauge.width / 2
                    centerY: speedGauge.height / 2
                    radiusX: speedGauge.width / 2 - s(15)
                    radiusY: speedGauge.height / 2 - s(15)
                    startAngle: 135
                    sweepAngle: Math.min((currentSpeed / 220) * 270, 270)
                }
            }
        }

        Repeater {
            model: 12

            Item {
                anchors.fill: parent
                rotation: -135 + index * 24.5

                Rectangle {
                    width: index % 3 === 0 ? s(3) : s(1.5)
                    height: index % 3 === 0 ? parent.width * 0.05 : parent.width * 0.03
                    radius: width / 2
                    color: (index * 20) <= currentSpeed ? "#667eea" : "#33FFFFFF"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: parent.width * 0.06

                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: s(8)

            Text {
                text: Math.round(currentSpeed)
                font.pixelSize: speedGauge.width * 0.24
                font.weight: Font.ExtraLight
                color: "#FFFFFF"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "km/h"
                font.pixelSize: s(24)
                font.letterSpacing: 4
                font.weight: Font.Light
                color: "#80FFFFFF"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        Rectangle {
            width: parent.width * 0.55
            height: width
            radius: width / 2
            anchors.centerIn: parent
            color: "transparent"
            border.color: "#0DFFFFFF"
            border.width: 1
        }
    }

    // 中央信息
    Column {
        anchors.centerIn: parent
        spacing: s(24)

        Rectangle {
            width: s(200)
            height: s(60)
            radius: height / 2
            color: "#14FFFFFF"
            border.color: "#26FFFFFF"
            border.width: 1
            anchors.horizontalCenter: parent.horizontalCenter

            Row {
                anchors.centerIn: parent
                spacing: s(14)

                Rectangle {
                    width: s(12); height: s(12); radius: s(6)
                    color: "#4ade80"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "正常行驶"
                    font.pixelSize: s(22)
                    font.letterSpacing: 2
                    color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: s(24)

            Repeater {
                model: ["P", "R", "N", "D"]

                Text {
                    text: modelData
                    font.pixelSize: s(26)
                    font.weight: modelData === "D" ? Font.Bold : Font.Light
                    color: modelData === "D" ? "#667eea" : "#4DFFFFFF"
                }
            }
        }
    }

    // 转速表
    Item {
        id: rpmGauge
        width: Math.min(parent.width * 0.22, parent.height * 0.4)
        height: width
        anchors.right: parent.right
        anchors.rightMargin: parent.width * 0.14
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -parent.height * 0.03

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 1.15
            height: width
            radius: width / 2
            color: "transparent"
            border.color: "#1Af093fb"
            border.width: parent.width * 0.15
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.color: "#1AFFFFFF"
            border.width: s(3)
        }

        Shape {
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 8

            ShapePath {
                strokeColor: currentRpm > 6 ? "#ef4444" : "#f093fb"
                strokeWidth: s(8)
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: rpmGauge.width / 2
                    centerY: rpmGauge.height / 2
                    radiusX: rpmGauge.width / 2 - s(15)
                    radiusY: rpmGauge.height / 2 - s(15)
                    startAngle: 135
                    sweepAngle: Math.min((currentRpm / 8) * 270, 270)
                }
            }
        }

        Repeater {
            model: 9

            Item {
                anchors.fill: parent
                rotation: -135 + index * 33.75

                Rectangle {
                    width: s(2)
                    height: parent.width * 0.04
                    radius: s(1)
                    color: index <= currentRpm ? "#f093fb" : "#33FFFFFF"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: parent.width * 0.06

                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: s(8)

            Text {
                text: currentRpm.toFixed(1)
                font.pixelSize: rpmGauge.width * 0.24
                font.weight: Font.ExtraLight
                color: "#FFFFFF"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "×1000 RPM"
                font.pixelSize: s(20)
                font.letterSpacing: 2
                font.weight: Font.Light
                color: "#80FFFFFF"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        Rectangle {
            width: parent.width * 0.55
            height: width
            radius: width / 2
            anchors.centerIn: parent
            color: "transparent"
            border.color: "#0DFFFFFF"
            border.width: 1
        }
    }

    // 底部状态栏
    Rectangle {
        width: Math.min(parent.width * 0.45, s(700))
        height: s(70)
        radius: height / 2
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: parent.height * 0.08
        color: "#0DFFFFFF"
        border.color: "#1AFFFFFF"
        border.width: 1

        Row {
            anchors.centerIn: parent
            spacing: s(80)

            // 油量
            Row {
                spacing: s(16)
                anchors.verticalCenter: parent.verticalCenter

                Text { text: "⛽"; font.pixelSize: s(24); anchors.verticalCenter: parent.verticalCenter }

                Rectangle {
                    width: s(140); height: s(7); radius: s(3.5)
                    color: "#1AFFFFFF"
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        width: parent.width * fuelLevel
                        height: parent.height
                        radius: s(3.5)
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: fuelLevel < 0.2 ? "#ef4444" : "#667eea" }
                            GradientStop { position: 1.0; color: fuelLevel < 0.2 ? "#f87171" : "#764ba2" }
                        }

                        Behavior on width { NumberAnimation { duration: 300 } }
                    }
                }

                Text {
                    text: Math.round(fuelLevel * 100) + "%"
                    font.pixelSize: s(18)
                    color: fuelLevel < 0.2 ? "#ef4444" : "#B3FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // 分隔线
            Rectangle { width: 1; height: s(36); color: "#33FFFFFF"; anchors.verticalCenter: parent.verticalCenter }

            // 电量
            Row {
                spacing: s(16)
                anchors.verticalCenter: parent.verticalCenter

                Text { text: "🔋"; font.pixelSize: s(24); anchors.verticalCenter: parent.verticalCenter }

                Rectangle {
                    width: s(140); height: s(7); radius: s(3.5)
                    color: "#1AFFFFFF"
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        width: parent.width * batteryLevel
                        height: parent.height
                        radius: s(3.5)
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#4ade80" }
                            GradientStop { position: 1.0; color: "#22d3ee" }
                        }

                        Behavior on width { NumberAnimation { duration: 300 } }
                    }
                }

                Text {
                    text: Math.round(batteryLevel * 100) + "%"
                    font.pixelSize: s(18)
                    color: "#B3FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // 右滑提示（放大文字和箭头）
    Column {
        anchors.right: parent.right
        anchors.rightMargin: parent.width * 0.03
        anchors.verticalCenter: parent.verticalCenter
        spacing: s(16)
        opacity: 0.6

        Text {
            text: "›"
            font.pixelSize: s(48)
            font.weight: Font.Light
            color: "#FFFFFF"
            anchors.horizontalCenter: parent.horizontalCenter

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 1; duration: 600 }
                NumberAnimation { to: 0.2; duration: 600 }
            }

            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { to: s(8); duration: 600; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 0; duration: 600; easing.type: Easing.InOutQuad }
            }
        }
        Text {
            text: "滑动"
            font.pixelSize: s(16)
            font.letterSpacing: 2
            color: "#80FFFFFF"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
