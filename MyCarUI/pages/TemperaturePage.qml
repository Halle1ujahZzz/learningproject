import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    color: "transparent"

    property real sf: Math.min(width / 1920, height / 880)
    function s(v) { return v * sf }

    property int targetTemp: 24
    property int currentMode: 0
    property int fanLevel: 3
    property int driverSeatHeat: 0
    property int passengerSeatHeat: 0
    property bool acOn: false
    property bool autoModeOn: false
    property bool recycleOn: false
    property bool defogOn: false

    Row {
        anchors.fill: parent
        anchors.margins: s(20)
        spacing: s(25)

        // ========== 左侧：温度控制区 ==========
        Rectangle {
            width: parent.width * 0.42
            height: parent.height
            radius: s(28)
            color: "#0DFFFFFF"
            border.color: "#1AFFFFFF"
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: s(25)
                spacing: s(20)

                // 标题
                Text {
                    text: "温度控制"
                    font.pixelSize: s(26)
                    font.weight: Font.Medium
                    font.letterSpacing: 3
                    color: "#FFFFFF"
                }

                // 温度圆环 - 放大
                Item {
                    width: parent.width
                    height: parent.height * 0.52
                    anchors.horizontalCenter: parent.horizontalCenter

                    // 外层装饰环
                    Rectangle {
                        width: Math.min(parent.width * 0.88, parent.height * 0.98)
                        height: width
                        radius: width / 2
                        anchors.centerIn: parent
                        color: "transparent"
                        border.color: "#1A667eea"
                        border.width: s(25)
                    }

                    // 主圆环
                    Rectangle {
                        id: tempCircle
                        width: Math.min(parent.width * 0.72, parent.height * 0.82)
                        height: width
                        radius: width / 2
                        anchors.centerIn: parent
                        color: "transparent"
                        border.color: "#33FFFFFF"
                        border.width: s(5)

                        // 内部渐变背景
                        Rectangle {
                            width: parent.width - s(35)
                            height: width
                            radius: width / 2
                            anchors.centerIn: parent
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#1A667eea" }
                                GradientStop { position: 1.0; color: "#0D764ba2" }
                            }
                        }

                        // 温度显示
                        Column {
                            anchors.centerIn: parent
                            spacing: s(10)

                            // 当前温度
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter

                                Text {
                                    text: targetTemp
                                    font.pixelSize: tempCircle.width * 0.38
                                    font.weight: Font.Light
                                    color: "#FFFFFF"
                                }

                                Text {
                                    text: "°C"
                                    font.pixelSize: tempCircle.width * 0.14
                                    font.weight: Font.Light
                                    color: "#80FFFFFF"
                                    anchors.top: parent.top
                                    anchors.topMargin: s(12)
                                }
                            }

                            Text {
                                text: "目标温度"
                                font.pixelSize: s(18)
                                font.letterSpacing: 3
                                color: "#80FFFFFF"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            // 室内当前温度
                            Rectangle {
                                width: s(140)
                                height: s(42)
                                radius: s(21)
                                color: "#1AFFFFFF"
                                anchors.horizontalCenter: parent.horizontalCenter

                                Text {
                                    text: "室内 26°C"
                                    font.pixelSize: s(15)
                                    color: "#AAFFFFFF"
                                    anchors.centerIn: parent
                                }
                            }
                        }
                    }
                }

                // 温度调节按钮 - 放大
                Row {
                    spacing: s(50)
                    anchors.horizontalCenter: parent.horizontalCenter

                    // 减温按钮
                    Rectangle {
                        width: s(90)
                        height: s(90)
                        radius: width / 2
                        color: minusArea.pressed ? "#33FFFFFF" : "#1AFFFFFF"
                        border.color: "#33FFFFFF"
                        border.width: 2

                        Text {
                            text: "−"
                            font.pixelSize: s(50)
                            font.weight: Font.Light
                            color: "#FFFFFF"
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: -s(3)
                        }

                        MouseArea {
                            id: minusArea
                            anchors.fill: parent
                            onClicked: if (targetTemp > 16) targetTemp--
                        }

                        Timer {
                            interval: 150
                            running: minusArea.pressed
                            repeat: true
                            onTriggered: if (targetTemp > 16) targetTemp--
                        }
                    }

                    // 温度范围指示
                    Column {
                        spacing: s(6)
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: "16°"
                            font.pixelSize: s(14)
                            color: "#66FFFFFF"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Rectangle {
                            width: s(6)
                            height: s(50)
                            radius: s(3)
                            color: "#33FFFFFF"
                            anchors.horizontalCenter: parent.horizontalCenter

                            Rectangle {
                                width: parent.width
                                height: parent.height * ((targetTemp - 16) / 16)
                                radius: s(3)
                                color: "#667eea"
                                anchors.bottom: parent.bottom
                            }
                        }

                        Text {
                            text: "32°"
                            font.pixelSize: s(14)
                            color: "#66FFFFFF"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    // 加温按钮
                    Rectangle {
                        width: s(90)
                        height: s(90)
                        radius: width / 2
                        color: plusArea.pressed ? "#33FFFFFF" : "#1AFFFFFF"
                        border.color: "#33FFFFFF"
                        border.width: 2

                        Text {
                            text: "+"
                            font.pixelSize: s(44)
                            font.weight: Font.Light
                            color: "#FFFFFF"
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: plusArea
                            anchors.fill: parent
                            onClicked: if (targetTemp < 32) targetTemp++
                        }

                        Timer {
                            interval: 150
                            running: plusArea.pressed
                            repeat: true
                            onTriggered: if (targetTemp < 32) targetTemp++
                        }
                    }
                }

                // 快捷温度 - 放大
                Row {
                    spacing: s(18)
                    anchors.horizontalCenter: parent.horizontalCenter

                    Repeater {
                        model: [18, 22, 24, 26]

                        Rectangle {
                            width: s(75)
                            height: s(52)
                            radius: s(14)
                            color: targetTemp === modelData ? "#4D667eea" : "#14FFFFFF"
                            border.color: targetTemp === modelData ? "#667eea" : "#26FFFFFF"
                            border.width: 1

                            Text {
                                text: modelData + "°"
                                font.pixelSize: s(20)
                                font.weight: targetTemp === modelData ? Font.Medium : Font.Normal
                                color: targetTemp === modelData ? "#FFFFFF" : "#AAFFFFFF"
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: targetTemp = modelData
                            }
                        }
                    }
                }
            }
        }

        // ========== 右侧：设置区 ==========
        Column {
            width: parent.width * 0.54
            height: parent.height
            spacing: s(18)

            // 模式选择 - 放大
            Rectangle {
                width: parent.width
                height: parent.height * 0.3
                radius: s(28)
                color: "#0DFFFFFF"
                border.color: "#1AFFFFFF"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: s(22)
                    spacing: s(18)

                    Text {
                        text: "空调模式"
                        font.pixelSize: s(24)
                        font.weight: Font.Medium
                        font.letterSpacing: 2
                        color: "#FFFFFF"
                    }

                    Row {
                        spacing: s(18)
                        anchors.horizontalCenter: parent.horizontalCenter

                        Repeater {
                            model: [
                                { name: "自动", icon: "🔄", desc: "智能调节" },
                                { name: "制冷", icon: "❄️", desc: "降温模式" },
                                { name: "制热", icon: "🔥", desc: "升温模式" },
                                { name: "送风", icon: "💨", desc: "通风换气" }
                            ]

                            Rectangle {
                                width: s(150)
                                height: s(105)
                                radius: s(18)
                                color: currentMode === index ? "#33667eea" : "#14FFFFFF"
                                border.color: currentMode === index ? "#667eea" : "#26FFFFFF"
                                border.width: currentMode === index ? 2 : 1

                                Column {
                                    anchors.centerIn: parent
                                    spacing: s(8)

                                    Text {
                                        text: modelData.icon
                                        font.pixelSize: s(34)
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Text {
                                        text: modelData.name
                                        font.pixelSize: s(17)
                                        font.weight: Font.Medium
                                        color: currentMode === index ? "#FFFFFF" : "#CCFFFFFF"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Text {
                                        text: modelData.desc
                                        font.pixelSize: s(11)
                                        color: "#66FFFFFF"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: currentMode = index
                                }
                            }
                        }
                    }
                }
            }

            // 风量控制 - 放大
            Rectangle {
                width: parent.width
                height: parent.height * 0.22
                radius: s(28)
                color: "#0DFFFFFF"
                border.color: "#1AFFFFFF"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: s(22)
                    spacing: s(16)

                    Row {
                        width: parent.width

                        Text {
                            text: "风量控制"
                            font.pixelSize: s(24)
                            font.weight: Font.Medium
                            font.letterSpacing: 2
                            color: "#FFFFFF"
                        }

                        Item { width: parent.width - s(240); height: 1 }

                        Text {
                            text: fanLevel + " 档"
                            font.pixelSize: s(22)
                            font.weight: Font.Medium
                            color: "#667eea"
                        }
                    }

                    // 风量滑块 - 放大
                    Row {
                        spacing: s(16)
                        anchors.horizontalCenter: parent.horizontalCenter

                        Text {
                            text: "💨"
                            font.pixelSize: s(28)
                            opacity: 0.5
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Row {
                            spacing: s(10)
                            anchors.verticalCenter: parent.verticalCenter

                            Repeater {
                                model: 7

                                Rectangle {
                                    width: s(70)
                                    height: s(16) + index * s(5)
                                    radius: s(8)
                                    color: index < fanLevel ? "#667eea" : "#26FFFFFF"
                                    anchors.bottom: parent.bottom

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: fanLevel = index + 1
                                    }

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }
                        }

                        Text {
                            text: "💨"
                            font.pixelSize: s(36)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // 座椅加热 & 快捷开关
            Row {
                width: parent.width
                height: parent.height * 0.43
                spacing: s(18)

                // 座椅加热 - 放大
                Rectangle {
                    width: parent.width * 0.56
                    height: parent.height
                    radius: s(28)
                    color: "#0DFFFFFF"
                    border.color: "#1AFFFFFF"
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: s(22)
                        spacing: s(18)

                        Text {
                            text: "座椅加热"
                            font.pixelSize: s(24)
                            font.weight: Font.Medium
                            font.letterSpacing: 2
                            color: "#FFFFFF"
                        }

                        Row {
                            spacing: s(30)
                            anchors.horizontalCenter: parent.horizontalCenter

                            // 主驾驶
                            Rectangle {
                                width: s(175)
                                height: s(155)
                                radius: s(22)
                                color: driverSeatHeat > 0 ? "#26f59e0b" : "#14FFFFFF"
                                border.color: driverSeatHeat > 0 ? "#4Df59e0b" : "#26FFFFFF"
                                border.width: 1

                                Column {
                                    anchors.centerIn: parent
                                    spacing: s(14)

                                    Text {
                                        text: "🪑"
                                        font.pixelSize: s(44)
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Text {
                                        text: "主驾驶"
                                        font.pixelSize: s(16)
                                        font.weight: Font.Medium
                                        color: "#FFFFFF"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Row {
                                        spacing: s(10)
                                        anchors.horizontalCenter: parent.horizontalCenter

                                        Repeater {
                                            model: 3

                                            Rectangle {
                                                width: s(30)
                                                height: s(30)
                                                radius: s(15)
                                                color: index < driverSeatHeat ? "#f59e0b" : "#26FFFFFF"
                                                border.color: index < driverSeatHeat ? "#f59e0b" : "#33FFFFFF"
                                                border.width: 1

                                                Text {
                                                    text: index + 1
                                                    font.pixelSize: s(14)
                                                    color: index < driverSeatHeat ? "#FFFFFF" : "#66FFFFFF"
                                                    anchors.centerIn: parent
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: driverSeatHeat = (driverSeatHeat === index + 1) ? 0 : index + 1
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // 副驾驶
                            Rectangle {
                                width: s(175)
                                height: s(155)
                                radius: s(22)
                                color: passengerSeatHeat > 0 ? "#26f59e0b" : "#14FFFFFF"
                                border.color: passengerSeatHeat > 0 ? "#4Df59e0b" : "#26FFFFFF"
                                border.width: 1

                                Column {
                                    anchors.centerIn: parent
                                    spacing: s(14)

                                    Text {
                                        text: "🪑"
                                        font.pixelSize: s(44)
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Text {
                                        text: "副驾驶"
                                        font.pixelSize: s(16)
                                        font.weight: Font.Medium
                                        color: "#FFFFFF"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Row {
                                        spacing: s(10)
                                        anchors.horizontalCenter: parent.horizontalCenter

                                        Repeater {
                                            model: 3

                                            Rectangle {
                                                width: s(30)
                                                height: s(30)
                                                radius: s(15)
                                                color: index < passengerSeatHeat ? "#f59e0b" : "#26FFFFFF"
                                                border.color: index < passengerSeatHeat ? "#f59e0b" : "#33FFFFFF"
                                                border.width: 1

                                                Text {
                                                    text: index + 1
                                                    font.pixelSize: s(14)
                                                    color: index < passengerSeatHeat ? "#FFFFFF" : "#66FFFFFF"
                                                    anchors.centerIn: parent
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: passengerSeatHeat = (passengerSeatHeat === index + 1) ? 0 : index + 1
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // 快捷开关 - 放大
                Rectangle {
                    width: parent.width * 0.40
                    height: parent.height
                    radius: s(28)
                    color: "#0DFFFFFF"
                    border.color: "#1AFFFFFF"
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: s(22)
                        spacing: s(16)

                        Text {
                            text: "快捷开关"
                            font.pixelSize: s(24)
                            font.weight: Font.Medium
                            font.letterSpacing: 2
                            color: "#FFFFFF"
                        }

                        Grid {
                            columns: 2
                            spacing: s(14)
                            anchors.horizontalCenter: parent.horizontalCenter

                            // A/C 开关
                            Rectangle {
                                width: s(115)
                                height: s(85)
                                radius: s(16)
                                color: acOn ? "#33667eea" : "#14FFFFFF"
                                border.color: acOn ? "#667eea" : "#26FFFFFF"
                                border.width: acOn ? 2 : 1

                                Column {
                                    anchors.centerIn: parent
                                    spacing: s(8)

                                    Text {
                                        text: "❄️"
                                        font.pixelSize: s(28)
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Text {
                                        text: "A/C"
                                        font.pixelSize: s(15)
                                        font.weight: acOn ? Font.Medium : Font.Normal
                                        color: acOn ? "#667eea" : "#AAFFFFFF"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: acOn = !acOn
                                }
                            }

                            // AUTO 开关
                            Rectangle {
                                width: s(115)
                                height: s(85)
                                radius: s(16)
                                color: autoModeOn ? "#33667eea" : "#14FFFFFF"
                                border.color: autoModeOn ? "#667eea" : "#26FFFFFF"
                                border.width: autoModeOn ? 2 : 1

                                Column {
                                    anchors.centerIn: parent
                                    spacing: s(8)

                                    Text {
                                        text: "🔄"
                                        font.pixelSize: s(28)
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Text {
                                        text: "AUTO"
                                        font.pixelSize: s(15)
                                        font.weight: autoModeOn ? Font.Medium : Font.Normal
                                        color: autoModeOn ? "#667eea" : "#AAFFFFFF"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: autoModeOn = !autoModeOn
                                }
                            }

                            // 内循环开关
                            Rectangle {
                                width: s(115)
                                height: s(85)
                                radius: s(16)
                                color: recycleOn ? "#33667eea" : "#14FFFFFF"
                                border.color: recycleOn ? "#667eea" : "#26FFFFFF"
                                border.width: recycleOn ? 2 : 1

                                Column {
                                    anchors.centerIn: parent
                                    spacing: s(8)

                                    Text {
                                        text: "🔃"
                                        font.pixelSize: s(28)
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Text {
                                        text: "内循环"
                                        font.pixelSize: s(15)
                                        font.weight: recycleOn ? Font.Medium : Font.Normal
                                        color: recycleOn ? "#667eea" : "#AAFFFFFF"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: recycleOn = !recycleOn
                                }
                            }

                            // 除雾开关
                            Rectangle {
                                width: s(115)
                                height: s(85)
                                radius: s(16)
                                color: defogOn ? "#33667eea" : "#14FFFFFF"
                                border.color: defogOn ? "#667eea" : "#26FFFFFF"
                                border.width: defogOn ? 2 : 1

                                Column {
                                    anchors.centerIn: parent
                                    spacing: s(8)

                                    Text {
                                        text: "💧"
                                        font.pixelSize: s(28)
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Text {
                                        text: "除雾"
                                        font.pixelSize: s(15)
                                        font.weight: defogOn ? Font.Medium : Font.Normal
                                        color: defogOn ? "#667eea" : "#AAFFFFFF"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: defogOn = !defogOn
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
