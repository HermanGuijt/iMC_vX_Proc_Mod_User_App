/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2021 PHYTEC Messtechnik GmbH
 */

#include <QtCore>
#include <QtDBus>
#include <QDBusMetaType>
#include "rauc.hpp"

QDBusArgument &operator<<(QDBusArgument &argument, const RaucProgress &progress)
{
    argument.beginStructure();
    argument << progress.percentage << progress.message << progress.nestingDepth;
    argument.endStructure();
    return argument;
}

const QDBusArgument &operator>>(const QDBusArgument &argument, RaucProgress &progress)
{
    argument.beginStructure();
    argument >> progress.percentage >> progress.message >> progress.nestingDepth;
    argument.endStructure();
    return argument;
}

inline void testInterface(const QDBusInterface *iface)
{
    if (!iface->isValid()) {
        qCritical() << qPrintable(QDBusConnection::sessionBus().lastError().message());
    }
}

Rauc::Rauc(QObject *parent) :
    QObject(parent),
    progress({0, "", 0})
{
    qDBusRegisterMetaType<RaucProgress>();

    if (!QDBusConnection::systemBus().isConnected()) {
        qCritical() << "Cannot connect to the D-Bus system bus!";
        return;
    }

    ifaceProperties = new QDBusInterface("de.pengutronix.rauc", "/",
            "org.freedesktop.DBus.Properties", QDBusConnection::systemBus());
    testInterface(ifaceProperties);
    ifaceInstaller = new QDBusInterface("de.pengutronix.rauc", "/",
            "de.pengutronix.rauc.Installer", QDBusConnection::systemBus());
    testInterface(ifaceInstaller);

    QDBusConnection::systemBus().connect("de.pengutronix.rauc", "/",
            "org.freedesktop.DBus.Properties", "PropertiesChanged",
            this, SLOT(onPropertiesChanged(QString, QVariantMap, QStringList)));

    setPrimary();
    setOperation();
    setLastError();
    setProgress();
    setCompatible();
    setVariant();
    setBootSlot();

    processLsbRelease = new QProcess(this);
    processLsbRelease->start("lsb_release", QStringList() << "-r" << "-s");
    connect(processLsbRelease, SIGNAL(finished(int, QProcess::ExitStatus)),
            this, SLOT(lsbReleaseFinished(int, QProcess::ExitStatus)));
}

bool Rauc::isBootedSlot(const QString &slot)
{
    if (slot == "A" || slot == "0") {
        return bootSlot.endsWith("0");
    } else if (slot == "B" || slot == "1") {
        return bootSlot.endsWith("1");
    } else {
        return false;
    }
}

bool Rauc::isActiveSlot(const QString &slot)
{
    if (slot == "A" || slot == "0") {
        return primary.endsWith("0");
    } else if (slot == "B" || slot == "1") {
        return primary.endsWith("1");
    } else {
        return false;
    }
}

int Rauc::toPercentage(const RaucProgress &progress)
{
    return progress.percentage;
}

QString Rauc::getClientConfigPath() const
{
    return clientConfigPath;
}

void Rauc::setClientConfigPath(const QString &path)
{
    qDebug() << "setting client config path";
    clientConfigPath = path;

    QSettings settings(clientConfigPath, QSettings::IniFormat);

    settings.beginGroup("client");
    targetName = settings.value("target_name").toString();
    settings.endGroup();

    emit targetNameChanged();
}

QString Rauc::getTargetName() const
{
    return targetName;
}

QString Rauc::getReleaseName() const
{
    return releaseName;
}

void Rauc::lsbReleaseFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitStatus);

    if (exitCode < 0) {
        qCritical() << "lsb_release failed to execute!";
        return;
    }

    releaseName = processLsbRelease->readAll().trimmed();
    emit releaseNameChanged();
}

// RAUC D-Bus interface

QString Rauc::getPrimary() const
{
    return primary;
}

void Rauc::setPrimary()
{
    if (!ifaceInstaller->isValid()) {
        qCritical() << "Invalid interface!";
        return;
    }

    QList<QVariant> args;
    args.clear();

    if (!ifaceInstaller->callWithCallback("GetPrimary", args, this,
                SLOT(callbackPrimary(const QString &)))) {
        qCritical() << "Calling method \"GetPrimary\" failed!";
    }
}

void Rauc::callbackPrimary(const QString &value)
{
    primary = value;
    emit primaryChanged();
}

QString Rauc::getOperation() const
{
    return operation;
}

void Rauc::setOperation()
{
    operation = ifaceInstaller->property("Operation").toString();
    emit operationChanged();
}

QString Rauc::getLastError() const
{
    return lastError;
}

void Rauc::setLastError()
{
    lastError = ifaceInstaller->property("LastError").toString();
    emit lastErrorChanged();
}

RaucProgress Rauc::getProgress() const
{
    return progress;
}

void Rauc::setProgress()
{
    progress = ifaceInstaller->property("Progress").value<RaucProgress>();
    emit progressChanged();
}

QString Rauc::getCompatible() const
{
    return compatible;
}

void Rauc::setCompatible()
{
    compatible = ifaceInstaller->property("Compatible").toString();
    emit compatibleChanged();
}

QString Rauc::getVariant() const
{
    return variant;
}

void Rauc::setVariant()
{
    variant = ifaceInstaller->property("Variant").toString();
    emit variantChanged();
}

void Rauc::setBootSlot()
{
    bootSlot = ifaceInstaller->property("BootSlot").toString();
    emit bootSlotChanged();
}

QString Rauc::getBootSlot() const
{
    return bootSlot;
}

void Rauc::onPropertiesChanged(const QString &interfaceName,
        const QVariantMap &properties, const QStringList &invalidatedProperties)
{
    Q_UNUSED(invalidatedProperties);

    if (interfaceName == QLatin1String("de.pengutronix.rauc.Installer")) {
        qDebug() << "propertiesChanged!" << properties;
        // TODO: Only emit actually changed properties. Use QMap?

        setPrimary();
        setOperation();
        setLastError();
        setProgress();
        setCompatible();
        setVariant();
        setBootSlot();
    }
}
