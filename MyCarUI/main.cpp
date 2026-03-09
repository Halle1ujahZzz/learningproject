#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QTimer>
#include <QDebug>
#include "SerialHandler.h"
#include "HistoryDatabase.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);


    SerialHandler serialHandler;
    HistoryDatabase *historyDB = new HistoryDatabase(&app);

    // ⭐ 立即初始化数据库
    qDebug() << "========================================";
    qDebug() << "初始化历史数据库...";

    if (!historyDB->initDatabase()) {
        qWarning() << "❌ 数据库初始化失败！";
    } else {
        qDebug() << "✅ 数据库初始化成功，当前记录数:" << historyDB->count();
    }
    qDebug() << "========================================";

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty("historyDB", historyDB);
    engine.rootContext()->setContextProperty("SerialHandler", &serialHandler);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("MyCarUI", "Main");

    QTimer::singleShot(500, [&]() {
        serialHandler.connectPort("/dev/ttyACM0", 115200);
    });

    return app.exec();
}
