/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2021 PHYTEC Messtechnik GmbH
 */

#ifndef DEVICE_INFO_HPP
#define DEVICE_INFO_HPP

#include <QObject>
#include <QProcess>
#include <QQmlEngine>
#include <QJSEngine>

class DeviceInfo : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString boardDescription
               READ getBoardDescription
               NOTIFY boardDescriptionChanged)
    Q_PROPERTY(QString machine
               READ getMachine
               NOTIFY machineChanged)
    Q_PROPERTY(QString distribution
               READ getDistribution
               NOTIFY distributionChanged)
    Q_PROPERTY(QString release
               READ getRelease
               NOTIFY releaseChanged)
    Q_PROPERTY(QString codename
               READ getCodename
               NOTIFY codenameChanged)
    Q_PROPERTY(QString kernelRelease
               READ getKernelRelease
               NOTIFY kernelReleaseChanged)
    Q_PROPERTY(QString cpuModelName
               READ getCpuModelName
               NOTIFY cpuModelNameChanged)
    Q_PROPERTY(QString ram
               READ getRam
               NOTIFY ramChanged)
    Q_PROPERTY(QString architecture
               READ getArchitecture
               NOTIFY architectureChanged)

public:
    explicit DeviceInfo(QObject *parent = nullptr);
    static QObject * singletontypeProvider(QQmlEngine *engine, QJSEngine *scriptEngine);

public slots:
    QString getBoardDescription() const;
    QString getMachine() const;
    QString getDistribution() const;
    QString getRelease() const;
    QString getCodename() const;
    QString getKernelRelease() const;
    QString getCpuModelName() const;
    QString getRam() const;
    QString getArchitecture() const;

private:
    QString boardDescription;
    QProcess *procBoardDescription;
    QString machine;
    QProcess *procMachine;
    QString distribution;
    QProcess *procDistribution;
    QString release;
    QProcess *procRelease;
    QString codename;
    QProcess *procCodename;
    QString kernelRelease;
    QProcess *procKernelRelease;
    QString cpuModelName;
    QProcess *procCpuModelName;
    QString ram;
    QProcess *procRam;
    QString architecture;
    QProcess *procArchitecture;

private slots:
    void procBoardDescriptionFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void procMachineFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void procDistributionFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void procReleaseFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void procCodenameFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void procKernelReleaseFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void procCpuModelNameFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void procRamFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void procArchitectureFinished(int exitCode, QProcess::ExitStatus exitStatus);

signals:
    void boardDescriptionChanged();
    void machineChanged();
    void distributionChanged();
    void releaseChanged();
    void codenameChanged();
    void kernelReleaseChanged();
    void cpuModelNameChanged();
    void ramChanged();
    void architectureChanged();
};

#endif /* DEVICE_INFO_HPP */
