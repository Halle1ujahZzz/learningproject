#include "HistoryDatabase.h"
#include <QDateTime>
#include <QCoreApplication>
#include <QDebug>
#include <QFileInfo>
#include <QRegularExpression>

HistoryDatabase::HistoryDatabase(QObject *parent)
    : QAbstractListModel(parent)
{
    m_syncTimer = new QTimer(this);
    connect(m_syncTimer, &QTimer::timeout, this, &HistoryDatabase::onAutoSyncTimeout);
}

HistoryDatabase::~HistoryDatabase()
{
    stopAutoSync();
    if (m_db.isOpen()) {
        m_db.close();
    }
}

int HistoryDatabase::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_historyList.count();
}

QVariant HistoryDatabase::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_historyList.count()) {
        return QVariant();
    }

    const HistoryData &item = m_historyList.at(index.row());

    switch (role) {
    case DateRole: return item.date;
    case FromRole: return item.from;
    case ToRole: return item.to;
    case DistRole: return item.dist;
    case TimeRole: return item.time;
    case SpeedRole: return item.speed;
    default: return QVariant();
    }
}

QHash<int, QByteArray> HistoryDatabase::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[DateRole] = "date";
    roles[FromRole] = "from";
    roles[ToRole] = "to";
    roles[DistRole] = "dist";
    roles[TimeRole] = "time";
    roles[SpeedRole] = "speed";
    return roles;
}

int HistoryDatabase::count() const
{
    return m_historyList.count();
}

void HistoryDatabase::startAutoSync(int intervalMs)
{
    if (!m_db.isOpen()) {
        qWarning() << "无法启动自动同步：数据库未打开";
        return;
    }

    if (m_syncTimer->isActive()) {
        m_syncTimer->stop();
    }
    m_syncTimer->start(intervalMs);
    qDebug() << "自动同步已启动，间隔:" << intervalMs << "ms";
}

void HistoryDatabase::stopAutoSync()
{
    if (m_db.isOpen() && m_syncTimer->isActive()) {
        m_syncTimer->stop();
        qDebug() << "自动同步已停止";
    }
}

bool HistoryDatabase::isAutoSync() const
{
    return m_syncTimer->isActive();
}

void HistoryDatabase::onAutoSyncTimeout()
{
    if (!m_db.isOpen()) {
        return;
    }

    QSqlQuery query(m_db);
    if (!query.exec("SELECT COUNT(*) FROM trips")) {
        qWarning() << "自动同步查询失败:" << query.lastError().text();
        return;
    }

    if (query.next()) {
        int dbCount = query.value(0).toInt();
        if (dbCount != m_historyList.count()) {
            qDebug() << "检测到数据库变化，刷新历史记录 (DB:" << dbCount << "内存:" << m_historyList.count() << ")";
            refreshHistory();
            emit dataChanged();
        }
    }
}

bool HistoryDatabase::initDatabase()
{
    QString path = dbPath();
    qDebug() << "正在初始化数据库，路径:" << path;

    QFileInfo fileInfo(path);
    QDir dir = fileInfo.dir();
    if (!dir.exists()) {
        qDebug() << "目录不存在，尝试创建:" << dir.absolutePath();
        if (!dir.mkpath(".")) {
            qWarning() << "❌ 无法创建数据库目录！";
            return false;
        }
        qDebug() << "✅ 目录创建成功";
    }

    if (QSqlDatabase::contains("qt_sql_default_connection")) {
        m_db = QSqlDatabase::database("qt_sql_default_connection");
        qDebug() << "使用现有数据库连接";
    } else {
        m_db = QSqlDatabase::addDatabase("QSQLITE");
        qDebug() << "创建新的SQLite数据库连接";
    }
    m_db.setDatabaseName(path);

    if (!m_db.open()) {
        qWarning() << "❌ 无法打开数据库！";
        qWarning() << "错误:" << m_db.lastError().text();
        return false;
    }

    qDebug() << "✅ 数据库打开成功";

    if (!createTable()) {
        qWarning() << "❌ 创建表失败！";
        return false;
    }

    qDebug() << "✅ 表创建/验证成功";

    refreshHistory();
    qDebug() << "✅ 初始刷新完成，当前记录数:" << m_historyList.count();

    startAutoSync(5000);

    return true;
}

bool HistoryDatabase::createTable()
{
    if (!m_db.isOpen()) {
        qWarning() << "createTable: 数据库未打开";
        return false;
    }

    QSqlQuery query(m_db);

    // 先检查表是否存在
    QString checkSql = "SELECT name FROM sqlite_master WHERE type='table' AND name='trips'";
    if (query.exec(checkSql) && query.next()) {
        // 表已存在，检查列结构
        QString checkColumnSql = "PRAGMA table_info(trips)";
        bool hasSpeedColumn = false;
        bool hasCostColumn = false;

        if (query.exec(checkColumnSql)) {
            while (query.next()) {
                QString colName = query.value(1).toString();
                if (colName == "speed") {
                    hasSpeedColumn = true;
                } else if (colName == "cost") {
                    hasCostColumn = true;
                }
            }
        }

        // 如果有cost列但没有speed列，需要迁移数据
        if (hasCostColumn && !hasSpeedColumn) {
            qDebug() << "检测到旧表结构，开始迁移数据...";

            m_db.transaction();

            // 1. 创建新表
            QString createNewTable = R"(
                CREATE TABLE trips_new (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    date TEXT NOT NULL,
                    from_place TEXT NOT NULL,
                    to_place TEXT NOT NULL,
                    dist TEXT NOT NULL,
                    time_ TEXT NOT NULL,
                    speed TEXT DEFAULT '--',
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            )";

            if (!query.exec(createNewTable)) {
                qWarning() << "创建新表失败:" << query.lastError().text();
                m_db.rollback();
                return false;
            }

            // 2. 复制数据（cost列映射到speed列，默认为'--'）
            QString copyData = R"(
                INSERT INTO trips_new (id, date, from_place, to_place, dist, time_, speed, timestamp)
                SELECT id, date, from_place, to_place, dist, time_, '--', timestamp FROM trips
            )";

            if (!query.exec(copyData)) {
                qWarning() << "复制数据失败:" << query.lastError().text();
                m_db.rollback();
                return false;
            }

            // 3. 删除旧表
            if (!query.exec("DROP TABLE trips")) {
                qWarning() << "删除旧表失败:" << query.lastError().text();
                m_db.rollback();
                return false;
            }

            // 4. 重命名新表
            if (!query.exec("ALTER TABLE trips_new RENAME TO trips")) {
                qWarning() << "重命名表失败:" << query.lastError().text();
                m_db.rollback();
                return false;
            }

            m_db.commit();
            qDebug() << "✅ 数据库迁移完成";
        }
        // 如果没有speed列也没有cost列，添加speed列
        else if (!hasSpeedColumn && !hasCostColumn) {
            qDebug() << "添加speed列到现有表";
            if (!query.exec("ALTER TABLE trips ADD COLUMN speed TEXT DEFAULT '--'")) {
                qWarning() << "添加speed列失败:" << query.lastError().text();
            }
        }
    } else {
        // 表不存在，创建新表（只包含speed列，不包含cost列）
        QString sql = R"(
            CREATE TABLE IF NOT EXISTS trips (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT NOT NULL,
                from_place TEXT NOT NULL,
                to_place TEXT NOT NULL,
                dist TEXT NOT NULL,
                time_ TEXT NOT NULL,
                speed TEXT DEFAULT '--',
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        )";

        if (!query.exec(sql)) {
            qWarning() << "创建表失败:" << query.lastError().text();
            return false;
        }
        qDebug() << "✅ 创建新表成功";
    }

    return true;
}

void HistoryDatabase::insertTrip(const QVariantMap &tripData)
{
    if (!m_db.isOpen()) {
        qWarning() << "insertTrip: 数据库未打开";
        return;
    }

    qDebug() << "正在插入行程记录...";
    qDebug() << "  日期:" << tripData["date"].toString();
    qDebug() << "  起点:" << tripData["from"].toString();
    qDebug() << "  终点:" << tripData["to"].toString();
    qDebug() << "  距离:" << tripData["dist"].toString();
    qDebug() << "  时长:" << tripData["time"].toString();
    qDebug() << "  速度:" << tripData["speed"].toString();

    QSqlQuery query(m_db);
    query.prepare(R"(
        INSERT INTO trips (date, from_place, to_place, dist, time_, speed)
        VALUES (:date, :from, :to, :dist, :time, :speed)
    )");
    query.bindValue(":date", tripData["date"].toString());
    query.bindValue(":from", tripData["from"].toString());
    query.bindValue(":to", tripData["to"].toString());
    query.bindValue(":dist", tripData["dist"].toString());
    query.bindValue(":time", tripData["time"].toString());
    query.bindValue(":speed", tripData.value("speed", "--").toString());

    if (!query.exec()) {
        qWarning() << "❌ 插入失败:" << query.lastError().text();
        return;
    }

    qDebug() << "✅ 行程记录插入成功";
    refreshHistory();
}

void HistoryDatabase::deleteTrip(int index)
{
    if (!m_db.isOpen()) {
        qWarning() << "deleteTrip: 数据库未打开";
        return;
    }

    if (index < 0 || index >= m_historyList.count()) {
        qWarning() << "deleteTrip: 无效的索引" << index;
        return;
    }

    // 获取要删除的记录信息
    const HistoryData &trip = m_historyList.at(index);

    qDebug() << "正在删除行程记录:" << trip.from << "->" << trip.to;

    // 从数据库删除（按时间戳匹配，因为我们按时间倒序排列）
    QSqlQuery query(m_db);
    query.prepare("DELETE FROM trips WHERE from_place = :from AND to_place = :to AND date = :date LIMIT 1");
    query.bindValue(":from", trip.from);
    query.bindValue(":to", trip.to);
    query.bindValue(":date", trip.date);

    if (!query.exec()) {
        qWarning() << "❌ 删除失败:" << query.lastError().text();
        return;
    }

    qDebug() << "✅ 行程记录删除成功";
    refreshHistory();
}

void HistoryDatabase::refreshHistory()
{
    if (!m_db.isOpen()) {
        qWarning() << "refreshHistory: 数据库未打开";
        return;
    }

    beginResetModel();
    m_historyList.clear();

    QSqlQuery query(m_db);
    QString sql = "SELECT date, from_place, to_place, dist, time_, speed FROM trips ORDER BY timestamp DESC LIMIT 50";

    if (!query.exec(sql)) {
        qWarning() << "查询失败:" << query.lastError().text();
        endResetModel();
        return;
    }

    int count = 0;
    while (query.next()) {
        HistoryData data;
        data.date = query.value("date").toString();
        data.from = query.value("from_place").toString();
        data.to = query.value("to_place").toString();
        data.dist = query.value("dist").toString();
        data.time = query.value("time_").toString();
        data.speed = query.value("speed").toString();

        m_historyList.append(data);
        count++;
    }

    endResetModel();

    if (count > 0) {
        qDebug() << "刷新历史记录: 加载了" << count << "条记录";
    }

    emit countChanged();
}

QString HistoryDatabase::dbPath() const
{
    QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(appDataPath);
    return appDataPath + "/history.db";
}

void HistoryDatabase::clearAllTrips()
{
    if (!m_db.isOpen()) {
        qWarning() << "clearAllTrips: 数据库未打开";
        return;
    }

    qDebug() << "正在清除所有行程记录...";

    QSqlQuery query(m_db);
    m_db.transaction();

    if (!query.exec("DELETE FROM trips")) {
        qWarning() << "删除失败:" << query.lastError().text();
        m_db.rollback();
        return;
    }

    query.exec("UPDATE SQLITE_SEQUENCE SET seq = 0 WHERE name = 'trips'");
    m_db.commit();

    qDebug() << "✅ 所有行程记录已清除";
    refreshHistory();
}

// 新增：统计函数
double HistoryDatabase::getTotalDistance() const
{
    double total = 0;
    for (const auto &trip : m_historyList) {
        // 解析距离字符串 (例如 "4770.6公里" 或 "100km")
        QString distStr = trip.dist;
        QRegularExpression rx("([\\d.]+)");
        QRegularExpressionMatch match = rx.match(distStr);
        if (match.hasMatch()) {
            total += match.captured(1).toDouble();
        }
    }
    return total;
}

double HistoryDatabase::getTotalTime() const
{
    double total = 0;  // 总时间（小时）
    for (const auto &trip : m_historyList) {
        QString timeStr = trip.time;
        double hours = 0;

        // 解析时间 (例如 "23天23小时", "20分钟", "1天")
        QRegularExpression dayRx("(\\d+)天");
        QRegularExpression hourRx("(\\d+)小时");
        QRegularExpression minRx("(\\d+)分钟");

        QRegularExpressionMatch dayMatch = dayRx.match(timeStr);
        QRegularExpressionMatch hourMatch = hourRx.match(timeStr);
        QRegularExpressionMatch minMatch = minRx.match(timeStr);

        if (dayMatch.hasMatch()) {
            hours += dayMatch.captured(1).toDouble() * 24;
        }
        if (hourMatch.hasMatch()) {
            hours += hourMatch.captured(1).toDouble();
        }
        if (minMatch.hasMatch()) {
            hours += minMatch.captured(1).toDouble() / 60.0;
        }

        total += hours;
    }
    return total;
}

double HistoryDatabase::getAverageSpeed() const
{
    double totalDist = getTotalDistance();
    double totalTime = getTotalTime();

    if (totalTime > 0) {
        return totalDist / totalTime;
    }
    return 0;
}
