import QtQuick
import QtQuick.Controls
import QtMultimedia
import QtQuick.Dialogs
import Qt.labs.folderlistmodel

Item {
    id: root
    // 自适应缩放因子：基于原始设计尺寸 1920x880，等比缩放以适应窗口变化
    property real uiScale: (width > 0 && height > 0) ? Math.min(width / 1920, height / 880) : 1

    MediaPlayer {
        id: mediaPlayer
        audioOutput: audioOutput

        onPlaybackStateChanged: {
            isPlaying = playbackState === MediaPlayer.PlayingState
            if (playlistModel.count > 0 && currentIndex >= 0) {
                for (var i = 0; i < playlistModel.count; i++) {
                    playlistModel.setProperty(i, "playing", i === currentIndex && isPlaying)
                }
            }
        }

        onPositionChanged: progress = position / duration

        onMediaStatusChanged: if (mediaStatus === MediaPlayer.EndOfMedia) nextTrack()

        onErrorOccurred: console.error("播放错误:", errorString)
    }

    AudioOutput {
        id: audioOutput
        volume: volumeLevel
    }

    ListModel { id: playlistModel }

    property bool isPlaying: false
    property real progress: 0.0
    property real volumeLevel: 0.7
    property int currentIndex: -1
    property bool isScanning: false
    property bool autoScanCompleted: false
    property url albumArt: ""
    property bool hasAlbumArt: false
    property string defaultMusicFolder: "file:///home/zhuc/gitzz/emb/MyCarUI"

    FolderListModel {
        id: folderListModel
        showDirs: false
        showDotAndDotDot: false
        showHidden: false
        nameFilters: ["*.mp3", "*.MP3", "*.wav", "*.WAV", "*.flac", "*.FLAC",
                      "*.ogg", "*.OGG", "*.m4a", "*.M4A", "*.aac", "*.AAC",
                      "*.wma", "*.WMA", "*.ape", "*.APE"]
        sortField: FolderListModel.Name

        onStatusChanged: if (status === FolderListModel.Ready) {
            for (var i = 0; i < count; i++) {
                var filePath = get(i, "fileUrl").toString()
                var fileName = get(i, "fileName")
                addFileToPlaylist(filePath, fileName)
            }
            if (!subFolderListModel.recursiveEnabled || subFolderListModel.pendingFolders.length === 0) {
                isScanning = false
                if (!autoScanCompleted && playlistModel.count > 0) {
                    autoScanCompleted = true
                    currentIndex = 0
                    playTrack(0)
                }
            }
        }
    }

    FolderListModel {
        id: subFolderListModel
        showDirs: true
        showDotAndDotDot: false
        showHidden: false
        showFiles: false
        sortField: FolderListModel.Name
        property var pendingFolders: []
        property bool recursiveEnabled: false

        onStatusChanged: if (status === FolderListModel.Ready && recursiveEnabled) {
            for (var i = 0; i < count; i++) pendingFolders.push(get(i, "fileUrl"))
            processNextSubFolder()
        }
    }

    function processNextSubFolder() {
        if (subFolderListModel.pendingFolders.length > 0) {
            scanFolderNonRecursive(subFolderListModel.pendingFolders.shift())
            subFolderTimer.start()
        } else {
            isScanning = false
            subFolderListModel.recursiveEnabled = false
            if (!autoScanCompleted && playlistModel.count > 0) {
                autoScanCompleted = true
                currentIndex = 0
                playTrack(0)
            }
        }
    }

    Timer {
        id: subFolderTimer
        interval: 100
        onTriggered: {
            if (subFolderListModel.pendingFolders.length > 0) {
                scanFolderNonRecursive(subFolderListModel.pendingFolders.shift())
                start()
            } else {
                isScanning = false
                if (!autoScanCompleted && playlistModel.count > 0) {
                    autoScanCompleted = true
                    currentIndex = 0
                    playTrack(0)
                }
            }
        }
    }

    Timer {
        id: autoScanTimer
        interval: 500
        repeat: false
        onTriggered: scanFolder(defaultMusicFolder, true)
    }

    // Unicode 图标（保持简洁）
    component MusicNoteIcon: Item {
        property color iconColor: "#FFFFFF"
        property real iconSize: 80
        width: iconSize; height: iconSize
        Text { anchors.centerIn: parent; text: "🎵"; font.pixelSize: iconSize; color: iconColor }
    }

    component PlayIcon: Item {
        property color iconColor: "#FFFFFF"
        property real iconSize: 24
        width: iconSize; height: iconSize
        Text { anchors.centerIn: parent; text: "▶"; font.pixelSize: iconSize * 1.2; color: iconColor }
    }

    component PauseIcon: Item {
        property color iconColor: "#FFFFFF"
        property real iconSize: 24
        width: iconSize; height: iconSize
        Row {
            anchors.centerIn: parent
            spacing: parent.width * 0.2
            Repeater {
                model: 2
                Rectangle { width: parent.parent.width * 0.25; height: parent.parent.height * 0.7; radius: 2; color: parent.parent.iconColor }
            }
        }
    }

    component PrevIcon: Item {
        property color iconColor: "#FFFFFF"
        property real iconSize: 20
        width: iconSize; height: iconSize
        Text { anchors.centerIn: parent; text: "◀◀"; font.pixelSize: iconSize * 1.2; color: iconColor }
    }

    component NextIcon: Item {
        property color iconColor: "#FFFFFF"
        property real iconSize: 20
        width: iconSize; height: iconSize
        Text { anchors.centerIn: parent; text: "▶▶"; font.pixelSize: iconSize * 1.2; color: iconColor }
    }

    component FolderIcon: Item {
        property color iconColor: "#FFFFFF"
        property real iconSize: 28
        width: iconSize; height: iconSize
        Text { anchors.centerIn: parent; text: "📂"; font.pixelSize: iconSize; color: iconColor }
    }

    component VolumeIcon: Item {
        property color iconColor: "#FFFFFF"
        property real iconSize: 20
        property real level: 0.7
        width: iconSize; height: iconSize
        Text {
            anchors.centerIn: parent
            text: level === 0 ? "🔇" : level < 0.33 ? "🔈" : level < 0.66 ? "🔉" : "🔊"
            font.pixelSize: iconSize * 1.2
            color: iconColor
        }
    }

    component TrashIcon: Item {
        property color iconColor: "#FFFFFF"
        property real iconSize: 16
        width: iconSize; height: iconSize
        Text { anchors.centerIn: parent; text: "🗑"; font.pixelSize: iconSize * 1.2; color: iconColor }
    }

    component SearchIcon: Item {
        property color iconColor: "#FFFFFF"
        property real iconSize: 40
        width: iconSize; height: iconSize
        Text { anchors.centerIn: parent; text: "🔍"; font.pixelSize: iconSize * 1.2; color: iconColor }
    }

    component CloseIcon: Item {
        property color iconColor: "#ef4444"
        property real iconSize: 16
        width: iconSize; height: iconSize
        Repeater {
            model: 2
            Rectangle {
                width: parent.width * 0.8
                height: parent.height * 0.15
                radius: height / 2
                color: parent.iconColor
                anchors.centerIn: parent
                rotation: index === 0 ? 45 : -45
            }
        }
    }

    component EmptyFolderIcon: Item {
        property color iconColor: "#FFFFFF"
        property real iconSize: 60
        width: iconSize; height: iconSize
        Text { anchors.centerIn: parent; text: "📂"; font.pixelSize: iconSize * 1.2; color: iconColor }
    }

    // 函数保持不变（紧凑版）
    function formatTime(ms) {
        if (ms <= 0) return "00:00"
        var s = Math.floor(ms / 1000)
        var m = Math.floor(s / 60)
        return String(m).padStart(2, '0') + ":" + String(s % 60).padStart(2, '0')
    }

    function togglePlayback() {
        isPlaying ? mediaPlayer.pause() : mediaPlayer.playbackState === MediaPlayer.StoppedState && playlistModel.count > 0 ?
                    playTrack(currentIndex < 0 ? 0 : currentIndex) : mediaPlayer.play()
    }

    function nextTrack() { if (playlistModel.count > 0) playTrack((currentIndex + 1) % playlistModel.count) }
    function previousTrack() { if (playlistModel.count > 0) playTrack((currentIndex - 1 + playlistModel.count) % playlistModel.count) }

    function playTrack(index) {
        if (index >= 0 && index < playlistModel.count) {
            currentIndex = index
            mediaPlayer.source = playlistModel.get(index).path
            mediaPlayer.play()
            readAlbumArt()
        }
    }

    function readAlbumArt() {
        albumArt = ""; hasAlbumArt = false
        if (mediaPlayer.metaData) {
            var keys = ["coverArtImage", "coverArtUrl", "thumbnailUrl", "albumArt"]
            for (var k of keys) {
                if (mediaPlayer.metaData[k]) { albumArt = mediaPlayer.metaData[k]; hasAlbumArt = true; break }
            }
        }
    }

    function setProgress(p) { if (mediaPlayer.duration > 0) mediaPlayer.position = p * mediaPlayer.duration }
    function setVolume(v) { volumeLevel = Math.max(0, Math.min(1, v)) }

    function scanFolderNonRecursive(url) { folderListModel.folder = url }
    function scanFolder(url, recursive) {
        isScanning = true
        folderListModel.folder = url
        if (recursive) {
            subFolderListModel.recursiveEnabled = true
            subFolderListModel.pendingFolders = []
            subFolderListModel.folder = url
        }
    }

    function addFileToPlaylist(path, name) {
        for (var i = 0; i < playlistModel.count; i++) if (playlistModel.get(i).path === path) return
        playlistModel.append({ title: name.replace(/\.[^/.]+$/, ""), artist: "本地音乐", duration: "0:00", path: path, playing: false })
        if (playlistModel.count === 1) currentIndex = 0
    }

    function removeFromPlaylist(idx) {
        if (idx < 0 || idx >= playlistModel.count) return
        playlistModel.remove(idx)
        if (playlistModel.count === 0) {
            currentIndex = -1; mediaPlayer.stop(); albumArt = ""; hasAlbumArt = false
        } else if (currentIndex >= idx) currentIndex = Math.max(0, currentIndex - 1)
    }

    function clearPlaylist() { playlistModel.clear(); currentIndex = -1; mediaPlayer.stop(); albumArt = ""; hasAlbumArt = false }

    FolderDialog { id: folderDialog; title: "选择音乐文件夹"; onAccepted: scanFolder(selectedFolder, recursiveScanEnabled) }
    property bool recursiveScanEnabled: true

    // 主布局（所有固定尺寸均乘以 uiScale，实现等比自适应）
    Row {
        anchors.centerIn: parent
        spacing: 80 * uiScale

        Column {
            spacing: 40 * uiScale
            width: 500 * uiScale

            Item {
                id: albumArtWrapper
                width: 320 * uiScale
                height: 320 * uiScale
                anchors.horizontalCenter: parent.horizontalCenter

                Item {
                    anchors.fill: parent
                    RotationAnimation on rotation { from: 0; to: 360; duration: 20000; loops: Animation.Infinite; running: isPlaying && !isScanning }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Qt.rgba(1, 1, 1, 0.05)
                        border.color: Qt.rgba(1, 1, 1, 0.15)
                        border.width: 2
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: 2 * uiScale
                            source: hasAlbumArt ? albumArt : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: hasAlbumArt
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2 * uiScale
                            radius: width / 2
                            visible: !hasAlbumArt
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#667eea" }
                                GradientStop { position: 1.0; color: "#764ba2" }
                            }
                            MusicNoteIcon { anchors.centerIn: parent; iconSize: 100 * uiScale; iconColor: Qt.rgba(1, 1, 1, 0.9) }
                        }
                    }
                }

                Rectangle {
                    visible: isScanning
                    anchors.fill: parent
                    radius: width / 2
                    color: Qt.rgba(0, 0, 0, 0.8)
                    Column {
                        anchors.centerIn: parent
                        spacing: 20 * uiScale
                        SearchIcon {
                            iconSize: 50 * uiScale; iconColor: "#667eea"; anchors.horizontalCenter: parent.horizontalCenter
                            RotationAnimation on rotation { from: 0; to: 360; duration: 2000; loops: Animation.Infinite; running: isScanning }
                        }
                        Text { text: "正在扫描..."; font.pixelSize: 24 * uiScale; color: "#FFFFFF"; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "已找到 " + playlistModel.count + " 首歌曲"; font.pixelSize: 18 * uiScale; color: Qt.rgba(1,1,1,0.7); anchors.horizontalCenter: parent.horizontalCenter }
                    }
                }

                Rectangle {
                    width: 56 * uiScale; height: 56 * uiScale; radius: 28 * uiScale
                    color: addFileBtnArea.pressed ? "#667eea" : Qt.rgba(102,126,234,0.9)
                    anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: 10 * uiScale
                    visible: !isScanning
                    FolderIcon { anchors.centerIn: parent; iconSize: 28 * uiScale; iconColor: "#FFFFFF" }
                    MouseArea { id: addFileBtnArea; anchors.fill: parent; hoverEnabled: true; onClicked: folderDialog.open() }
                    scale: addFileBtnArea.containsMouse ? 1.1 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150 } }
                }
            }

            Column {
                spacing: 12 * uiScale
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width

                Text {
                    text: currentIndex >= 0 ? playlistModel.get(currentIndex).title : "无歌曲"
                    font.pixelSize: 40 * uiScale; font.weight: Font.Medium; color: "#FFFFFF"
                    horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                    width: parent.width - 40 * uiScale
                }

                Text {
                    text: "本地音乐"
                    font.pixelSize: 20 * uiScale; color: Qt.rgba(1,1,1,0.5)
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: currentIndex >= 0
                }

                Text {
                    visible: currentIndex >= 0
                    text: {
                        var p = playlistModel.get(currentIndex).path.toString().replace(/^file:\/\//, "")
                        return p.length > 40 ? p.substring(0,20) + "..." + p.substring(p.length-20) : p
                    }
                    font.pixelSize: 15 * uiScale; color: Qt.rgba(1,1,1,0.3)
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 40 * uiScale; elide: Text.ElideMiddle
                }
            }

            Column {
                width: 450 * uiScale; spacing: 12 * uiScale; anchors.horizontalCenter: parent.horizontalCenter
                Rectangle {
                    width: parent.width; height: 6 * uiScale; radius: 3 * uiScale; color: Qt.rgba(1,1,1,0.1)
                    Rectangle {
                        width: parent.width * progress; height: parent.height; radius: 3 * uiScale
                        gradient: Gradient { GradientStop { position: 0; color: "#667eea" } GradientStop { position: 1; color: "#764ba2" } }
                    }
                    Rectangle {
                        id: progressHandle
                        x: parent.width * progress - 8 * uiScale; y: -5 * uiScale; width: 16 * uiScale; height: 16 * uiScale; radius: 8 * uiScale; color: "#FFFFFF"
                        visible: mediaPlayer.duration > 0
                        MouseArea {
                            anchors.fill: parent; drag.target: parent; drag.axis: Drag.XAxis
                            drag.minimumX: -8 * uiScale; drag.maximumX: parent.parent.width - 8 * uiScale
                            onPositionChanged: if (drag.active) setProgress((progressHandle.x + 8 * uiScale) / parent.parent.width)
                        }
                    }
                }
                Row {
                    width: parent.width
                    Text { text: formatTime(mediaPlayer.position); font.pixelSize: 16 * uiScale; color: Qt.rgba(1,1,1,0.5) }
                    Item { width: parent.width - 80 * uiScale; height: 1 }
                    Text { text: formatTime(mediaPlayer.duration); font.pixelSize: 16 * uiScale; color: Qt.rgba(1,1,1,0.5) }
                }
            }

            Row {
                spacing: 40 * uiScale; anchors.horizontalCenter: parent.horizontalCenter
                Rectangle {
                    width: 56 * uiScale; height: 56 * uiScale; radius: 28 * uiScale
                    color: prevBtnArea.pressed ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.08)
                    enabled: playlistModel.count > 0
                    PrevIcon { anchors.centerIn: parent; iconSize: 20 * uiScale; iconColor: parent.enabled ? "#FFFFFF" : Qt.rgba(1,1,1,0.3) }
                    MouseArea { id: prevBtnArea; anchors.fill: parent; onClicked: if (parent.enabled) previousTrack() }
                }
                Rectangle {
                    width: 80 * uiScale; height: 80 * uiScale; radius: 40 * uiScale; color: "#667eea"
                    enabled: playlistModel.count > 0
                    Loader {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: isPlaying ? 0 : 3 * uiScale
                        sourceComponent: isPlaying ? pauseComp : playComp
                    }
                    Component { id: playComp; PlayIcon { iconSize: 28 * uiScale; iconColor: "#FFFFFF" } }
                    Component { id: pauseComp; PauseIcon { iconSize: 28 * uiScale; iconColor: "#FFFFFF" } }
                    MouseArea { id: playBtnArea; anchors.fill: parent; onClicked: if (parent.enabled) togglePlayback() }
                    scale: playBtnArea.pressed ? 0.95 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }
                Rectangle {
                    width: 56 * uiScale; height: 56 * uiScale; radius: 28 * uiScale
                    color: nextBtnArea.pressed ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.08)
                    enabled: playlistModel.count > 0
                    NextIcon { anchors.centerIn: parent; iconSize: 20 * uiScale; iconColor: parent.enabled ? "#FFFFFF" : Qt.rgba(1,1,1,0.3) }
                    MouseArea { id: nextBtnArea; anchors.fill: parent; onClicked: if (parent.enabled) nextTrack() }
                }
            }
        }

        Rectangle { width: 1 * uiScale; height: 600 * uiScale; color: Qt.rgba(1,1,1,0.1); anchors.verticalCenter: parent.verticalCenter }

        Column {
            spacing: 20 * uiScale
            width: 500 * uiScale

            Row {
                width: parent.width; height: 40 * uiScale; spacing: 10 * uiScale
                Text { text: "播放列表 (" + playlistModel.count + ")"; font.pixelSize: 26 * uiScale; font.weight: Font.Medium; font.letterSpacing: 2; color: "#FFFFFF"; anchors.verticalCenter: parent.verticalCenter }
                Item { width: parent.width - 280 * uiScale; height: 1 }
                Row {
                    spacing: 8 * uiScale; anchors.verticalCenter: parent.verticalCenter
                    Text { text: "包含子文件夹"; font.pixelSize: 16 * uiScale; color: Qt.rgba(1,1,1,0.6) }
                    Rectangle {
                        width: 44 * uiScale; height: 24 * uiScale; radius: 12 * uiScale
                        color: recursiveScanEnabled ? "#667eea" : Qt.rgba(1,1,1,0.2)
                        Rectangle { width: 20 * uiScale; height: 20 * uiScale; radius: 10 * uiScale; color: "#FFFFFF"; x: recursiveScanEnabled ? parent.width - width - 2 * uiScale : 2 * uiScale; Behavior on x { NumberAnimation { duration: 150 } } }
                        MouseArea { anchors.fill: parent; onClicked: recursiveScanEnabled = !recursiveScanEnabled }
                    }
                }
                Rectangle {
                    width: 40 * uiScale; height: 40 * uiScale; radius: 8 * uiScale
                    color: clearBtnArea.pressed ? "#ef4444" : Qt.rgba(239,68,68,0.2)
                    enabled: playlistModel.count > 0
                    TrashIcon { anchors.centerIn: parent; iconSize: 18 * uiScale; iconColor: parent.enabled ? "#ef4444" : Qt.rgba(239,68,68,0.3) }
                    MouseArea { id: clearBtnArea; anchors.fill: parent; onClicked: clearPlaylist() }
                }
            }

            Rectangle {
                width: parent.width; height: 550 * uiScale; color: Qt.rgba(1,1,1,0.03); radius: 12 * uiScale

                ListView {
                    anchors.fill: parent; anchors.margins: 10 * uiScale; spacing: 8 * uiScale; clip: true
                    model: playlistModel; currentIndex: root.currentIndex
                    delegate: Rectangle {
                        width: ListView.view.width; height: 70 * uiScale; radius: 16 * uiScale
                        color: playing ? Qt.rgba(102/255,126/255,234/255,0.15) : (index % 2 ? Qt.rgba(1,1,1,0.01) : Qt.rgba(1,1,1,0.03))
                        border.color: playing ? Qt.rgba(102/255,126/255,234/255,0.3) : "transparent"
                        border.width: 1 * uiScale

                        Row {
                            anchors.fill: parent; anchors.margins: 16 * uiScale; spacing: 16 * uiScale
                            Rectangle {
                                width: 40 * uiScale; height: 40 * uiScale; radius: 20 * uiScale
                                color: playing ? "#667eea" : Qt.rgba(1,1,1,0.1)
                                anchors.verticalCenter: parent.verticalCenter
                                Loader {
                                    anchors.centerIn: parent
                                    sourceComponent: playing ? playingComp : numComp
                                }
                                Component { id: playingComp; PlayIcon { iconSize: 14 * uiScale; iconColor: "#FFFFFF" } }
                                Component { id: numComp; Text { text: index + 1; font.pixelSize: 18 * uiScale; color: Qt.rgba(1,1,1,0.5) } }
                            }
                            Column {
                                spacing: 4 * uiScale; anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 140 * uiScale
                                Text { text: title; font.pixelSize: 20 * uiScale; font.weight: playing ? Font.Medium : Font.Normal; color: playing ? "#FFFFFF" : Qt.rgba(1,1,1,0.8); elide: Text.ElideRight; width: parent.width }
                                Text { text: artist; font.pixelSize: 17 * uiScale; color: Qt.rgba(1,1,1,0.5) }
                            }
                            Rectangle {
                                width: 30 * uiScale; height: 30 * uiScale; radius: 15 * uiScale
                                color: removeBtnArea.pressed ? "#ef4444" : Qt.rgba(239,68,68,0.1)
                                anchors.verticalCenter: parent.verticalCenter
                                CloseIcon { anchors.centerIn: parent; iconSize: 14 * uiScale; iconColor: "#ef4444" }
                                MouseArea { id: removeBtnArea; anchors.fill: parent; onClicked: removeFromPlaylist(index) }
                            }
                        }
                        MouseArea { anchors.fill: parent; onClicked: playTrack(index) }
                    }

                    ScrollBar.vertical: ScrollBar {
                        width: 6 * uiScale; policy: ScrollBar.AsNeeded
                        contentItem: Rectangle { implicitWidth: 6 * uiScale; radius: 3 * uiScale; color: Qt.rgba(1,1,1,0.2) }
                    }
                }

                Column {
                    anchors.centerIn: parent; spacing: 20 * uiScale; visible: playlistModel.count === 0
                    EmptyFolderIcon { iconSize: 80 * uiScale; iconColor: Qt.rgba(1,1,1,0.3); anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: isScanning ? "正在扫描音乐文件..." : "播放列表为空"; font.pixelSize: 24 * uiScale; color: Qt.rgba(1,1,1,0.5); anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: isScanning ? "请稍候..." : "点击左侧按钮扫描音乐文件夹"; font.pixelSize: 18 * uiScale; color: Qt.rgba(1,1,1,0.3); anchors.horizontalCenter: parent.horizontalCenter }
                }
            }
        }
    }

    Row {
        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottomMargin: 30 * uiScale; spacing: 20 * uiScale
        VolumeIcon { iconSize: 24 * uiScale; iconColor: Qt.rgba(1,1,1,0.7); level: volumeLevel; anchors.verticalCenter: parent.verticalCenter }
        Rectangle {
            width: 200 * uiScale; height: 6 * uiScale; radius: 3 * uiScale; color: Qt.rgba(1,1,1,0.1); anchors.verticalCenter: parent.verticalCenter
            Rectangle { width: parent.width * volumeLevel; height: parent.height; radius: 3 * uiScale; color: "#667eea" }
            MouseArea { anchors.fill: parent; onClicked: mouse => setVolume(mouse.x / width) }
        }
        Text { text: Math.round(volumeLevel * 100) + "%"; font.pixelSize: 18 * uiScale; color: Qt.rgba(1,1,1,0.5); anchors.verticalCenter: parent.verticalCenter }
    }

    Component.onCompleted: autoScanTimer.start()
}
