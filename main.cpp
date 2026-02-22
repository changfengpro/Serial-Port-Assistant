#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "serialhandler.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // 注册 C++ 类给 QML 使用
    qmlRegisterType<SerialHandler>("com.serial", 1, 0, "SerialHandler");

    QQmlApplicationEngine engine;

    // 修正后的路径加载方式，适配 Qt 6 项目结构
    const QUrl url(QStringLiteral("qrc:/qt/qml/SerialPortAssistant/Main.qml"));

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
