import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform 1.1
import com.serial 1.0

ApplicationWindow {
    id: window
    width: 1100
    height: 750
    visible: true
    title: "✨ 串口调试助手 - Wz Blue Protocol ✨"

    font.family: "Segoe UI Emoji, 'Microsoft YaHei', 'Noto Sans', sans-serif"

    Rectangle {
        anchors.fill: parent
        color: "#050b1a"
        Image {
            id: backgroundImage
            source: "qrc:/bg.jpg"
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            opacity: 0.25
            asynchronous: true
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#0f172a88" }
                GradientStop { position: 1.0; color: "#020617cc" }
            }
        }
    }

    function getCurrentTime() {
        return "[" + Qt.formatDateTime(new Date(), "hh:mm:ss.zzz") + "] "
    }

    function stringToHex(str) {
        var hex = ""
        for(var i=0; i<str.length; i++) {
            var c = str.charCodeAt(i).toString(16).toUpperCase()
            hex += (c.length < 2 ? "0" + c : c) + " "
        }
        return hex.trim()
    }

    function sendAction(isAuto) {
        var msg = sendInput.text
        if (msg === "") return
        serialBackend.sendData(msg)
        if (showSendCheck.checked) {
            let timePrefix = showTimeCheck.checked ? getCurrentTime() : ""
            let logMsg = asciiMode.checked ? msg : stringToHex(msg)
            displayArea.append("<font color='#7dd3fc'>" + timePrefix + "</font>" +
                               "<font color='#c084fc'><b>[TX]</b></font> " +
                               "<font color='#ffffff'>" + logMsg + "</font>")
        }
        if (!isAuto) sendInput.clear()
    }

    SerialHandler {
        id: serialBackend
        onDataReceived: (data) => {
            let timePrefix = showTimeCheck.checked ? getCurrentTime() : ""
            let displayData = asciiMode.checked ? data : stringToHex(data)
            displayArea.append("<font color='#7dd3fc'>" + timePrefix + "</font>" +
                               "<font color='#22d3ee'><b>[RX]</b></font> " +
                               "<font color='#ffffff'>" + displayData + "</font>")
        }
    }

    Timer {
        id: repeatTimer
        interval: parseInt(repeatIntervalInput.text) || 1000
        repeat: true
        running: repeatCheck.checked && serialBackend.isOpen
        onTriggered: sendAction(true)
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
        id: mainToolbar
        background: Rectangle {
            color: "#0f172a"
            border.color: "#1e293b"
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#38bdf8"; opacity: 0.6 }
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 15
            Button {
                id: openBtn
                text: serialBackend.isOpen ? "💠 断开连接" : "🔹 启动串口"
                flat: true
                contentItem: Text {
                    text: openBtn.text
                    color: serialBackend.isOpen ? "#fb7185" : "#38bdf8"
                    font.bold: true; verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    if(!serialBackend.isOpen) {
                        serialBackend.openPort(
                            portBox.currentText,
                            parseInt(baudBox.editText),
                            parseInt(dataBitsBox.currentText),
                            stopBitsBox.currentIndex,
                            parityBox.currentIndex,
                            flowControlBox.currentIndex
                        )
                    } else {
                        serialBackend.closePort()
                    }
                }
            }
            ToolSeparator { contentItem: Rectangle { implicitWidth: 1; color: "#38bdf8"; opacity: 0.3 } }
            Button {
                id: exportBtn
                text: "📂 导出数据"; flat: true; enabled: displayArea.length > 0
                contentItem: Text { text: exportBtn.text; color: exportBtn.enabled ? "#f1f5f9" : "#475569" }
                onClicked: exportDialog.open()
            }
            Button {
                id: clearBtn
                text: "🧹 清除接收"; flat: true
                contentItem: Text { text: clearBtn.text; color: "#f1f5f9" }
                onClicked: displayArea.clear()
            }
            Item { Layout.fillWidth: true }
            Text { text: "NEON BLUE PROTOCOL "; color: "#38bdf8"; font.italic: true; opacity: 0.8; Layout.rightMargin: 20 }
        }
    }

    SplitView {
        anchors.fill: parent
        anchors.margins: 15
        orientation: Qt.Horizontal

        ColumnLayout {
            SplitView.preferredWidth: 260
            SplitView.fillWidth: false
            spacing: 15

            GroupBox {
                id: configGroup
                title: "💠 串口设置"; Layout.fillWidth: true
                background: Rectangle { color: "#0f172ae6"; radius: 12; border.color: "#38bdf8"; border.width: 1 }
                label: Text { text: configGroup.title; color: "#38bdf8"; font.bold: true; padding: 5 }
                GridLayout {
                    anchors.fill: parent
                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 8

                    Label { text: "串口号:"; color: "#bae6fd" }
                    ComboBox {
                        id: portBox; Layout.fillWidth: true
                        model: serialBackend.getPortList()
                        onPressedChanged: { if(pressed) model = serialBackend.getPortList() }
                    }

                    Label { text: "波特率:"; color: "#bae6fd" }
                    ComboBox {
                        id: baudBox; Layout.fillWidth: true
                        model: ["9600", "115200", "57600", "19200", "Custom"]
                        currentIndex: 1
                        editable: currentText === "Custom"
                        validator: IntValidator { bottom: 0; top: 10000000 }
                        onCurrentTextChanged: {
                            if (currentText !== "Custom") editText = currentText
                            else { editText = ""; focus = true }
                        }
                    }

                    Label { text: "数据位:"; color: "#bae6fd" }
                    ComboBox {
                        id: dataBitsBox; Layout.fillWidth: true
                        model: ["8", "7", "6", "5"]
                        currentIndex: 0
                    }

                    Label { text: "停止位:"; color: "#bae6fd" }
                    ComboBox {
                        id: stopBitsBox; Layout.fillWidth: true
                        model: ["1", "1.5", "2"]
                        currentIndex: 0
                    }

                    Label { text: "校验位:"; color: "#bae6fd" }
                    ComboBox {
                        id: parityBox; Layout.fillWidth: true
                        model: ["None", "Even", "Odd", "Space", "Mark"]
                        currentIndex: 0
                    }

                    Label { text: "流控:"; color: "#bae6fd" }
                    ComboBox {
                        id: flowControlBox; Layout.fillWidth: true
                        model: ["None", "Hardware", "Software"]
                        currentIndex: 0
                    }
                }
            }

            GroupBox {
                id: paramGroup
                title: "💎 收发参数"; Layout.fillWidth: true
                background: Rectangle { color: "#0f172ae6"; radius: 12; border.color: "#38bdf8"; border.width: 1 }
                label: Text { text: paramGroup.title; color: "#38bdf8"; font.bold: true; padding: 5 }
                ColumnLayout {
                    CheckBox { id: showSendCheck; text: "显示发送"; checked: true; palette.windowText: "#f1f5f9" }
                    CheckBox { id: showTimeCheck; text: "显示时间"; checked: true; palette.windowText: "#f1f5f9" }
                    CheckBox { id: asciiMode; text: "ASCII 模式"; checked: true; palette.windowText: "#f1f5f9" }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#38bdf8"; opacity: 0.3 }
                    CheckBox { id: repeatCheck; text: "周期发送"; palette.windowText: "#f1f5f9" }
                    RowLayout {
                        TextField {
                            id: repeatIntervalInput; text: "1000"; enabled: repeatCheck.checked; Layout.fillWidth: true
                            color: "white"; background: Rectangle { radius: 6; border.color: "#38bdf8"; color: "#1e293b" }
                            validator: IntValidator { bottom: 10; top: 60000 }
                        }
                        Label { text: "ms"; color: "#38bdf8" }
                    }
                }
            }
            Item { Layout.fillHeight: true }
        }

        ColumnLayout {
            SplitView.fillWidth: true
            spacing: 15

            GroupBox {
                id: monitorGroup
                title: "🛰️ 监控数据流"; Layout.fillWidth: true; Layout.fillHeight: true
                background: Rectangle { color: "#0f172af2"; radius: 15; border.color: "#38bdf8" }
                label: Text { text: monitorGroup.title; color: "#38bdf8"; font.bold: true; padding: 5 }
                ScrollView {
                    id: receiveScrollView; anchors.fill: parent; clip: true
                    TextArea {
                        id: displayArea; readOnly: true; textFormat: TextEdit.RichText
                        font.family: "Consolas, 'Courier New', monospace"
                        font.pixelSize: 14; color: "#ffffff"
                        wrapMode: TextArea.WrapAnywhere; background: null
                        onTextChanged: {
                            receiveScrollView.ScrollBar.vertical.position = 1.0 - receiveScrollView.ScrollBar.vertical.size
                        }
                    }
                }
            }

            GroupBox {
                id: inputGroup
                title: "⌨️ 发送窗口"; Layout.fillWidth: true; Layout.preferredHeight: 120
                background: Rectangle { color: "#0f172af2"; radius: 15; border.color: "#38bdf8" }
                label: Text { text: inputGroup.title; color: "#38bdf8"; font.bold: true; padding: 5 }
                RowLayout {
                    anchors.fill: parent; anchors.margins: 5
                    TextArea {
                        id: sendInput; Layout.fillWidth: true; Layout.fillHeight: true
                        color: "#ffffff"; wrapMode: TextArea.WrapAnywhere
                        placeholderText: asciiMode.checked ? "输入并回车发送..." : "输入十六进制..."
                        background: Rectangle { radius: 8; color: "#1e293b"; border.color: "#334155" }
                        Keys.onPressed: (event) => {
                            if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
                                if (serialBackend.isOpen) sendAction(false)
                                event.accepted = true
                            }
                        }
                    }
                    Button {
                        id: sendBtn
                        text: "发送 🚀"; Layout.fillHeight: true; Layout.preferredWidth: 80; enabled: serialBackend.isOpen
                        contentItem: Text {
                            text: sendBtn.text
                            font.bold: true; color: sendBtn.enabled ? "white" : "#475569"
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 10
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: sendBtn.enabled ? "#0ea5e9" : "#1e293b" }
                                GradientStop { position: 1.0; color: sendBtn.enabled ? "#2563eb" : "#0f172a" }
                            }
                        }
                        onClicked: sendAction(false)
                    }
                }
            }
        }
    }
}
