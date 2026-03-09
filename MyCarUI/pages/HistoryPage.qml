import QtQuick
import QtQuick.Controls

Item {
    id: root

    width: parent ? parent.width : 800
    height: parent ? parent.height : 600

    readonly property real scaleFactor: (width > 0 && height > 0) ? Math.min(width / 1920, height / 880) : 0.5
    function s(value) { return value * scaleFactor }

    // 筛选和排序状态
    //property string filterType: "all"
    //property string sortOrder: "desc"

    // 统计数据属性
    property real totalDistance: 0
    property real totalTime: 0
    property real avgSpeed: 0
    property int tripCount: 0

    // 格式化数字为千分位
    function formatNumber(num) {
        if (num >= 1000) {
            return num.toFixed(0).replace(/\B(?=(\d{3})+(?!\d))/g, ",")
        }
        return num.toFixed(1)
    }

    // 更新统计数据
    function updateStats() {
        if (!historyDB || historyDB.count() === 0) {
            totalDistance = 0
            totalTime = 0
            avgSpeed = 0
            tripCount = 0
            return
        }

        totalDistance = historyDB.getTotalDistance()
        totalTime = historyDB.getTotalTime()
        avgSpeed = historyDB.getAverageSpeed()
        tripCount = historyDB.count()
    }

    // 左侧统计面板
    Rectangle {
        id: leftPanel
        width: root.width * 0.22
        height: root.height - s(50)
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: s(25)
        radius: s(20)
        color: "#0DFFFFFF"
        border.color: "#1AFFFFFF"
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: s(24)
            spacing: s(20)

            Text {
                text: "本月统计"
                font.pixelSize: s(24)
                font.weight: Font.Medium
                font.letterSpacing: 2
                color: "#FFFFFF"
            }

            // 统计卡片 - 使用真实数据
            Column {
                width: parent.width
                spacing: s(16)

                // 总里程
                Rectangle {
                    width: parent.width
                    height: s(90)
                    radius: s(16)
                    color: "#14FFFFFF"
                    border.color: "#1AFFFFFF"
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: s(18)
                        spacing: s(14)

                        Rectangle {
                            width: s(50)
                            height: s(50)
                            radius: s(25)
                            color: "#667eea"
                            opacity: 0.2
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                width: s(26)
                                height: s(26)
                                radius: s(13)
                                color: "#667eea"
                                anchors.centerIn: parent
                            }
                        }

                        Column {
                            spacing: s(6)
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: "总里程"
                                font.pixelSize: s(15)
                                color: "#80FFFFFF"
                            }

                            Row {
                                spacing: s(8)

                                Text {
                                    text: formatNumber(totalDistance)
                                    font.pixelSize: s(24)
                                    font.weight: Font.Medium
                                    color: "#FFFFFF"
                                }

                                Text {
                                    text: "km"
                                    font.pixelSize: s(14)
                                    color: "#80FFFFFF"
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: s(3)
                                }
                            }
                        }
                    }
                }

                // 驾驶时长
                Rectangle {
                    width: parent.width
                    height: s(90)
                    radius: s(16)
                    color: "#14FFFFFF"
                    border.color: "#1AFFFFFF"
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: s(18)
                        spacing: s(14)

                        Rectangle {
                            width: s(50)
                            height: s(50)
                            radius: s(25)
                            color: "#f093fb"
                            opacity: 0.2
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                width: s(26)
                                height: s(26)
                                radius: s(13)
                                color: "#f093fb"
                                anchors.centerIn: parent
                            }
                        }

                        Column {
                            spacing: s(6)
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: "驾驶时长"
                                font.pixelSize: s(15)
                                color: "#80FFFFFF"
                            }

                            Row {
                                spacing: s(8)

                                Text {
                                    text: totalTime.toFixed(1)
                                    font.pixelSize: s(24)
                                    font.weight: Font.Medium
                                    color: "#FFFFFF"
                                }

                                Text {
                                    text: "小时"
                                    font.pixelSize: s(14)
                                    color: "#80FFFFFF"
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: s(3)
                                }
                            }
                        }
                    }
                }

                // 平均速度
                Rectangle {
                    width: parent.width
                    height: s(90)
                    radius: s(16)
                    color: "#14FFFFFF"
                    border.color: "#1AFFFFFF"
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: s(18)
                        spacing: s(14)

                        Rectangle {
                            width: s(50)
                            height: s(50)
                            radius: s(25)
                            color: "#4ade80"
                            opacity: 0.2
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                width: s(26)
                                height: s(26)
                                radius: s(13)
                                color: "#4ade80"
                                anchors.centerIn: parent
                            }
                        }

                        Column {
                            spacing: s(6)
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: "平均速度"
                                font.pixelSize: s(15)
                                color: "#80FFFFFF"
                            }

                            Row {
                                spacing: s(8)

                                Text {
                                    text: avgSpeed.toFixed(0)
                                    font.pixelSize: s(24)
                                    font.weight: Font.Medium
                                    color: "#FFFFFF"
                                }

                                Text {
                                    text: "km/h"
                                    font.pixelSize: s(14)
                                    color: "#80FFFFFF"
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: s(3)
                                }
                            }
                        }
                    }
                }

                // 行程次数
                Rectangle {
                    width: parent.width
                    height: s(90)
                    radius: s(16)
                    color: "#14FFFFFF"
                    border.color: "#1AFFFFFF"
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: s(18)
                        spacing: s(14)

                        Rectangle {
                            width: s(50)
                            height: s(50)
                            radius: s(25)
                            color: "#fbbf24"
                            opacity: 0.2
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                width: s(26)
                                height: s(26)
                                radius: s(13)
                                color: "#fbbf24"
                                anchors.centerIn: parent
                            }
                        }

                        Column {
                            spacing: s(6)
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: "行程次数"
                                font.pixelSize: s(15)
                                color: "#80FFFFFF"
                            }

                            Row {
                                spacing: s(8)

                                Text {
                                    text: tripCount.toString()
                                    font.pixelSize: s(24)
                                    font.weight: Font.Medium
                                    color: "#FFFFFF"
                                }

                                Text {
                                    text: "次"
                                    font.pixelSize: s(14)
                                    color: "#80FFFFFF"
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: s(3)
                                }
                            }
                        }
                    }
                }
            }

            // 操作按钮
            Rectangle {
                width: parent.width
                height: s(52)
                radius: s(12)
                color: historyDB && historyDB.count() > 0 ? "#ef4444" : "#33FFFFFF"
                border.color: historyDB && historyDB.count() > 0 ? "#ff0000" : "#44FFFFFF"
                border.width: 1
                opacity: clearBtnMouseArea.pressed ? 0.8 : 1.0

                Text {
                    text: "清空历史记录"
                    font.pixelSize: s(16)
                    font.weight: Font.Medium
                    color: "#FFFFFF"
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: clearBtnMouseArea
                    anchors.fill: parent
                    enabled: historyDB && historyDB.count() > 0
                    onClicked: {
                        deleteConfirmDialog.open()
                    }
                }
            }
        }
    }

    // 右侧历史记录列表
    Rectangle {
        anchors.left: leftPanel.right
        anchors.leftMargin: s(20)
        anchors.right: parent.right
        anchors.rightMargin: s(25)
        anchors.top: parent.top
        anchors.topMargin: s(25)
        height: root.height - s(50)
        radius: s(20)
        color: "#0DFFFFFF"
        border.color: "#1AFFFFFF"
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: s(24)
            spacing: s(20)

            // 标题栏
            Row {
                width: parent.width
                spacing: s(12)

                Text {
                    text: "行程历史"
                    font.pixelSize: s(24)
                    font.weight: Font.Medium
                    font.letterSpacing: 2
                    color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: s(100)
                    height: s(32)
                    radius: s(16)
                    color: "#14FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: (historyDB ? historyDB.count() : 0) + " 条记录"
                        font.pixelSize: s(14)
                        color: "#80FFFFFF"
                        anchors.centerIn: parent
                    }
                }
            }

            // 历史记录列表
            ListView {
                id: historyListView
                width: parent.width
                height: parent.height - s(60)
                spacing: s(12)
                clip: true
                model: historyDB

                delegate: Rectangle {
                    width: ListView.view.width
                    height: s(85)
                    radius: s(16)
                    color: "#14FFFFFF"
                    border.color: "#1AFFFFFF"
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: s(18)
                        spacing: s(20)

                        // 时间
                        Column {
                            spacing: s(6)
                            width: s(130)
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: model.date
                                font.pixelSize: s(16)
                                font.weight: Font.Medium
                                color: "#FFFFFF"
                            }

                            Text {
                                text: model.startTime
                                font.pixelSize: s(14)
                                color: "#80FFFFFF"
                            }
                        }

                        // 分隔线
                        Rectangle {
                            width: 1
                            height: s(50)
                            color: "#1AFFFFFF"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // 起点终点
                        Column {
                            spacing: s(8)
                            width: s(260)
                            anchors.verticalCenter: parent.verticalCenter

                            Row {
                                spacing: s(10)

                                Rectangle {
                                    width: s(10)
                                    height: s(10)
                                    radius: s(5)
                                    color: "#4ade80"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: model.from
                                    font.pixelSize: s(15)
                                    color: "#FFFFFF"
                                    elide: Text.ElideRight
                                    width: s(230)
                                }
                            }

                            Row {
                                spacing: s(10)

                                Rectangle {
                                    width: s(10)
                                    height: s(10)
                                    radius: s(5)
                                    color: "#f093fb"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: model.to
                                    font.pixelSize: s(15)
                                    color: "#FFFFFF"
                                    elide: Text.ElideRight
                                    width: s(230)
                                }
                            }
                        }

                        // 分隔线
                        Rectangle {
                            width: 1
                            height: s(50)
                            color: "#1AFFFFFF"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // 统计数据
                        Row {
                            spacing: s(32)
                            anchors.verticalCenter: parent.verticalCenter

                            Column {
                                spacing: s(4)

                                Text {
                                    text: "里程"
                                    font.pixelSize: s(13)
                                    color: "#66FFFFFF"
                                }

                                Text {
                                    text: model.dist
                                    font.pixelSize: s(17)
                                    font.weight: Font.Medium
                                    color: "#667eea"
                                }
                            }

                            Column {
                                spacing: s(4)

                                Text {
                                    text: "时长"
                                    font.pixelSize: s(13)
                                    color: "#66FFFFFF"
                                }

                                Text {
                                    text: model.time
                                    font.pixelSize: s(17)
                                    color: "#FFFFFF"
                                }
                            }

                            Column {
                                spacing: s(4)

                                Text {
                                    text: "速度"
                                    font.pixelSize: s(13)
                                    color: "#66FFFFFF"
                                }

                                Text {
                                    text: model.speed
                                    font.pixelSize: s(17)
                                    color: "#4ade80"
                                }
                            }
                        }
                        // 占位空间
                        Item {
                            width: s(20)
                            height: 1
                        }
                    }
                }

                ScrollIndicator.vertical: ScrollIndicator { }
            }
        }
    }

    // 删除所有记录确认对话框
    Dialog {
        id: deleteConfirmDialog
        anchors.centerIn: parent
        width: s(450)
        height: s(200)
        modal: true

        background: Rectangle {
            color: "#1E1E1E"
            radius: s(18)
            border.color: "#444"
            border.width: 2
        }

        contentItem: Column {
            spacing: s(24)
            padding: s(30)

            Text {
                text: "确认清空所有历史记录？"
                color: "white"
                font.pixelSize: s(22)
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "此操作不可恢复!"
                color: "#FF4444"
                font.pixelSize: s(17)
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Row {
                spacing: s(24)
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    width: s(140)
                    height: s(48)
                    radius: s(12)
                    color: "#444"

                    Text {
                        text: "取消"
                        color: "white"
                        font.pixelSize: s(17)
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: deleteConfirmDialog.close()
                    }
                }

                Rectangle {
                    width: s(140)
                    height: s(48)
                    radius: s(12)
                    color: "#FF4444"

                    Text {
                        text: "确认清空"
                        color: "white"
                        font.pixelSize: s(17)
                        font.bold: true
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            historyDB.clearAllTrips()
                            updateStats()
                            deleteConfirmDialog.close()
                        }
                    }
                }
            }
        }
    }

    // 页面加载时刷新数据
    Component.onCompleted: {
        console.log("📊 HistoryPage 加载完成")

        if (typeof historyDB === "undefined") {
            console.error("❌ historyDB 未定义！")
            return
        }

        if (!historyDB) {
            console.error("❌ historyDB 为 null！")
            return
        }

        console.log("✅ historyDB 可用")
        console.log("📝 当前记录数:", historyDB.count())

        // 刷新数据
        historyDB.refreshHistory()
        updateStats()
    }

    // 监听数据库变化，自动更新统计
    Connections {
        target: historyDB
        function onCountChanged() {
            updateStats()
        }
        function onDataChanged() {
            updateStats()
        }
    }
}
