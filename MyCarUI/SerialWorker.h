#ifndef SERIALWORKER_H
#define SERIALWORKER_H

#include <QObject>
#include <QSerialPort>
#include <QByteArray>
#include <QMutex>
#include <QTimer>
static const uint8_t TYPE_STOP_WEATHER = 0x03;
static const uint8_t TYPE_REQUEST_WEATHER = 0x04;

#pragma pack(push, 1)
struct WeatherInfo {
    char weather;
    int32_t perceivedTemperature;
    int32_t humidity;
    int32_t morningTemperature;
    int32_t eveningTemperature;
};

struct CarInfo {
    int32_t speed;
    float rotationalSpeed;
    int32_t fuelCapacity;
    int32_t batteryCapacity;
    uint8_t reverseState;
    int32_t temperature;
};
#pragma pack(pop)

class SerialWorker : public QObject
{
    Q_OBJECT

public:
    explicit SerialWorker(QObject *parent = nullptr);
    ~SerialWorker();

    // 获取数据接口
    WeatherInfo getWeatherInfo();
    CarInfo getCarInfo();
    bool isWeatherReceived() const { return m_weatherReceived; }

public slots:
    void startWork(const QString &portName, int baudRate);
    void stopWork();

signals:
    // 数据更新信号
    void weatherDataReceived(const WeatherInfo &weather);
    void carDataReceived(const CarInfo &car);
    void reverseStateChanged(bool isReverse);
    void errorOccurred(const QString &error);
    void connected();
    void disconnected();

private slots:
    void onReadyRead();
    void onErrorOccurred(QSerialPort::SerialPortError error);
    void requestWeatherData();
private:
    void parseBuffer();
    bool parsePacket(const QByteArray &packet);
    uint8_t calculateChecksum(uint8_t type, uint8_t len, const QByteArray &data);

private:
    QSerialPort *m_serial;
    QByteArray m_buffer;
    QTimer *m_requestTimer;  // 请求天气的定时器

    WeatherInfo m_weather;
    CarInfo m_car;
    bool m_weatherReceived;
    bool m_lastReverseState;

    mutable QMutex m_mutex;

    // 协议常量
    static const uint8_t PACKET_HEAD1 = 0xAA;
    static const uint8_t PACKET_HEAD2 = 0x55;
    static const uint8_t PACKET_TAIL = 0xEE;
    static const uint8_t TYPE_WEATHER = 0x01;
    static const uint8_t TYPE_CAR = 0x02;
};

#endif // SERIALWORKER_H
