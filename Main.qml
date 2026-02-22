import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform 1.1
import com.serial 1.0

ApplicationWindow {
    width: 900
    height: 600
    visible: true
    title: "Linux 串口调试助手"

    // --- 辅助函数 ---
    function getCurrentTime() {
        return "[" + Qt.formatDateTime(new Date(), "hh:mm:ss.zzz") + "] "
    }

    function stringToHex(str) {
        var hex = "";
        for(var i=0; i<str.length; i++) {
            var c = str.charCodeAt(i).toString(16).toUpperCase();
            hex += (c.length < 2 ? "0" + c : c) + " ";
        }
        return hex.trim();
    }

    SerialHandler {
        id: serialBackend
        onDataReceived: (data) => {
            let timePrefix = showTimeCheck.checked ? getCurrentTime() : ""
            let displayData = asciiMode.checked ? data : stringToHex(data)
            displayArea.append(timePrefix + "[RX] " + displayData)
        }
    }

    function sendAction() {
        var msg = sendInput.text
        if (msg === "") return
        serialBackend.sendData(msg)
        if (showSendCheck.checked) {
            let timePrefix = showTimeCheck.checked ? getCurrentTime() : ""
            let logMsg = asciiMode.checked ? msg : stringToHex(msg)
            displayArea.append(timePrefix + "[TX] " + logMsg)
        }
    }

    Timer {
        id: repeatTimer
        interval: parseInt(repeatIntervalInput.text) || 1000
        repeat: true
        running: repeatCheck.checked && serialBackend.isOpen
        onTriggered: sendAction()
    }

    FileDialog {
        id: exportDialog
        title: "导出接收区数据"
        fileMode: FileDialog.SaveFile
        nameFilters: ["文本文件 (*.txt)", "日志文件 (*.log)"]
        onAccepted: {
            let path = file.toString().replace("file://", "")
            serialBackend.saveToFile(path, displayArea.text)
        }
    }

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            ToolButton {
                text: serialBackend.isOpen ? "断开串口" : "连接串口"
                onClicked: {
                    if(!serialBackend.isOpen) {
                        serialBackend.openPort(portBox.currentText, parseInt(baudBox.editText))
                    } else {
                        serialBackend.closePort()
                    }
                }
            }
            ToolSeparator {}
            ToolButton {
                text: "导出数据"
                enabled: displayArea.length > 0
                onClicked: exportDialog.open()
            }
            ToolButton {
                text: "清除接收"
                onClicked: displayArea.clear()
            }
            Item { Layout.fillWidth: true }
        }
    }

    // 使用 SplitView 防止布局挤压，并允许手动调节窗口大小
    SplitView {
        anchors.fill: parent
        anchors.margins: 5
        orientation: Qt.Horizontal

        // --- 左侧：设置面板 (固定宽度，不会被挤压) ---
        ColumnLayout {
            SplitView.preferredWidth: 200
            SplitView.fillWidth: false
            spacing: 5

            GroupBox {
                title: "串口设置"
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    Label { text: "串口号:" }
                    ComboBox {
                        id: portBox
                        Layout.fillWidth: true
                        model: serialBackend.getPortList()
                        onPressedChanged: { if(pressed) model = serialBackend.getPortList() }
                    }
                    Label { text: "波特率:" }
                    ComboBox {
                        id: baudBox
                        Layout.fillWidth: true
                        model: ["9600", "115200", "57600", "38400", "Custom"]
                        currentIndex: 1
                        editable: currentIndex === model.length - 1
                    }
                }
            }

            GroupBox {
                title: "收发设置"
                Layout.fillWidth: true
                ColumnLayout {
                    CheckBox { id: showSendCheck; text: "显示发送"; checked: true }
                    CheckBox { id: showTimeCheck; text: "显示时间"; checked: true }
                    CheckBox { id: asciiMode; text: "ASCII模式"; checked: true }
                    CheckBox { id: repeatCheck; text: "周期发送" }
                    RowLayout {
                        TextField {
                            id: repeatIntervalInput
                            enabled: repeatCheck.checked
                            text: "1000"
                            Layout.fillWidth: true
                            validator: IntValidator { bottom: 10; top: 60000 }
                        }
                        Label { text: "ms" }
                    }
                }
            }
            Item { Layout.fillHeight: true }
        }

        // --- 右侧：数据收发区 ---
        ColumnLayout {
            SplitView.fillWidth: true
            spacing: 5

            GroupBox {
                title: "接收窗口"
                Layout.fillWidth: true
                Layout.fillHeight: true
                ScrollView {
                    id: receiveScrollView
                    anchors.fill: parent
                    clip: true
                    TextArea {
                        id: displayArea
                        readOnly: true
                        font.family: "Monospace"
                        font.pixelSize: 13
                        // 【关键修改】开启自动换行，防止撑开宽度挤压左侧
                        wrapMode: TextArea.WrapAnywhere
                        background: Rectangle { border.color: "#ddd" }
                        onTextChanged: {
                            receiveScrollView.ScrollBar.vertical.position = 1.0 - receiveScrollView.ScrollBar.vertical.size
                        }
                    }
                }
            }

            GroupBox {
                title: "发送窗口"
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                RowLayout {
                    anchors.fill: parent
                    TextArea {
                        id: sendInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: asciiMode.checked ? "输入字符串..." : "输入十六进制..."
                    }
                    Button {
                        text: "发送"
                        Layout.fillHeight: true
                        Layout.preferredWidth: 60
                        enabled: serialBackend.isOpen
                        onClicked: sendAction()
                    }
                }
            }
        }
    }
}
