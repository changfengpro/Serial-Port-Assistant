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

signals:
    void dataReceived(QString data);
    void statusChanged();

private:
    QSerialPort *m_serial;
};

#endif
