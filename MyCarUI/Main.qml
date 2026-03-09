import QtQuick
import QtQuick.Controls
import "pages" as Pages

ApplicationWindow {
    id: window
    width: 1280
    height: 720
    minimumWidth: 960
    minimumHeight: 540
    visible: true
    title: "CarOS"

    readonly property real designWidth: 1920
    readonly property real designHeight: 1080
    readonly property real scaleFactor: Math.min(width / designWidth, height / designHeight)

    function s(value) { return value * scaleFactor }

    QtObject {
        id: appState
        property int currentSubPageIndex: 0
    }

    Connections {
        target: SerialHandler

        function onReverseStateChanged(isReverse) {
            console.log("Reverse state:", isReverse)
            if (isReverse) {
                mainStack.push(reversePageComponent)
            } else {
                if (mainStack.depth > 1 && mainStack.currentItem.objectName === "reversePage") {
                    mainStack.pop()
                }
            }
        }

        function onWeatherDataChanged() {
            console.log("Weather data changed!")
        }

        function onErrorOccurred(error) {
            console.log("Serial error:", error)
        }
    }

    Component {
        id: reversePageComponent
        Pages.ReversePage {
            objectName: "reversePage"
        }
    }

    // 星空背景
    Rectangle {
        id: skyBackground
        anchors.fill: parent

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0F0C29" }
            GradientStop { position: 0.5; color: "#302B63" }
            GradientStop { position: 1.0; color: "#24243E" }
        }

        Repeater {
            model: 80

            Rectangle {
                property real randX: Math.random()
                property real randY: Math.random()
                property real starSize: Math.random() * 2 + 1
                property real baseOpacity: Math.random() * 0.5 + 0.2

                x: randX * window.width
                y: randY * window.height
                width: starSize
                height: starSize
                radius: starSize / 2
                color: "#FFFFFF"
                opacity: baseOpacity

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: baseOpacity * 0.3; duration: 1500 + Math.random() * 1500 }
                    NumberAnimation { to: baseOpacity; duration: 1500 + Math.random() * 1500 }
                }
            }
        }

        Rectangle {
            width: window.width * 0.4
            height: window.width * 0.4
            radius: width / 2
            x: -width * 0.3
            y: -height * 0.3
            opacity: 0.12
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#667eea" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Rectangle {
            width: window.width * 0.3
            height: window.width * 0.3
            radius: width / 2
            x: window.width - width * 0.7
            y: window.height - height * 0.5
            opacity: 0.08
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#f093fb" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    // 连接状态指示器
    Rectangle {
        width: s(12)
        height: s(12)
        radius: width / 2
        color: SerialHandler.connected ? "#4ade80" : "#ef4444"
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: s(20)
        z: 1000

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: !SerialHandler.connected
            NumberAnimation { to: 0.3; duration: 500 }
            NumberAnimation { to: 1.0; duration: 500 }
        }
    }

    StackView {
        id: mainStack
        anchors.fill: parent
        initialItem: mainSwipeViewComponent

        pushEnter: Transition {
            PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 250 }
        }
        pushExit: Transition {
            PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 250 }
        }
        popEnter: Transition {
            PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 250 }
        }
        popExit: Transition {
            PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 250 }
        }
    }

    Component {
        id: mainSwipeViewComponent

        Item {
            anchors.fill: parent

            SwipeView {
                id: rootSwipe
                anchors.fill: parent
                currentIndex: 0
                interactive: true
                clip: true

                Item {
                    Pages.InstrumentPage {
                        anchors.fill: parent
                    }
                }

                Item {
                    Pages.HomePage {
                        id: homePage
                        anchors.fill: parent
                    }

                    Connections {
                        target: homePage
                        function onEnterSubPage(pageIndex) {
                            appState.currentSubPageIndex = pageIndex
                            mainStack.push(subPagesComponent)
                        }
                    }
                }
            }

            Row {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: window.s(25)
                spacing: window.s(10)
                z: 100

                Repeater {
                    model: 2

                    Rectangle {
                        width: rootSwipe.currentIndex === index ? window.s(28) : window.s(10)
                        height: window.s(10)
                        radius: height / 2
                        color: rootSwipe.currentIndex === index ? "#FFFFFF" : "#55FFFFFF"

                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
            }
        }
    }

    // 副界面 - 恢复 SwipeView 滑动功能
    Component {
        id: subPagesComponent

        Item {
            id: subPageRoot
            anchors.fill: parent

            // 返回按钮
            Rectangle {
                id: backBtn
                width: window.s(52)
                height: window.s(52)
                radius: width / 2
                color: backArea.pressed ? "#33FFFFFF" : "#1AFFFFFF"
                border.color: "#33FFFFFF"
                border.width: 1
                z: 100
                x: window.s(28)
                y: window.s(28)

                Text {
                    text: "←"
                    font.pixelSize: window.s(22)
                    font.weight: Font.Light
                    color: "#FFFFFF"
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: backArea
                    anchors.fill: parent
                    onClicked: mainStack.pop()
                }
            }

            // 页面标题
            Text {
                id: pageTitleText
                text: {
                    var titles = ["导航", "车辆控制", "空调温控", "音乐播放", "历史行程"]
                    return titles[subSwipe.currentIndex] || ""
                }
                font.pixelSize: window.s(20)
                font.weight: Font.Medium
                font.letterSpacing: 3
                color: "#FFFFFF"
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: window.s(36)
                z: 100
            }

            // SwipeView - 支持滑动切换
            SwipeView {
                id: subSwipe
                anchors.top: parent.top
                anchors.topMargin: window.s(90)
                anchors.bottom: bottomNav.top
                anchors.left: parent.left
                anchors.right: parent.right
                currentIndex: appState.currentSubPageIndex
                clip: true
                interactive: true  // 启用滑动

                // 每个页面用 Item 包裹，确保尺寸正确传递
                Item {
                    property real pageWidth: subSwipe.width
                    property real pageHeight: subSwipe.height

                    Pages.NavigationPage {
                        width: parent.pageWidth
                        height: parent.pageHeight
                    }
                }

                Item {
                    property real pageWidth: subSwipe.width
                    property real pageHeight: subSwipe.height

                    Pages.VehicleControlPage {
                        width: parent.pageWidth
                        height: parent.pageHeight
                    }
                }

                Item {
                    property real pageWidth: subSwipe.width
                    property real pageHeight: subSwipe.height

                    Pages.TemperaturePage {
                        width: parent.pageWidth
                        height: parent.pageHeight
                    }
                }

                Item {
                    property real pageWidth: subSwipe.width
                    property real pageHeight: subSwipe.height

                    Pages.MusicPage {
                        width: parent.pageWidth
                        height: parent.pageHeight
                    }
                }

                Item {
                    property real pageWidth: subSwipe.width
                    property real pageHeight: subSwipe.height

                    Pages.HistoryPage {
                        width: parent.pageWidth
                        height: parent.pageHeight
                    }
                }

                onCurrentIndexChanged: {
                    appState.currentSubPageIndex = currentIndex
                }
            }

            // 底部导航栏（删除图标，只保留文字，文字整体居中并放大）
            Rectangle {
                id: bottomNav
                width: parent.width
                height: window.s(90)
                anchors.bottom: parent.bottom
                color: "#CC1a1a2e"

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#40FFFFFF"
                }

                Row {
                    anchors.centerIn: parent
                    spacing: window.s(70)

                    Repeater {
                        model: [
                            { name: "导航" },
                            { name: "车控" },
                            { name: "温控" },
                            { name: "音乐" },
                            { name: "历史" }
                        ]

                        Item {
                            width: window.s(120)
                            height: window.s(60)

                            property bool isActive: subSwipe.currentIndex === index

                            Rectangle {
                                anchors.fill: parent
                                radius: window.s(18)
                                color: isActive ? "#40FFFFFF" : "transparent"
                                border.color: isActive ? "#66FFFFFF" : "transparent"
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    text: modelData.name
                                    font.pixelSize: window.s(20)
                                    font.letterSpacing: 2
                                    font.weight: isActive ? Font.Medium : Font.Normal
                                    color: isActive ? "#FFFFFF" : "#AAFFFFFF"
                                    anchors.centerIn: parent
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: subSwipe.currentIndex = index
                            }
                        }
                    }
                }
            }
        }
    }
}
