cmake_minimum_required(VERSION 3.16)

project(SerialPortAssistant VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTORCC ON)

# 添加所需的 Qt 组件：Quick, QuickControls2, SerialPort
find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 SerialPort)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appSerialPortAssistant
    main.cpp
    serialhandler.h
)

qt_add_qml_module(appSerialPortAssistant
    URI SerialPortAssistant
    QML_FILES
        Main.qml
    SOURCES serialhandler.h
    RESOURCES images.qrc
)

# 链接库（包含 QuickControls2）
target_link_libraries(appSerialPortAssistant
    PRIVATE Qt6::Quick
    PRIVATE Qt6::QuickControls2
    PRIVATE Qt6::SerialPort
)

# 可选：为 Windows 设置应用程序图标等（可忽略）
set_target_properties(appSerialPortAssistant PROPERTIES
    WIN32_EXECUTABLE TRUE
)

include(GNUInstallDirs)
install(TARGETS appSerialPortAssistant
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
