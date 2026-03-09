#include "SerialWorker.h"
#include <QDebug>

SerialWorker::SerialWorker(QObject *parent)
    : QObject(parent)
    , m_serial(nullptr)
    , m_weatherReceived(false)
    , m_lastReverseState(false)
    , m_requestTimer(new QTimer(this))
{
    memset(&m_weather, 0, sizeof(WeatherInfo));
    memset(&m_car, 0, sizeof(CarInfo));

    // 添加定时器连接
    connect(m_requestTimer, &QTimer::timeout, this, &SerialWorker::requestWeatherData);
}

SerialWorker::~SerialWorker()
{
    stopWork();
}

void SerialWorker::startWork(const QString &portName, int baudRate)
{
    if (m_serial) {
        stopWork();
    }

    m_serial = new QSerialPort(this);
    m_serial->setPortName(portName);
    m_serial->setBaudRate(baudRate);
    m_serial->setDataBits(QSerialPort::Data8);
    m_serial->setParity(QSerialPort::NoParity);
    m_serial->setStopBits(QSerialPort::OneStop);
    m_serial->setFlowControl(QSerialPort::NoFlowControl);

    connect(m_serial, &QSerialPort::readyRead, this, &SerialWorker::onReadyRead);
    connect(m_serial, &QSerialPort::errorOccurred, this, &SerialWorker::onErrorOccurred);

    if (m_serial->open(QIODevice::ReadWrite)) {
        qDebug() << "Serial port opened:" << portName;

        // 重置状态并启动请求定时器
        m_weatherReceived = false;
        m_requestTimer->start(100);  // 每 100ms 请求一次

        emit connected();
    } else {
        emit errorOccurred(tr("无法打开串口: %1").arg(m_serial->errorString()));
    }
}

void SerialWorker::stopWork()
{
    m_requestTimer->stop();  // 添加这行

    if (m_serial) {
        if (m_serial->isOpen()) {
            m_serial->close();
        }
        m_serial->deleteLater();
        m_serial = nullptr;
        emit disconnected();
    }
    m_buffer.clear();
}

void SerialWorker::onReadyRead()
{
    if (!m_serial) return;

    m_buffer.append(m_serial->readAll());
    parseBuffer();
}

void SerialWorker::onErrorOccurred(QSerialPort::SerialPortError error)
{
    if (error != QSerialPort::NoError) {
        emit errorOccurred(m_serial->errorString());
    }
}

void SerialWorker::parseBuffer()
{
    // 最小包长度: HEAD1 + HEAD2 + TYPE + LEN + CHECK + TAIL = 6
    while (m_buffer.size() >= 6) {
        // 查找帧头
        int headIndex = -1;
        for (int i = 0; i < m_buffer.size() - 1; i++) {
            if ((uint8_t)m_buffer.at(i) == PACKET_HEAD1 &&
                (uint8_t)m_buffer.at(i + 1) == PACKET_HEAD2) {
                headIndex = i;
                break;
            }
        }

        if (headIndex == -1) {
            // 没找到帧头，保留最后一个字节（可能是不完整的帧头）
            m_buffer = m_buffer.right(1);
            return;
        }

        // 丢弃帧头之前的数据
        if (headIndex > 0) {
            m_buffer.remove(0, headIndex);
        }

        // 检查是否有足够的数据读取类型和长度
        if (m_buffer.size() < 4) {
            return; // 等待更多数据
        }

        uint8_t type = (uint8_t)m_buffer.at(2);
        uint8_t len = (uint8_t)m_buffer.at(3);

        // 计算完整包长度
        int packetLen = 4 + len + 2; // HEAD(2) + TYPE(1) + LEN(1) + DATA(len) + CHECK(1) + TAIL(1)

        if (m_buffer.size() < packetLen) {
            return; // 等待更多数据
        }

        // 检查帧尾
        if ((uint8_t)m_buffer.at(packetLen - 1) != PACKET_TAIL) {
            // 帧尾错误，丢弃这个帧头，继续查找
            m_buffer.remove(0, 2);
            continue;
        }

        // 提取数据
        QByteArray data = m_buffer.mid(4, len);
        uint8_t receivedCheck = (uint8_t)m_buffer.at(4 + len);
        uint8_t calculatedCheck = calculateChecksum(type, len, data);

        if (receivedCheck == calculatedCheck) {
            // 校验通过，解析数据
            QByteArray packet = m_buffer.left(packetLen);
            parsePacket(packet);
        } else {
            qDebug() << "Checksum error! Received:" << receivedCheck << "Calculated:" << calculatedCheck;
        }

        // 移除已处理的包
        m_buffer.remove(0, packetLen);
    }
}

uint8_t SerialWorker::calculateChecksum(uint8_t type, uint8_t len, const QByteArray &data)
{
    uint8_t check = type ^ len;
    for (int i = 0; i < data.size(); i++) {
        check ^= (uint8_t)data.at(i);
    }
    return check;
}
// 删除 sendStopWeatherCommand，替换为：
void SerialWorker::requestWeatherData()
{
    if (!m_serial || !m_serial->isOpen()) return;
    if (m_weatherReceived) {
        m_requestTimer->stop();  // 收到天气数据后停止请求
        return;
    }

    QByteArray packet;
    packet.append((char)PACKET_HEAD1);
    packet.append((char)PACKET_HEAD2);
    packet.append((char)TYPE_REQUEST_WEATHER);
    packet.append((char)0);  // len=0
    uint8_t check = TYPE_REQUEST_WEATHER ^ 0;
    packet.append((char)check);
    packet.append((char)PACKET_TAIL);

    m_serial->write(packet);
    m_serial->flush();
}

bool SerialWorker::parsePacket(const QByteArray &packet)
{
    if (packet.size() < 6) return false;

    uint8_t type = (uint8_t)packet.at(2);
    uint8_t len = (uint8_t)packet.at(3);
    QByteArray data = packet.mid(4, len);

    if (type == TYPE_WEATHER && len == sizeof(WeatherInfo)) {
        QMutexLocker locker(&m_mutex);
        memcpy(&m_weather, data.constData(), sizeof(WeatherInfo));
        m_weatherReceived = true;  // 标记已收到
        locker.unlock();

        qDebug() << "Weather received - Type:" << m_weather.weather;

        emit weatherDataReceived(m_weather);

        // sendStopWeatherCommand();


        return true;
    }
    else if (type == TYPE_CAR && len == sizeof(CarInfo)) {
        QMutexLocker locker(&m_mutex);
        memcpy(&m_car, data.constData(), sizeof(CarInfo));

        bool currentReverse = (m_car.reverseState != 0);
        bool reverseChanged = (currentReverse != m_lastReverseState);
        m_lastReverseState = currentReverse;
        locker.unlock();

        emit carDataReceived(m_car);

        if (reverseChanged) {
            emit reverseStateChanged(currentReverse);
        }
        return true;
    }

    return false;
}

WeatherInfo SerialWorker::getWeatherInfo()
{
    QMutexLocker locker(&m_mutex);
    return m_weather;
}

CarInfo SerialWorker::getCarInfo()
{
    QMutexLocker locker(&m_mutex);
    return m_car;
}
