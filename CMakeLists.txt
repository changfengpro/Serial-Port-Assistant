cmake_minimum_required(VERSION 3.16)

project(SerialPortAssistant VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)
find_package(Qt6 REQUIRED COMPONENTS Gui Qml SerialPort)

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

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appSerialPortAssistant PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appSerialPortAssistant
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appSerialPortAssistant
    PRIVATE Qt6::Quick
    PRIVATE Qt6::Quick Qt6::SerialPort
)

include(GNUInstallDirs)
install(TARGETS appSerialPortAssistant
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)


set(CPACK_GENERATOR "DEB")
set(CPACK_PACKAGE_NAME "serial-port-assistant")
set(CPACK_PACKAGE_VERSION "1.0.0")
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "changfengpro")
set(CPACK_DEBIAN_PACKAGE_DEPENDS "libc6, libstdc++6, libqt6core6, libqt6widgets6, libqt6serialport6")# 填写基础依赖
include(CPack)
