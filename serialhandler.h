#ifndef SERIALHANDLER_H
#define SERIALHANDLER_H

#include <QObject>
#include <QSerialPort>
#include <QSerialPortInfo>
#include <QFile>
#include <QTextStream>
#include <QDebug>

class SerialHandler : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isOpen READ isOpen NOTIFY statusChanged)

public:
    explicit SerialHandler(QObject *parent = nullptr) : QObject(parent) {
        m_serial = new QSerialPort(this);
        connect(m_serial, &QSerialPort::readyRead, this, [this](){
            QByteArray data = m_serial->readAll();
            if (!data.isEmpty()) {
                emit dataReceived(QString::fromUtf8(data));
            }
        });
        // 错误信号，便于调试
        connect(m_serial, &QSerialPort::errorOccurred, this, [this](QSerialPort::SerialPortError error){
            if (error != QSerialPort::NoError) {
                qDebug() << "SerialPort error:" << error;
            }
        });
    }

    bool isOpen() const { return m_serial->isOpen(); }

    // 返回带描述的端口列表，用于显示
    Q_INVOKABLE QStringList getPortDisplayList() {
        QStringList list;
        m_portInfoList = QSerialPortInfo::availablePorts();
        for (const QSerialPortInfo &info : m_portInfoList) {
            QString displayName = info.portName();
            QString desc = info.description();
            if (!desc.isEmpty()) {
                displayName += " (" + desc + ")";
            }
            list << displayName;
        }
        return list;
    }

    // 根据索引获取实际端口名
    Q_INVOKABLE QString getPortName(int index) {
        if (index >= 0 && index < m_portInfoList.size()) {
            return m_portInfoList.at(index).portName();
        }
        return QString();
    }

    // 兼容旧版：返回端口名列表（不带描述）
    Q_INVOKABLE QStringList getPortList() {
        QStringList list;
        m_portInfoList = QSerialPortInfo::availablePorts();
        for (const QSerialPortInfo &info : m_portInfoList) {
            list << info.portName();
        }
        return list;
    }

    // 简单版本（仅端口和波特率）
    Q_INVOKABLE bool openPort(QString name, int baud) {
        if (m_serial->isOpen()) m_serial->close();
        m_serial->setPortName(name);
        m_serial->setBaudRate(baud);
        m_serial->setDataBits(QSerialPort::Data8);
        m_serial->setStopBits(QSerialPort::OneStop);
        m_serial->setParity(QSerialPort::NoParity);
        m_serial->setFlowControl(QSerialPort::NoFlowControl);
        // 设置 DTR/RTS（在 Linux 下无害，Windows 下必需）
        m_serial->setDataTerminalReady(true);
        m_serial->setRequestToSend(true);
        if (m_serial->open(QIODevice::ReadWrite)) {
            m_serial->clear();                // 清空缓冲区
            m_serial->setReadBufferSize(65536);
            emit statusChanged();
            return true;
        }
        return false;
    }

    Q_INVOKABLE void closePort() {
        m_serial->close();
        emit statusChanged();
    }

    Q_INVOKABLE void sendData(QString data) {
        if (m_serial->isOpen()) {
            m_serial->write(data.toUtf8());
        }
    }

    Q_INVOKABLE bool saveToFile(const QString &filePath, const QString &content) {
        QFile file(filePath);
        if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
            QTextStream out(&file);
            out << content;
            file.close();
            return true;
        }
        return false;
    }

    // 完整参数版本（支持所有设置）
    Q_INVOKABLE bool openPort(QString name, int baud, int dataBits, int stopBits, int parity, int flow) {
        if (m_serial->isOpen()) m_serial->close();

        m_serial->setPortName(name);
        m_serial->setBaudRate(baud);

        // 数据位映射（传入值为 5/6/7/8，对应 Qt 枚举）
        QSerialPort::DataBits dataBitsEnum;
        switch (dataBits) {
        case 5: dataBitsEnum = QSerialPort::Data5; break;
        case 6: dataBitsEnum = QSerialPort::Data6; break;
        case 7: dataBitsEnum = QSerialPort::Data7; break;
        case 8: dataBitsEnum = QSerialPort::Data8; break;
        default: dataBitsEnum = QSerialPort::Data8; break;
        }
        m_serial->setDataBits(dataBitsEnum);

        // 停止位映射（索引 0:1, 1:1.5, 2:2）
        QSerialPort::StopBits stopBitsEnum;
        if (stopBits == 0) stopBitsEnum = QSerialPort::OneStop;
        else if (stopBits == 1) stopBitsEnum = QSerialPort::OneAndHalfStop;
        else stopBitsEnum = QSerialPort::TwoStop;
        m_serial->setStopBits(stopBitsEnum);

        // 校验位映射（索引 0:None, 1:Even, 2:Odd, 3:Space, 4:Mark）
        QSerialPort::Parity parityEnum;
        switch (parity) {
        case 0: parityEnum = QSerialPort::NoParity; break;
        case 1: parityEnum = QSerialPort::EvenParity; break;
        case 2: parityEnum = QSerialPort::OddParity; break;
        case 3: parityEnum = QSerialPort::SpaceParity; break;
        case 4: parityEnum = QSerialPort::MarkParity; break;
        default: parityEnum = QSerialPort::NoParity; break;
        }
        m_serial->setParity(parityEnum);

        // 流控映射（索引 0:None, 1:Hardware, 2:Software）
        QSerialPort::FlowControl flowEnum;
        if (flow == 0) flowEnum = QSerialPort::NoFlowControl;
        else if (flow == 1) flowEnum = QSerialPort::HardwareControl;
        else flowEnum = QSerialPort::SoftwareControl;
        m_serial->setFlowControl(flowEnum);

        // 打开前设置 DTR/RTS（Windows 下必需）
        m_serial->setDataTerminalReady(true);
        m_serial->setRequestToSend(true);

        if (m_serial->open(QIODevice::ReadWrite)) {
            m_serial->clear();
            m_serial->setReadBufferSize(65536);
            emit statusChanged();
            return true;
        }
        return false;
    }

signals:
    void dataReceived(QString data);
    void statusChanged();

private:
    QSerialPort *m_serial;
    QList<QSerialPortInfo> m_portInfoList;  // 缓存端口信息，供 getPortName 使用
};

#endif // SERIALHANDLER_H
