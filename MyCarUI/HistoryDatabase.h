#ifndef HISTORYDATABASE_H
#define HISTORYDATABASE_H

#include <QAbstractListModel>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QStandardPaths>
#include <QDir>
#include <QVariantMap>
#include <QTimer>

struct HistoryData {
    QString date;
    QString from;
    QString to;
    QString dist;
    QString time;
    QString speed;
};

class HistoryDatabase : public QAbstractListModel {
    Q_OBJECT

public:
    enum HistoryRoles {
        DateRole = Qt::UserRole + 1,
        FromRole,
        ToRole,
        DistRole,
        TimeRole,
        SpeedRole
    };
    Q_ENUM(HistoryRoles)

    explicit HistoryDatabase(QObject *parent = nullptr);
    ~HistoryDatabase();

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE bool initDatabase();
    Q_INVOKABLE void insertTrip(const QVariantMap &tripData);
    Q_INVOKABLE void refreshHistory();
    Q_INVOKABLE int count() const;
    Q_INVOKABLE void startAutoSync(int intervalMs = 5000);
    Q_INVOKABLE void stopAutoSync();
    Q_INVOKABLE bool isAutoSync() const;
    Q_INVOKABLE void clearAllTrips();
    Q_INVOKABLE void deleteTrip(int index);
    Q_INVOKABLE QString dbPath() const;


    Q_INVOKABLE double getTotalDistance() const;
    Q_INVOKABLE double getTotalTime() const;
    Q_INVOKABLE double getAverageSpeed() const;

signals:
    void countChanged();
    void dataChanged();

private slots:
    void onAutoSyncTimeout();

private:
    QSqlDatabase m_db;
    QList<HistoryData> m_historyList;
    QTimer *m_syncTimer = nullptr;

    bool createTable();
};

#endif
