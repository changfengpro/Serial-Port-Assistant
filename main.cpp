#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>          // 引入样式头文件
#include "serialhandler.h"

int main(int argc, char *argv[])
{
    // Qt 6 中以下高DPI属性已默认启用，无需显式设置
    // QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    // QGuiApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);

    QGuiApplication app(argc, argv);

    // 设置跨平台一致的控件样式（Fusion 风格在 Windows 下表现稳定）
    QQuickStyle::setStyle("Fusion");

    // 注册 C++ 类给 QML 使用
    qmlRegisterType<SerialHandler>("com.serial", 1, 0, "SerialHandler");

    QQmlApplicationEngine engine;
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
