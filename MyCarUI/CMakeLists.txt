cmake_minimum_required(VERSION 3.16)

project(MyCarUI VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick SerialPort)
find_package(Qt6 REQUIRED COMPONENTS Quick)
find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2)
find_package(Qt6 REQUIRED COMPONENTS WebEngineQuick)
find_package(Qt6 REQUIRED COMPONENTS Positioning)
find_package(Qt6 REQUIRED COMPONENTS WebChannel)
find_package(Qt6 REQUIRED COMPONENTS Quick Sql Core)
find_package(Qt6 REQUIRED COMPONENTS Quick Multimedia)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appMyCarUI
    main.cpp

    SerialHandler.cpp

    SerialWorker.cpp

    HistoryDatabase.cpp
)

qt_add_qml_module(appMyCarUI
    URI MyCarUI
    VERSION 1.0
    QML_FILES
        Main.qml
        pages/InstrumentPage.qml
        pages/HomePage.qml
        pages/NavigationPage.qml
        pages/VehicleControlPage.qml
        pages/TemperaturePage.qml
        pages/MusicPage.qml
        pages/HistoryPage.qml
        pages/ReversePage.qml
        SOURCES HistoryDatabase.h
        SOURCES HistoryDatabase.cpp

        SOURCES HistoryDatabase.cpp
        SOURCES
)

set_target_properties(appMyCarUI PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

qt_add_resources(appMyCarUI "html_resources"
    PREFIX "/"
    BASE html
    FILES
        html/map.html
)

target_link_libraries(appMyCarUI
    PRIVATE Qt6::Quick
    PRIVATE Qt6::SerialPort
    Qt6::QuickControls2
    Qt6::WebEngineQuick
    Qt6::Positioning
    Qt6::WebChannel
    Qt6::Sql
    Qt6::Core
    Qt6::Multimedia
)

# 设置目标属性
set_target_properties(appMyCarUI PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

# 复制HTML文件到构建目录（可选，用于调试）
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/html DESTINATION ${CMAKE_CURRENT_BINARY_DIR})


include(GNUInstallDirs)
install(TARGETS appMyCarUI
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
