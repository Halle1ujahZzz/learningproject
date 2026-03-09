#include "SerialHandler.h"
#include <QSerialPortInfo>
#include <QDebug>

SerialHandler::SerialHandler(QObject *parent)
    : QObject(parent)
    , m_workerThread(new QThread(this))
    , m_worker(new SerialWorker())
    , m_connected(false)
    , m_weatherReceived(false)
    , m_isReversing(false)
{
    memset(&m_weather, 0, sizeof(WeatherInfo));
    memset(&m_car, 0, sizeof(CarInfo));

    m_worker->moveToThread(m_workerThread);

    connect(m_workerThread, &QThread::finished, m_worker, &QObject::deleteLater);

    connect(m_worker, &SerialWorker::weatherDataReceived,
            this, &SerialHandler::onWeatherReceived, Qt::QueuedConnection);
    connect(m_worker, &SerialWorker::carDataReceived,
            this, &SerialHandler::onCarReceived, Qt::QueuedConnection);
    connect(m_worker, &SerialWorker::reverseStateChanged,
            this, &SerialHandler::onReverseChanged, Qt::QueuedConnection);
    connect(m_worker, &SerialWorker::connected,
            this, &SerialHandler::onConnected, Qt::QueuedConnection);
    connect(m_worker, &SerialWorker::disconnected,
            this, &SerialHandler::onDisconnected, Qt::QueuedConnection);
    connect(m_worker, &SerialWorker::errorOccurred,
            this, &SerialHandler::onError, Qt::QueuedConnection);

    m_workerThread->start();
}

SerialHandler::~SerialHandler()
{
    disconnectPort();
    m_workerThread->quit();
    m_workerThread->wait();
}

void SerialHandler::connectPort(const QString &portName, int baudRate)
{
    QMetaObject::invokeMethod(m_worker, "startWork",
                              Qt::QueuedConnection,
                              Q_ARG(QString, portName),
                              Q_ARG(int, baudRate));
}

void SerialHandler::disconnectPort()
{
    QMetaObject::invokeMethod(m_worker, "stopWork", Qt::QueuedConnection);
}

QStringList SerialHandler::availablePorts()
{
    QStringList ports;
    const auto infos = QSerialPortInfo::availablePorts();
    for (const QSerialPortInfo &info : infos) {
        ports << info.portName();
    }
    return ports;
}

QString SerialHandler::weatherType() const
{
    switch (m_weather.weather) {
    case 'S': return QStringLiteral("sunny");
    case 'C': return QStringLiteral("cloudy");
    case 'R': return QStringLiteral("rainy");
    default: return QStringLiteral("unknown");
    }
}

void SerialHandler::onWeatherReceived(const WeatherInfo &weather)
{
    m_weather = weather;

    if (!m_weatherReceived) {
        m_weatherReceived = true;
        emit weatherReceivedChanged();
    }

    qDebug() << "Weather received - Type:" << m_weather.weather
             << "Perceived:" << m_weather.perceivedTemperature
             << "Humidity:" << m_weather.humidity;

    emit weatherDataChanged();  // 固定天气信息更新（类型、体感、湿度、晨晚温）
}

void SerialHandler::onCarReceived(const CarInfo &car)
{
    m_car = car;
    emit carDataChanged();      // 汽车数据 + 实时温度更新
}

void SerialHandler::onReverseChanged(bool isReverse)
{
    if (m_isReversing != isReverse) {
        m_isReversing = isReverse;
        emit reverseStateChanged(isReverse);
    }
}

void SerialHandler::onConnected()
{
    m_connected = true;
    emit connectedChanged();
    qDebug() << "SerialHandler: Connected";
}

void SerialHandler::onDisconnected()
{
    m_connected = false;
    emit connectedChanged();
    qDebug() << "SerialHandler: Disconnected";
}

void SerialHandler::onError(const QString &error)
{
    qDebug() << "SerialHandler Error:" << error;
    emit errorOccurred(error);
}
