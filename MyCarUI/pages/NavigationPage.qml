import QtQuick
import QtQuick.Controls
import QtWebEngine

Item {
    id: navigationPage

    // 背景
    Rectangle {
        anchors.fill: parent
        color: "#121212"
    }

    // 百度地图API的AK
    property string baiduMapAk: "FBfr6TTZQgDpyWTjlf2ocGWrfbakcTu5"

    // 当前位置坐标（起点）
    property double currentLng: 116.404
    property double currentLat: 39.915
    property string currentAddress: "北京市东城区天安门"

    // 目标位置坐标（终点）
    property double targetLng: 116.327
    property double targetLat: 39.895
    property string targetAddress: ""

    // 地图状态
    property bool mapLoaded: false
    property string loadStatus: "初始化中..."

    // 导航状态
    property bool isNavigating: false
    property string navDistance: ""
    property string navDuration: ""
    property bool trafficEnabled: false

    // 友好日期格式函数
    function formatFriendlyDate(date) {
        var now = new Date();
        var today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        var yesterday = new Date(today);
        yesterday.setDate(today.getDate() - 1);

        var targetDate = new Date(date.getFullYear(), date.getMonth(), date.getDate());

        if (targetDate.getTime() === today.getTime()) {
            return "今天 " + Qt.formatTime(date, "hh:mm");
        } else if (targetDate.getTime() === yesterday.getTime()) {
            return "昨天 " + Qt.formatTime(date, "hh:mm");
        } else {
            return Qt.formatDate(date, "M月d日") + " " + Qt.formatTime(date, "hh:mm");
        }
    }

    // 生成完整的HTML页面
    function getMapHtml() {
        return '<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="initial-scale=1.0, user-scalable=no">
    <title>车机导航</title>
    <style>
        html, body, #allmap {
            width: 100%;
            height: 100%;
            margin: 0;
            padding: 0;
            overflow: hidden;
        }
    </style>
    <script src="https://api.map.baidu.com/api?v=3.0&ak=' + baiduMapAk + '"></script>
</head>
<body>
    <div id="allmap"></div>
    <script>
        var map = null;
        var currentMarker = null;
        var targetMarker = null;
        var driving = null;
        var trafficLayer = null;
        var trafficOn = false;
        var geocoder = null;

        function initMap(lng, lat) {
            try {
                if (typeof BMap === "undefined") return "error: BMap not loaded";

                map = new BMap.Map("allmap");
                var point = new BMap.Point(lng, lat);
                map.centerAndZoom(point, 15);
                map.enableScrollWheelZoom(true);

                map.addControl(new BMap.NavigationControl({
                    anchor: BMAP_ANCHOR_TOP_LEFT,
                    type: BMAP_NAVIGATION_CONTROL_SMALL
                }));
                map.addControl(new BMap.ScaleControl());

                geocoder = new BMap.Geocoder();

                var startIcon = new BMap.Icon(
                    "data:image/svg+xml," + encodeURIComponent(\'<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32"><circle cx="16" cy="16" r="12" fill="#4285F4" stroke="white" stroke-width="4"/><circle cx="16" cy="16" r="5" fill="white"/></svg>\'),
                    new BMap.Size(32, 32),
                    { anchor: new BMap.Size(16, 16) }
                );
                currentMarker = new BMap.Marker(point, { icon: startIcon });
                currentMarker.setTitle("起点");
                map.addOverlay(currentMarker);

                return "success";
            } catch (e) {
                return "error: " + e.message;
            }
        }

        function geocodeAddress(address, isStart) {
            if (!geocoder) {
                geocoder = new BMap.Geocoder();
            }

            geocoder.getPoint(address, function(point) {
                if (point) {
                    console.log((isStart ? "START" : "END") + "_GEOCODE:" + JSON.stringify({
                        address: address,
                        lng: point.lng,
                        lat: point.lat
                    }));

                    if (isStart) {
                        if (currentMarker) currentMarker.setPosition(point);
                        map.centerAndZoom(point, 15);
                    } else {
                        setTarget(point.lng, point.lat, address);
                    }
                } else {
                    console.log("GEOCODE_ERROR:地址解析失败 - " + address);
                }
            }, "全国");
        }

        function setStartPoint(lng, lat) {
            var point = new BMap.Point(lng, lat);
            if (currentMarker) {
                currentMarker.setPosition(point);
            }
            map.centerAndZoom(point, 15);
            return "success";
        }

        function setTarget(lng, lat, name) {
            try {
                if (!map) return "error";

                var point = new BMap.Point(lng, lat);

                if (targetMarker) map.removeOverlay(targetMarker);

                var endIcon = new BMap.Icon(
                    "data:image/svg+xml," + encodeURIComponent(\'<svg xmlns="http://www.w3.org/2000/svg" width="32" height="40"><path d="M16 0C7.2 0 0 7.2 0 16c0 12 16 24 16 24s16-12 16-24C32 7.2 24.8 0 16 0z" fill="#FF4444"/><circle cx="16" cy="16" r="8" fill="white"/></svg>\'),
                    new BMap.Size(32, 40),
                    { anchor: new BMap.Size(16, 40) }
                );
                targetMarker = new BMap.Marker(point, { icon: endIcon });
                targetMarker.setTitle(name || "终点");
                map.addOverlay(targetMarker);

                if (name) {
                    var label = new BMap.Label(name, { offset: new BMap.Size(20, -10) });
                    label.setStyle({
                        color: "#fff",
                        backgroundColor: "#FF4444",
                        border: "none",
                        padding: "5px 10px",
                        borderRadius: "4px",
                        fontSize: "12px"
                    });
                    targetMarker.setLabel(label);
                }

                if (currentMarker) {
                    map.setViewport([currentMarker.getPosition(), point]);
                }

                return "success";
            } catch (e) {
                return "error: " + e.message;
            }
        }

        function planRoute(startLng, startLat, endLng, endLat) {
            try {
                if (!map) return JSON.stringify({status: "error", message: "地图未初始化"});

                if (driving) driving.clearResults();

                var startPoint = new BMap.Point(startLng, startLat);
                var endPoint = new BMap.Point(endLng, endLat);

                driving = new BMap.DrivingRoute(map, {
                    renderOptions: {
                        map: map,
                        autoViewport: true
                    },
                    onSearchComplete: function(results) {
                        if (driving.getStatus() === BMAP_STATUS_SUCCESS) {
                            var plan = results.getPlan(0);
                            console.log("ROUTE_INFO:" + JSON.stringify({
                                distance: plan.getDistance(true),
                                duration: plan.getDuration(true)
                            }));
                        } else {
                            console.log("ROUTE_ERROR:路线规划失败");
                        }
                    }
                });

                driving.search(startPoint, endPoint);
                return JSON.stringify({status: "success"});
            } catch (e) {
                return JSON.stringify({status: "error", message: e.message});
            }
        }

        function clearRoute() {
            if (driving) driving.clearResults();
            if (targetMarker) {
                map.removeOverlay(targetMarker);
                targetMarker = null;
            }
            return "success";
        }

        function centerAt(lng, lat, zoom) {
            if (map) map.centerAndZoom(new BMap.Point(lng, lat), zoom || 15);
        }

        function zoomIn() { if (map) map.zoomIn(); }
        function zoomOut() { if (map) map.zoomOut(); }

        function toggleTraffic() {
            if (!map) return false;
            if (!trafficLayer) trafficLayer = new BMap.TrafficLayer();
            if (trafficOn) {
                map.removeTileLayer(trafficLayer);
                trafficOn = false;
            } else {
                map.addTileLayer(trafficLayer);
                trafficOn = true;
            }
            return trafficOn;
        }

        function searchPlace(keyword) {
            if (!map) return;
            var local = new BMap.LocalSearch(map, {
                renderOptions: { map: map, autoViewport: true, selectFirstResult: true },
                onSearchComplete: function(results) {
                    if (local.getStatus() === BMAP_STATUS_SUCCESS && results.getPoi(0)) {
                        var poi = results.getPoi(0);
                        console.log("SEARCH_RESULT:" + JSON.stringify({
                            name: poi.title,
                            address: poi.address,
                            lng: poi.point.lng,
                            lat: poi.point.lat
                        }));
                    } else {
                        console.log("SEARCH_ERROR:未找到结果");
                    }
                }
            });
            local.search(keyword);
        }
    </script>
</body>
</html>';
    }

    // 标题栏
    Rectangle {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 70
        color: "#1A1A1A"

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            spacing: 15
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Rectangle {
                width: 12
                height: 12
                radius: 6
                color: mapLoaded ? "#00FF00" : "#FF8800"
            }

            Text {
                text: mapLoaded ? "已就绪" : "加载中"
                color: mapLoaded ? "#00FF00" : "#FF8800"
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // 地址输入栏
    Rectangle {
        id: addressBar
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 100
        color: "#1E1E1E"

        Row {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Column {
                width: (parent.width - 100) / 2
                spacing: 5

                Text {
                    text: "📍 起点"
                    color: "#4285F4"
                    font.pixelSize: 14
                    font.bold: true
                }

                Rectangle {
                    width: parent.width
                    height: 45
                    radius: 8
                    color: "#333"
                    border.color: startInput.activeFocus ? "#4285F4" : "#555"
                    border.width: 2

                    TextField {
                        id: startInput
                        anchors.fill: parent
                        anchors.margins: 8
                        color: "white"
                        font.pixelSize: 16
                        text: currentAddress
                        placeholderText: "输入起点地址..."
                        placeholderTextColor: "#888"
                        background: Rectangle { color: "transparent" }

                        onEditingFinished: {
                            if (text.trim() !== "") {
                                setStartAddress(text.trim())
                            }
                        }
                    }
                }
            }

            Column {
                width: (parent.width - 100) / 2
                spacing: 5

                Text {
                    text: "🚩 终点"
                    color: "#FF4444"
                    font.pixelSize: 14
                    font.bold: true
                }

                Rectangle {
                    width: parent.width
                    height: 45
                    radius: 8
                    color: "#333"
                    border.color: endInput.activeFocus ? "#FF4444" : "#555"
                    border.width: 2

                    TextField {
                        id: endInput
                        anchors.fill: parent
                        anchors.margins: 8
                        color: "white"
                        font.pixelSize: 16
                        text: targetAddress
                        placeholderText: "输入终点地址..."
                        placeholderTextColor: "#888"
                        background: Rectangle { color: "transparent" }

                        onEditingFinished: {
                            if (text.trim() !== "") {
                                setEndAddress(text.trim())
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: 70
                height: 80
                radius: 10
                color: routeBtnMouse.pressed ? "#0088CC" : "#00AADD"
                anchors.verticalCenter: parent.verticalCenter

                Column {
                    anchors.centerIn: parent
                    spacing: 3

                    Text {
                        text: "🔍"
                        font.pixelSize: 24
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "搜索"
                        color: "white"
                        font.pixelSize: 12
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                MouseArea {
                    id: routeBtnMouse
                    anchors.fill: parent
                    onClicked: {
                        if (startInput.text.trim() !== "" && endInput.text.trim() !== "") {
                            searchRoute()
                        } else {
                            showMessage("请输入起点和终点地址")
                        }
                    }
                }
            }
        }
    }

    // 导航信息条
    Rectangle {
        id: infoBar
        anchors.top: addressBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: isNavigating || navDistance !== "" ? 50 : 0
        color: "#2A2A2A"
        visible: height > 0

        Behavior on height { NumberAnimation { duration: 200 } }

        Row {
            anchors.centerIn: parent
            spacing: 40
            visible: parent.visible

            Row {
                spacing: 8
                Text { text: "📏"; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
                Text { text: navDistance || "--"; color: "#00D1FF"; font.pixelSize: 18; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
            }

            Rectangle { width: 1; height: 30; color: "#555" }

            Row {
                spacing: 8
                Text { text: "⏱️"; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
                Text { text: navDuration || "--"; color: "#00D1FF"; font.pixelSize: 18; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
            }

            Rectangle { width: 1; height: 30; color: "#555" }

            Row {
                spacing: 8
                Rectangle {
                    width: 12; height: 12; radius: 6
                    color: isNavigating ? "#00FF00" : "#FFAA00"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: isNavigating ? "导航中" : "已规划"
                    color: isNavigating ? "#00FF00" : "#FFAA00"
                    font.pixelSize: 16
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // 地图容器
    WebEngineView {
        id: webView
        anchors.top: infoBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: controlBar.top
        anchors.margins: 3

        settings.javascriptEnabled: true
        settings.pluginsEnabled: true
        settings.localContentCanAccessRemoteUrls: true

        Component.onCompleted: {
            loadHtml(getMapHtml(), "https://api.map.baidu.com/")
        }

        onLoadingChanged: function(loadRequest) {
            if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                loadStatus = "正在初始化..."
                mapInitTimer.start()
            } else if (loadRequest.status === WebEngineView.LoadFailedStatus) {
                loadStatus = "加载失败"
                mapLoaded = false
            }
        }

        onJavaScriptConsoleMessage: function(level, message, lineNumber, sourceID) {
            console.log("[JS]", message)

            if (message.startsWith("ROUTE_INFO:")) {
                try {
                    var info = JSON.parse(message.substring(11))
                    navDistance = info.distance || "--"
                    navDuration = info.duration || "--"

                    // 仍然保留写入数据库（独立的历史页面需要数据）
                    if (typeof historyDB !== "undefined" && historyDB && navDistance !== "--" && navDuration !== "--") {
                        var now = new Date()
                        var dateStr = formatFriendlyDate(now)

                        // ⭐ 新增：计算平均速度
                        var avgSpeed = "--"
                        try {
                            // 解析距离 (例如 "4770.6公里" 或 "100km")
                            var distMatch = navDistance.match(/[\d.]+/)
                            var dist = distMatch ? parseFloat(distMatch[0]) : 0

                            // 解析时间 (例如 "23天23小时", "20分钟", "1小时30分钟")
                            var hours = 0
                            var dayMatch = navDuration.match(/(\d+)天/)
                            var hourMatch = navDuration.match(/(\d+)小时/)
                            var minMatch = navDuration.match(/(\d+)分钟/)

                            if (dayMatch) hours += parseInt(dayMatch[1]) * 24
                            if (hourMatch) hours += parseInt(hourMatch[1])
                            if (minMatch) hours += parseInt(minMatch[1]) / 60.0

                            // 计算平均速度 (km/h)
                            if (hours > 0 && dist > 0) {
                                var speed = dist / hours
                                avgSpeed = speed.toFixed(1) + " km/h"
                            }
                        } catch (e) {
                            console.log("计算平均速度失败:", e)
                            avgSpeed = "--"
                        }

                        var tripData = {
                            "date": dateStr,
                            "from": currentAddress || "未知起点",
                            "to": targetAddress || "未知终点",
                            "dist": navDistance,
                            "time": navDuration,
                            "speed": avgSpeed
                        }

                        historyDB.insertTrip(tripData)
                        showMessage("路线规划完成，已保存到历史记录")
                    } else {
                        showMessage("路线规划完成")
                    }
                } catch (e) {
                    console.log("ROUTE_INFO parse error:", e)
                }
            }
            else if (message.startsWith("SEARCH_RESULT:")) {
                try {
                    var result = JSON.parse(message.substring(14))
                    targetLng = result.lng
                    targetLat = result.lat
                    targetAddress = result.name
                    endInput.text = result.name
                    showMessage("找到: " + result.name)
                } catch (e) {}
            }
            else if (message.startsWith("START_GEOCODE:")) {
                try {
                    var geo = JSON.parse(message.substring(14))
                    currentLng = geo.lng
                    currentLat = geo.lat
                    currentAddress = geo.address
                    showMessage("起点已设置")
                } catch (e) {}
            }
            else if (message.startsWith("END_GEOCODE:")) {
                try {
                    var geo = JSON.parse(message.substring(12))
                    targetLng = geo.lng
                    targetLat = geo.lat
                    targetAddress = geo.address
                    showMessage("终点已设置")
                } catch (e) {}
            }
            else if (message.startsWith("GEOCODE_ERROR:")) {
                showMessage(message.substring(14))
            }
            else if (message.startsWith("SEARCH_ERROR:") || message.startsWith("ROUTE_ERROR:")) {
                showMessage(message.substring(message.indexOf(":") + 1))
            }
        }
    }

    // 定时器
    Timer {
        id: mapInitTimer
        interval: 1500
        onTriggered: initializeMap()
    }

    Timer {
        id: retryTimer
        interval: 2000
        onTriggered: initializeMap()
    }

    Timer {
        id: messageTimer
        interval: 3000
        onTriggered: loadStatus = mapLoaded ? "就绪" : "等待中..."
    }

    // 控制栏
    Rectangle {
        id: controlBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 80
        color: "#1A1A1A"

        Row {
            anchors.centerIn: parent
            spacing: 12

            ControlButton {
                icon: isNavigating ? "⏹" : "▶"
                label: isNavigating ? "停止" : "导航"
                bgColor: isNavigating ? "#CC3333" : "#00AADD"
                onClicked: {
                    if (!mapLoaded) { showMessage("地图未就绪"); return }
                    isNavigating ? stopNavigation() : startNavigation()
                }
            }

            ControlButton {
                icon: "⭐"
                label: "热门"
                onClicked: hotPlacesDialog.open()
            }

            ControlButton {
                icon: "📍"
                label: "起点"
                onClicked: {
                    if (mapLoaded) {
                        webView.runJavaScript('centerAt(' + currentLng + ',' + currentLat + ',15);')
                        showMessage("已定位到起点")
                    }
                }
            }

            ControlButton {
                icon: "➕"
                label: "放大"
                onClicked: webView.runJavaScript('zoomIn();')
            }

            ControlButton {
                icon: "➖"
                label: "缩小"
                onClicked: webView.runJavaScript('zoomOut();')
            }

            ControlButton {
                icon: "🚦"
                label: trafficEnabled ? "关路况" : "路况"
                bgColor: trafficEnabled ? "#005577" : "#333333"
                onClicked: {
                    webView.runJavaScript('toggleTraffic();', function(result) {
                        trafficEnabled = (result === true)
                        showMessage(trafficEnabled ? "路况已开启" : "路况已关闭")
                    })
                }
            }

            ControlButton {
                icon: "🗑"
                label: "清除"
                onClicked: {
                    webView.runJavaScript('clearRoute();')
                    isNavigating = false
                    navDistance = ""
                    navDuration = ""
                    endInput.text = ""
                    targetAddress = ""
                    showMessage("已清除路线")
                }
            }
        }
    }

    // 控制按钮组件
    component ControlButton: Rectangle {
        property string icon: ""
        property string label: ""
        property color bgColor: "#333333"
        signal clicked()

        width: 85
        height: 60
        radius: 10
        color: btnMouse.pressed ? Qt.darker(bgColor, 1.3) : bgColor

        Column {
            anchors.centerIn: parent
            spacing: 2

            Text {
                text: icon
                font.pixelSize: 22
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: label
                color: "white"
                font.pixelSize: 12
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            onClicked: parent.clicked()
        }
    }

    // 热门地点对话框
    Dialog {
        id: hotPlacesDialog
        anchors.centerIn: parent
        width: 600
        height: 450
        modal: true

        background: Rectangle {
            color: "#1E1E1E"
            radius: 15
            border.color: "#444"
            border.width: 2
        }

        header: Rectangle {
            width: parent.width
            height: 55
            color: "#2A2A2A"
            radius: 15

            Text {
                text: "⭐ 热门地点"
                color: "white"
                font.pixelSize: 22
                font.bold: true
                anchors.centerIn: parent
            }

            Rectangle {
                width: 36; height: 36; radius: 18
                color: "#444"
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter

                Text { text: "✕"; color: "white"; font.pixelSize: 18; anchors.centerIn: parent }
                MouseArea { anchors.fill: parent; onClicked: hotPlacesDialog.close() }
            }
        }

        contentItem: Column {
            spacing: 15
            padding: 15

            Text {
                text: "选择作为起点或终点"
                color: "#AAA"
                font.pixelSize: 14
            }

            Grid {
                columns: 3
                spacing: 12

                Repeater {
                    model: [
                        {name: "天安门", type: "景点"},
                        {name: "北京西站", type: "交通"},
                        {name: "首都机场T3", type: "交通"},
                        {name: "故宫博物院", type: "景点"},
                        {name: "鸟巢体育馆", type: "景点"},
                        {name: "颐和园", type: "景点"},
                        {name: "王府井", type: "商圈"},
                        {name: "中关村", type: "商圈"},
                        {name: "国贸CBD", type: "商圈"},
                        {name: "北京南站", type: "交通"},
                        {name: "三里屯", type: "商圈"},
                        {name: "798艺术区", type: "景点"}
                    ]

                    Rectangle {
                        width: 175
                        height: 70
                        radius: 10
                        color: placeMouse.pressed ? "#444" : "#333"

                        Column {
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: modelData.name
                                color: "white"
                                font.pixelSize: 16
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: modelData.type
                                color: "#888"
                                font.pixelSize: 12
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        MouseArea {
                            id: placeMouse
                            anchors.fill: parent
                            onClicked: {
                                placeActionDialog.placeName = modelData.name
                                placeActionDialog.open()
                                hotPlacesDialog.close()
                            }
                        }
                    }
                }
            }
        }
    }

    // 地点操作选择对话框
    Dialog {
        id: placeActionDialog
        anchors.centerIn: parent
        width: 350
        height: 200
        modal: true

        property string placeName: ""

        background: Rectangle {
            color: "#1E1E1E"
            radius: 15
            border.color: "#444"
            border.width: 2
        }

        contentItem: Column {
            spacing: 20
            padding: 25

            Text {
                text: "将「" + placeActionDialog.placeName + "」设为："
                color: "white"
                font.pixelSize: 18
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Row {
                spacing: 20
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    width: 120; height: 50; radius: 10
                    color: "#4285F4"

                    Text { text: "📍 起点"; color: "white"; font.pixelSize: 16; font.bold: true; anchors.centerIn: parent }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            startInput.text = placeActionDialog.placeName
                            setStartAddress(placeActionDialog.placeName)
                            placeActionDialog.close()
                        }
                    }
                }

                Rectangle {
                    width: 120; height: 50; radius: 10
                    color: "#FF4444"

                    Text { text: "🚩 终点"; color: "white"; font.pixelSize: 16; font.bold: true; anchors.centerIn: parent }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            endInput.text = placeActionDialog.placeName
                            setEndAddress(placeActionDialog.placeName)
                            placeActionDialog.close()
                        }
                    }
                }
            }
        }
    }

    // 消息提示
    Rectangle {
        id: messageToast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: controlBar.top
        anchors.bottomMargin: 20
        width: messageText.width + 40
        height: 45
        radius: 22
        color: "#DD000000"
        visible: false

        Text {
            id: messageText
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: 16
        }

        Timer {
            id: toastTimer
            interval: 2000
            onTriggered: messageToast.visible = false
        }
    }

    // 函数
    function initializeMap() {
        loadStatus = "初始化地图..."

        webView.runJavaScript('initMap(' + currentLng + ',' + currentLat + ');', function(result) {
            if (result === "success") {
                mapLoaded = true
                loadStatus = "就绪"
                showMessage("地图已加载")
            } else {
                retryTimer.start()
            }
        })
    }

    function setStartAddress(address) {
        if (!mapLoaded) return
        showMessage("正在解析起点...")
        webView.runJavaScript('geocodeAddress("' + address + '", true);')
    }

    function setEndAddress(address) {
        if (!mapLoaded) return
        showMessage("正在解析终点...")
        webView.runJavaScript('geocodeAddress("' + address + '", false);')
    }

    function searchRoute() {
        if (!mapLoaded) {
            showMessage("地图未就绪")
            return
        }

        showMessage("正在规划路线...")

        var startAddr = startInput.text.trim()
        var endAddr = endInput.text.trim()

        if (currentLng > 0 && targetLng > 0) {
            webView.runJavaScript('planRoute(' + currentLng + ',' + currentLat + ',' + targetLng + ',' + targetLat + ');')
        } else {
            setStartAddress(startAddr)
            Qt.callLater(function() { setEndAddress(endAddr) })
        }
    }

    function startNavigation() {
        if (targetLng === 0 || targetLat === 0) {
            showMessage("请先设置终点")
            return
        }

        isNavigating = true
        navDistance = "计算中..."
        navDuration = "计算中..."

        webView.runJavaScript('planRoute(' + currentLng + ',' + currentLat + ',' + targetLng + ',' + targetLat + ');')
    }

    function stopNavigation() {
        isNavigating = false
        navDistance = ""
        navDuration = ""
        webView.runJavaScript('clearRoute();')
        showMessage("导航已停止")
    }

    function showMessage(msg) {
        console.log("💬", msg)
        loadStatus = msg
        messageText.text = msg
        messageToast.visible = true
        toastTimer.restart()
    }

    Component.onCompleted: {
        console.log("🚗 车机导航系统启动")
        // 数据库已在 main.cpp 中初始化，不需要在这里初始化
    }
}
