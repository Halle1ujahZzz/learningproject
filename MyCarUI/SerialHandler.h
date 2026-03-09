#ifndef SERIALHANDLER_H
#define SERIALHANDLER_H

#include <QObject>
#include <QThread>
#include "SerialWorker.h"

class SerialHandler : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool connected READ isConnected NOTIFY connectedChanged)
    Q_PROPERTY(bool weatherReceived READ isWeatherReceived NOTIFY weatherReceivedChanged)
    Q_PROPERTY(bool isReversing READ isReversing NOTIFY reverseStateChanged)

    // 天气属性（固定部分，随 Weather 包更新一次）
    Q_PROPERTY(QString weatherType READ weatherType NOTIFY weatherDataChanged)
    Q_PROPERTY(int perceivedTemperature READ perceivedTemperature NOTIFY weatherDataChanged)
    Q_PROPERTY(int humidity READ humidity NOTIFY weatherDataChanged)
    Q_PROPERTY(int morningTemperature READ morningTemperature NOTIFY weatherDataChanged)
    Q_PROPERTY(int eveningTemperature READ eveningTemperature NOTIFY weatherDataChanged)

    // 实时温度（随 Car 包持续更新）
    Q_PROPERTY(int temperature READ temperature NOTIFY carDataChanged)

    // 汽车属性
    Q_PROPERTY(int speed READ speed NOTIFY carDataChanged)
    Q_PROPERTY(double rpm READ rpm NOTIFY carDataChanged)
    Q_PROPERTY(int fuelLevel READ fuelLevel NOTIFY carDataChanged)
    Q_PROPERTY(int batteryLevel READ batteryLevel NOTIFY carDataChanged)

public:
    explicit SerialHandler(QObject *parent = nullptr);
    ~SerialHandler();

    bool isConnected() const { return m_connected; }
    bool isWeatherReceived() const { return m_weatherReceived; }
    bool isReversing() const { return m_isReversing; }

    QString weatherType() const;

    // 实时温度从 CarInfo 读取
    int temperature() const { return m_car.temperature; }

    // 其他天气属性仍从 WeatherInfo 读取
    int perceivedTemperature() const { return m_weather.perceivedTemperature; }
    int humidity() const { return m_weather.humidity; }
    int morningTemperature() const { return m_weather.morningTemperature; }
    int eveningTemperature() const { return m_weather.eveningTemperature; }

    int speed() const { return m_car.speed; }
    double rpm() const { return static_cast<double>(m_car.rotationalSpeed); }
    int fuelLevel() const { return m_car.fuelCapacity; }
    int batteryLevel() const { return m_car.batteryCapacity; }

public slots:
    void connectPort(const QString &portName, int baudRate = 115200);
    void disconnectPort();
    QStringList availablePorts();

signals:
    void connectedChanged();
    void weatherReceivedChanged();
    void weatherDataChanged();     // 固定天气信息变化（类型、体感、湿度、晨晚温）
    void carDataChanged();         // 汽车数据 + 实时温度变化
    void reverseStateChanged(bool isReverse);
    void errorOccurred(const QString &error);

private slots:
    void onWeatherReceived(const WeatherInfo &weather);
    void onCarReceived(const CarInfo &car);
    void onReverseChanged(bool isReverse);
    void onConnected();
    void onDisconnected();
    void onError(const QString &error);

private:
    QThread *m_workerThread;

    SerialWorker *m_worker;

    bool m_connected;
    bool m_weatherReceived;
    bool m_isReversing;

    WeatherInfo m_weather;   // 不含 temperature
    CarInfo m_car;           // 含 temperature
};

#endif // SERIALHANDLER_H
