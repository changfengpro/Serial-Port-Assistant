#ifndef SERIALHANDLER_H
#define SERIALHANDLER_H

#include <QObject>
#include <QSerialPort>
#include <QSerialPortInfo>
#include <QFile>
#include <QTextStream>

class SerialHandler : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isOpen READ isOpen NOTIFY statusChanged)

public:
    explicit SerialHandler(QObject *parent = nullptr) : QObject(parent) {
        m_serial = new QSerialPort(this);
        connect(m_serial, &QSerialPort::readyRead, this, [this](){
            emit dataReceived(QString::fromUtf8(m_serial->readAll()));
        });
    }

    bool isOpen() const { return m_serial->isOpen(); }

    Q_INVOKABLE QStringList getPortList() {
        QStringList list;
        for (const QSerialPortInfo &info : QSerialPortInfo::availablePorts()) {
            list << info.portName();
        }
        return list;
    }

    // 简单版本（仅端口和波特率） - 保留兼容
    Q_INVOKABLE bool openPort(QString name, int baud) {
        if (m_serial->isOpen()) m_serial->close();
        m_serial->setPortName(name);
        m_serial->setBaudRate(baud);
        if (m_serial->open(QIODevice::ReadWrite)) {
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

    // 完整参数版本
    Q_INVOKABLE bool openPort(QString name, int baud, int dataBits, int stopBits, int parity, int flow) {
        if (m_serial->isOpen()) m_serial->close();

        m_serial->setPortName(name);
        m_serial->setBaudRate(baud);

        // 设置数据位
        m_serial->setDataBits(static_cast<QSerialPort::DataBits>(dataBits));

        // 设置停止位 (QML 索引对应: 0:1, 1:1.5, 2:2)
        if (stopBits == 0) m_serial->setStopBits(QSerialPort::OneStop);
        else if (stopBits == 1) m_serial->setStopBits(QSerialPort::OneAndHalfStop);
        else m_serial->setStopBits(QSerialPort::TwoStop);

        // 设置校验位 (QML 索引对应: 0:None, 1:Even, 2:Odd...)
        m_serial->setParity(static_cast<QSerialPort::Parity>(parity));

        // 设置流控 (QML 索引对应: 0:None, 1:Hardware, 2:Software)
        m_serial->setFlowControl(static_cast<QSerialPort::FlowControl>(flow));

        if (m_serial->open(QIODevice::ReadWrite)) {
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
};

#endif // SERIALHANDLER_H
