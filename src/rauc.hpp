/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2021 PHYTEC Messtechnik GmbH
 */

#ifndef RAUC_HPP
#define RAUC_HPP

#include <QObject>
#include <QDBusArgument>
#include <QDBusInterface>
#include <QDBusPendingCallWatcher>
#include <QProcess>

typedef struct {
    int percentage;
    QString message;
    int nestingDepth;
} RaucProgress;
Q_DECLARE_METATYPE(RaucProgress)

QDBusArgument & operator<<(QDBusArgument &argument, const RaucProgress &progress);
const QDBusArgument & operator>>(const QDBusArgument &argument, RaucProgress &progress);

typedef struct {
    QString a;
    QList<QMap<QString, QVariant>> b;
} RaucSlotStatus;
Q_DECLARE_METATYPE(RaucSlotStatus)

class Rauc : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString clientConfigPath
            READ getClientConfigPath
            WRITE setClientConfigPath)
    Q_PROPERTY(QString targetName
            READ getTargetName
            NOTIFY targetNameChanged)

    Q_PROPERTY(QString releaseName
            READ getReleaseName
            NOTIFY releaseNameChanged)

    Q_PROPERTY(QString primary
            READ getPrimary
            NOTIFY primaryChanged)
    Q_PROPERTY(QString operation
            READ getOperation
            NOTIFY operationChanged)
    Q_PROPERTY(QString lastError
            READ getLastError
            NOTIFY lastErrorChanged)
    Q_PROPERTY(RaucProgress progress
            READ getProgress
            NOTIFY progressChanged)
    Q_PROPERTY(QString compatible
            READ getCompatible
            NOTIFY compatibleChanged)
    Q_PROPERTY(QString variant
            READ getVariant
            NOTIFY variantChanged)
    Q_PROPERTY(QString bootSlot
            READ getBootSlot
            NOTIFY bootSlotChanged)
public:
    explicit Rauc(QObject *parent = nullptr);
    Q_INVOKABLE bool isBootedSlot(const QString &slot);
    Q_INVOKABLE bool isActiveSlot(const QString &slot);
    Q_INVOKABLE int toPercentage(const RaucProgress &progress);

public slots:
    QString getClientConfigPath() const;
    void setClientConfigPath(const QString &path);
    QString getTargetName() const;

    QString getReleaseName() const;

    QString getPrimary() const;
    QString getOperation() const;
    QString getLastError() const;
    RaucProgress getProgress() const;
    QString getCompatible() const;
    QString getVariant() const;
    QString getBootSlot() const;

private:
    // rauc-hawkbit client configuration
    QString clientConfigPath;
    QString targetName;

    // misc
    QString releaseName;
    QProcess *processLsbRelease;

    // RAUC D-Bus interface
    QDBusInterface *ifaceProperties;
    QDBusInterface *ifaceInstaller;

    QString primary;
    QString operation;
    QString lastError;
    RaucProgress progress;
    QString compatible;
    QString variant;
    QString bootSlot;

    void setPrimary();
    void setOperation();
    void setLastError();
    void setProgress();
    void setCompatible();
    void setVariant();
    void setBootSlot();

private slots:
    void lsbReleaseFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void callbackPrimary(const QString &value);

    void onPropertiesChanged(const QString &interfaceName,
            const QVariantMap &properties,
            const QStringList &invalidatedProperties);

signals:
    void targetNameChanged();
    void releaseNameChanged();

    void primaryChanged();
    void operationChanged();
    void lastErrorChanged();
    void progressChanged();
    void compatibleChanged();
    void variantChanged();
    void bootSlotChanged();
};

#endif // RAUC_HPP
