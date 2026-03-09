import QtQuick
import QtQuick.Controls

Item {
    id: root

    // 重要：定义信号
    signal enterSubPage(int pageIndex)

    readonly property real scaleFactor: Math.min(width / 1920, height / 1080)
    function s(value) { return value * scaleFactor }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: currentTime = Qt.formatTime(new Date(), "HH:mm")
    }

    property string currentTime: ""

    // 顶部状态栏
    Item {
        id: topBar
        width: parent.width
        height: s(50)
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.02

        Text {
            text: currentTime
            font.pixelSize: s(22)
            font.weight: Font.Medium
            font.letterSpacing: 2
            color: "#FFFFFF"
            anchors.left: parent.left
            anchors.leftMargin: parent.width * 0.03
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: "C A R O S"
            font.pixelSize: s(16)
            font.weight: Font.Light
            font.letterSpacing: 8
            color: "#99FFFFFF"
            anchors.centerIn: parent
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: parent.width * 0.03
            anchors.verticalCenter: parent.verticalCenter
            spacing: s(25)

            Row {
                spacing: s(6)
                Text { text: "📶"; font.pixelSize: s(14) }
                Text { text: "5G"; font.pixelSize: s(13); color: "#B3FFFFFF"; anchors.verticalCenter: parent.verticalCenter }
            }

            Row {
                spacing: s(6)
                Text { text: "🔋"; font.pixelSize: s(14) }
                Text {
                    text: SerialHandler.connected ? SerialHandler.batteryLevel + "%" : "--%"
                    font.pixelSize: s(13)
                    color: "#4ade80"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                spacing: s(6)
                Text { text: "🌡"; font.pixelSize: s(14) }
                Text {
                    text: SerialHandler.connected ? SerialHandler.temperature + "°" : "--°"
                    font.pixelSize: s(13)
                    color: "#B3FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // 欢迎语
    Column {
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.035
        anchors.top: topBar.bottom
        anchors.topMargin: parent.height * 0.04
        spacing: s(8)

        Text {
            text: {
                var hour = new Date().getHours();
                if (hour < 6) return "凌晨好";
                else if (hour < 9) return "早上好";
                else if (hour < 12) return "上午好";
                else if (hour < 14) return "中午好";
                else if (hour < 18) return "下午好";
                else return "晚上好";
            }
            font.pixelSize: s(38)
            font.weight: Font.Light
            color: "#FFFFFF"
        }

        Text {
            text: "今天是个驾驶的好日子"
            font.pixelSize: s(14)
            color: "#80FFFFFF"
            font.letterSpacing: 1
        }
    }

    // 中央卡片区域
    Row {
        id: cardArea
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.2
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: parent.width * 0.012

        // 音乐卡片
        Rectangle {
            width: root.width * 0.2
            height: root.height * 0.28
            radius: s(20)
            color: "#14FFFFFF"
            border.color: "#1FFFFFFF"
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: s(16)

                Text {
                    text: "🎵"
                    font.pixelSize: s(72)
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "音乐"
                    font.pixelSize: s(24)
                    font.weight: Font.Medium
                    color: "#FFFFFF"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "点击进入播放器"
                    font.pixelSize: s(14)
                    color: "#80FFFFFF"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.enterSubPage(3)
            }
        }

        // 导航卡片
        Rectangle {
            width: root.width * 0.2
            height: root.height * 0.28
            radius: s(20)
            color: "#14FFFFFF"
            border.color: "#1FFFFFFF"
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: s(16)

                Text {
                    text: "🧭"
                    font.pixelSize: s(72)
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "导航"
                    font.pixelSize: s(24)
                    font.weight: Font.Medium
                    color: "#FFFFFF"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "点击规划路线"
                    font.pixelSize: s(14)
                    color: "#80FFFFFF"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.enterSubPage(0)
            }
        }

        // AI助手卡片
        Rectangle {
            width: root.width * 0.2
            height: root.height * 0.28
            radius: s(20)
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#33667eea" }
                GradientStop { position: 1.0; color: "#33764ba2" }
            }

            Column {
                anchors.centerIn: parent
                spacing: s(14)

                Text {
                    text: "🤖"
                    font.pixelSize: s(64)
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "AI 助手"
                    font.pixelSize: s(24)
                    font.weight: Font.Medium
                    color: "#FFFFFF"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "你好，有什么可以帮您？"
                    font.pixelSize: s(15)
                    color: "#CCFFFFFF"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "语音唤醒：\"你好，小助手\""
                    font.pixelSize: s(12)
                    color: "#99FFFFFF"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        // 天气卡片
        Rectangle {
            width: root.width * 0.2
            height: root.height * 0.28
            radius: s(20)
            color: "#14FFFFFF"
            border.color: "#1FFFFFFF"
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: s(12)

                Text {
                    text: {
                        if (!SerialHandler.weatherReceived) return "⏳"
                        switch(SerialHandler.weatherType) {
                            case "sunny": return "☀️"
                            case "cloudy": return "☁️"
                            case "rainy": return "🌧️"
                            default: return "❓"
                        }
                    }
                    font.pixelSize: s(80)
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: SerialHandler.weatherReceived ? SerialHandler.temperature + "°" : "--°"
                    font.pixelSize: s(40)
                    font.weight: Font.Light
                    color: "#FFFFFF"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: {
                        if (!SerialHandler.weatherReceived) return "加载中..."
                        switch(SerialHandler.weatherType) {
                            case "sunny": return "晴朗"
                            case "cloudy": return "多云"
                            case "rainy": return "小雨"
                            default: return "未知"
                        }
                    }
                    font.pixelSize: s(16)
                    color: "#99FFFFFF"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: SerialHandler.weatherReceived
                          ? "体感 " + SerialHandler.perceivedTemperature + "° · 湿度 " + SerialHandler.humidity + "%"
                          : "获取天气信息中"
                    font.pixelSize: s(12)
                    color: "#80FFFFFF"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    // 底部菜单栏
    Rectangle {
        id: bottomMenu
        width: parent.width
        height: s(110)
        anchors.bottom: parent.bottom
        color: "#E6151520"

        Rectangle {
            anchors.fill: parent
            color: "#CC1a1a2e"
        }

        Rectangle {
            width: parent.width - s(80)
            height: 1
            color: "#40FFFFFF"
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Row {
            anchors.centerIn: parent
            spacing: s(35)

            Repeater {
                model: [
                    { name: "导航", icon: "🧭", idx: 0 },
                    { name: "车控", icon: "🚗", idx: 1 },
                    { name: "温控", icon: "❄️", idx: 2 },
                    { name: "音乐", icon: "🎵", idx: 3 },
                    { name: "历史", icon: "📋", idx: 4 }
                ]

                Rectangle {
                    width: s(165)
                    height: s(72)
                    radius: s(16)
                    color: menuArea.pressed ? "#26FFFFFF" : "#14FFFFFF"
                    border.color: menuArea.containsMouse ? "#40FFFFFF" : "#1AFFFFFF"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: s(14)

                        Rectangle {
                            width: s(40)
                            height: s(40)
                            radius: width / 2
                            color: "#26667eea"
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: modelData.icon
                                font.pixelSize: s(20)
                                anchors.centerIn: parent
                            }
                        }

                        Text {
                            text: modelData.name
                            font.pixelSize: s(18)
                            font.weight: Font.Medium
                            color: "#FFFFFF"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: menuArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.enterSubPage(modelData.idx)
                    }
                }
            }
        }
    }

    // 左侧滑动提示
    Column {
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.03
        anchors.verticalCenter: parent.verticalCenter
        spacing: s(16)
        opacity: 0.6

        Text {
            text: "‹"
            font.pixelSize: s(48)  // 与右滑箭头大小一致
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
                NumberAnimation { to: -s(8); duration: 600; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 0; duration: 600; easing.type: Easing.InOutQuad }
            }
        }

        Text {
            text: "滑动"
            font.pixelSize: s(16)  // 与右滑提示文字大小一致
            font.letterSpacing: 2
            color: "#80FFFFFF"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
