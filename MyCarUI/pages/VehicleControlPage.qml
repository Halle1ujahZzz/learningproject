import QtQuick
import QtQuick.Controls

Item {
    id: root

    width: parent ? parent.width : 800
    height: parent ? parent.height : 600

    readonly property real scaleFactor: Math.min(width / 1920, height / 880)
    function s(value) { return value * scaleFactor }

    property bool doorLocked: true
    property bool lightsOn: false
    property bool trunkOpen: false
    property bool windowsClosed: true
    property bool flashlightOn: false
    property bool engineRunning: false

    Row {
        anchors.centerIn: parent
        spacing: parent.width * 0.06  // 增大整体间距，更宽松

        // 左侧 - 车辆可视化区域
        Rectangle {
            width: root.width * 0.40
            height: root.height * 0.80
            radius: s(32)
            color: "#0DFFFFFF"
            border.color: "#1AFFFFFF"
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: s(45)  // 增大垂直间距

                // 车辆图标
                Text {
                    text: "🚗"
                    font.pixelSize: s(180)
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // 车辆状态列表
                Column {
                    spacing: s(28)  // 增大状态项间距
                    anchors.horizontalCenter: parent.horizontalCenter

                    // 车门状态
                    Row {
                        spacing: s(20)
                        Text {
                            text: "车门:"
                            font.pixelSize: s(22)  // 原16 → 22
                            color: "#CCFFFFFF"
                            width: s(120)
                        }
                        Text {
                            text: doorLocked ? "已锁定 🔒" : "已解锁 🔓"
                            font.pixelSize: s(22)
                            font.weight: Font.Medium
                            color: doorLocked ? "#4ade80" : "#fbbf24"
                        }
                    }

                    // 车灯状态
                    Row {
                        spacing: s(20)
                        Text {
                            text: "车灯:"
                            font.pixelSize: s(22)
                            color: "#CCFFFFFF"
                            width: s(120)
                        }
                        Text {
                            text: lightsOn ? "开启 💡" : "关闭 🌑"
                            font.pixelSize: s(22)
                            font.weight: Font.Medium
                            color: lightsOn ? "#fbbf24" : "#94a3b8"
                        }
                    }

                    // 发动机状态
                    Row {
                        spacing: s(20)
                        Text {
                            text: "发动机:"
                            font.pixelSize: s(22)
                            color: "#CCFFFFFF"
                            width: s(120)
                        }
                        Text {
                            text: engineRunning ? "运行中 🚀" : "已熄火 🔋"
                            font.pixelSize: s(22)
                            font.weight: Font.Medium
                            color: engineRunning ? "#4ade80" : "#94a3b8"
                        }
                    }

                    // 后备箱状态
                    Row {
                        spacing: s(20)
                        Text {
                            text: "后备箱:"
                            font.pixelSize: s(22)
                            color: "#CCFFFFFF"
                            width: s(120)
                        }
                        Text {
                            text: trunkOpen ? "打开 📦" : "关闭 📦"
                            font.pixelSize: s(22)
                            font.weight: Font.Medium
                            color: trunkOpen ? "#f97316" : "#4ade80"
                        }
                    }

                    // 车窗状态
                    Row {
                        spacing: s(20)
                        Text {
                            text: "车窗:"
                            font.pixelSize: s(22)
                            color: "#CCFFFFFF"
                            width: s(120)
                        }
                        Text {
                            text: windowsClosed ? "关闭 🪟" : "打开 🌬️"
                            font.pixelSize: s(22)
                            font.weight: Font.Medium
                            color: windowsClosed ? "#4ade80" : "#60a5fa"
                        }
                    }
                }

                // 底部状态提示
                Row {
                    spacing: s(14)
                    anchors.horizontalCenter: parent.horizontalCenter
                    Rectangle {
                        width: s(14)
                        height: s(14)
                        radius: s(7)
                        color: "#4ade80"

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 1000 }
                            NumberAnimation { to: 1.0; duration: 1000 }
                        }
                    }
                    Text {
                        text: "自动监控中"
                        font.pixelSize: s(16)  // 原13 → 16
                        color: "#B3FFFFFF"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        // 右侧 - 快捷控制区域
        Column {
            spacing: s(30)

            Text {
                text: "快捷控制"
                font.pixelSize: s(26)
                font.weight: Font.Medium
                font.letterSpacing: 4
                color: "#FFFFFF"
            }

            Grid {
                columns: 2
                columnSpacing: s(24)  // 增大水平间距
                rowSpacing: s(24)     // 增大垂直间距

                // 车门控制
                Rectangle {
                    width: root.width * 0.14
                    height: root.height * 0.20
                    radius: s(24)
                    color: doorArea.pressed ? "#33FFFFFF" : "#1AFFFFFF"
                    border.color: doorLocked ? "#667eea" : "#1AFFFFFF"
                    border.width: doorLocked ? 3 : 1

                    Behavior on border.color { ColorAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: s(16)

                        Text {
                            text: "🔐"
                            font.pixelSize: s(48)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: "车门"
                            font.pixelSize: s(22)
                            font.weight: Font.Medium
                            color: "#FFFFFF"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: doorLocked ? "已锁定" : "已解锁"
                            font.pixelSize: s(16)
                            color: doorLocked ? "#667eea" : "#99FFFFFF"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    MouseArea {
                        id: doorArea
                        anchors.fill: parent
                        onClicked: doorLocked = !doorLocked
                    }
                }

                // 车灯控制
                Rectangle {
                    width: root.width * 0.14
                    height: root.height * 0.20
                    radius: s(24)
                    color: lightsArea.pressed ? "#33FFFFFF" : "#1AFFFFFF"
                    border.color: lightsOn ? "#fbbf24" : "#1AFFFFFF"
                    border.width: lightsOn ? 3 : 1

                    Behavior on border.color { ColorAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: s(16)

                        Text {
                            text: "💡"
                            font.pixelSize: s(48)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: "车灯"
                            font.pixelSize: s(22)
                            font.weight: Font.Medium
                            color: "#FFFFFF"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: lightsOn ? "已开启" : "已关闭"
                            font.pixelSize: s(16)
                            color: lightsOn ? "#fbbf24" : "#99FFFFFF"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    MouseArea {
                        id: lightsArea
                        anchors.fill: parent
                        onClicked: lightsOn = !lightsOn
                    }
                }

                // 后备箱控制
                Rectangle {
                    width: root.width * 0.14
                    height: root.height * 0.20
                    radius: s(24)
                    color: trunkArea.pressed ? "#33FFFFFF" : "#1AFFFFFF"
                    border.color: trunkOpen ? "#f97316" : "#1AFFFFFF"
                    border.width: trunkOpen ? 3 : 1

                    Behavior on border.color { ColorAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: s(16)

                        Text {
                            text: "📦"
                            font.pixelSize: s(48)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: "后备箱"
                            font.pixelSize: s(22)
                            font.weight: Font.Medium
                            color: "#FFFFFF"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: trunkOpen ? "已打开" : "已关闭"
                            font.pixelSize: s(16)
                            color: trunkOpen ? "#f97316" : "#99FFFFFF"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    MouseArea {
                        id: trunkArea
                        anchors.fill: parent
                        onClicked: trunkOpen = !trunkOpen
                    }
                }

                // 车窗控制
                Rectangle {
                    width: root.width * 0.14
                    height: root.height * 0.20
                    radius: s(24)
                    color: windowsArea.pressed ? "#33FFFFFF" : "#1AFFFFFF"
                    border.color: !windowsClosed ? "#60a5fa" : "#1AFFFFFF"
                    border.width: !windowsClosed ? 3 : 1

                    Behavior on border.color { ColorAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: s(16)

                        Text {
                            text: "🪟"
                            font.pixelSize: s(48)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: "车窗"
                            font.pixelSize: s(22)
                            font.weight: Font.Medium
                            color: "#FFFFFF"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: windowsClosed ? "已关闭" : "已打开"
                            font.pixelSize: s(16)
                            color: !windowsClosed ? "#60a5fa" : "#99FFFFFF"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    MouseArea {
                        id: windowsArea
                        anchors.fill: parent
                        onClicked: windowsClosed = !windowsClosed
                    }
                }

                // 闪灯寻车
                Rectangle {
                    width: root.width * 0.14
                    height: root.height * 0.20
                    radius: s(24)
                    color: flashArea.pressed ? "#33FFFFFF" : "#1AFFFFFF"
                    border.color: flashlightOn ? "#ef4444" : "#1AFFFFFF"
                    border.width: flashlightOn ? 3 : 1

                    Behavior on border.color { ColorAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: s(16)

                        Text {
                            text: "🚨"
                            font.pixelSize: s(48)
                            anchors.horizontalCenter: parent.horizontalCenter

                            SequentialAnimation on opacity {
                                running: flashlightOn
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 300 }
                                NumberAnimation { to: 1.0; duration: 300 }
                            }
                        }
                        Text {
                            text: "闪灯"
                            font.pixelSize: s(22)
                            font.weight: Font.Medium
                            color: "#FFFFFF"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: flashlightOn ? "闪烁中" : "点击闪烁"
                            font.pixelSize: s(16)
                            color: flashlightOn ? "#ef4444" : "#99FFFFFF"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    MouseArea {
                        id: flashArea
                        anchors.fill: parent
                        onClicked: {
                            flashlightOn = !flashlightOn
                            if (flashlightOn) {
                                flashTimer.start()
                            } else {
                                flashTimer.stop()
                            }
                        }
                    }

                    Timer {
                        id: flashTimer
                        interval: 5000
                        onTriggered: flashlightOn = false
                    }
                }

                // 一键熄火
                Rectangle {
                    width: root.width * 0.14
                    height: root.height * 0.20
                    radius: s(24)
                    color: engineArea.pressed ? "#33FFFFFF" : "#1AFFFFFF"
                    border.color: engineRunning ? "#4ade80" : "#1AFFFFFF"
                    border.width: engineRunning ? 3 : 1

                    Behavior on border.color { ColorAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: s(16)

                        Text {
                            text: "🔑"
                            font.pixelSize: s(48)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: "一键熄火"
                            font.pixelSize: s(22)
                            font.weight: Font.Medium
                            color: "#FFFFFF"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: engineRunning ? "运行中" : "已熄火"
                            font.pixelSize: s(16)
                            color: engineRunning ? "#4ade80" : "#99FFFFFF"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    MouseArea {
                        id: engineArea
                        anchors.fill: parent
                        onClicked: engineRunning = !engineRunning
                    }
                }
            }
        }
    }
}
