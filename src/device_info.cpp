/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2021 PHYTEC Messtechnik GmbH
 */

#include <QtCore>
#include "device_info.hpp"

#define NEW_PROC(proc, program, args) \
    proc = new QProcess(this); \
    proc->start(program, QStringList() << args); \
    connect(proc, SIGNAL(finished(int, QProcess::ExitStatus)), \
            this, SLOT(proc##Finished(int, QProcess::ExitStatus)));

DeviceInfo::DeviceInfo(QObject *parent) :
    QObject(parent)
{
    NEW_PROC(procBoardDescription, "cat", "/proc/device-tree/model");
    NEW_PROC(procMachine, "uname", "-n"); // Machine is hostname in this case
    NEW_PROC(procDistribution, "lsb_release", "-i");
    NEW_PROC(procRelease, "lsb_release", "-r");
    NEW_PROC(procCodename, "lsb_release", "-c");
    NEW_PROC(procKernelRelease, "uname", "-r");
    NEW_PROC(procCpuModelName, "cat", "/proc/cpuinfo");
    NEW_PROC(procRam, "cat", "/proc/meminfo");
    NEW_PROC(procArchitecture, "uname", "-m");
}

QObject * DeviceInfo::singletontypeProvider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine);
    Q_UNUSED(scriptEngine);

    DeviceInfo *deviceInfo = new DeviceInfo();
    return deviceInfo;
}

QString DeviceInfo::getBoardDescription() const
{
    return boardDescription;
}

QString DeviceInfo::getMachine() const
{
    return machine;
}

QString DeviceInfo::getDistribution() const
{
    return distribution;
}

QString DeviceInfo::getRelease() const
{
    return release;
}

QString DeviceInfo::getCodename() const
{
    return codename;
}

QString DeviceInfo::getKernelRelease() const
{
    return kernelRelease;
}

QString DeviceInfo::getCpuModelName() const
{
    return cpuModelName;
}

QString DeviceInfo::getRam() const
{
    return ram;
}

QString DeviceInfo::getArchitecture() const
{
    return architecture;
}

void DeviceInfo::procBoardDescriptionFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitStatus);

    if (exitCode < 0)
        boardDescription = "unknown";
    else
        boardDescription = procBoardDescription->readAll().trimmed();

    emit boardDescriptionChanged();
}

void DeviceInfo::procMachineFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitStatus);

    if (exitCode < 0)
        machine = "unknown";
    else
        machine = procMachine->readAll().trimmed();

    emit machineChanged();
}

void DeviceInfo::procDistributionFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitStatus);

    if (exitCode < 0) {
        distribution = "unknown";
    } else {
        QRegularExpression rx("(Distributor ID:\\s+)([^\\n]+)");
        distribution = rx.match(procDistribution->readAll()).captured(2);
    }

    emit distributionChanged();
}

void DeviceInfo::procReleaseFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitStatus);

    if (exitCode < 0) {
        release = "unknown";
    } else {
        QRegularExpression rx("(Release:\\s+)([^\\n]+)");
        release = rx.match(procRelease->readAll()).captured(2);
    }

    emit releaseChanged();
}

void DeviceInfo::procCodenameFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitStatus);

    if (exitCode < 0) {
        codename = "unknown";
    } else {
        QRegularExpression rx("(Codename:\\s+)([^\\n]+)");
        codename = rx.match(procCodename->readAll()).captured(2);
    }

    emit codenameChanged();
}

void DeviceInfo::procKernelReleaseFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitStatus);

    if (exitCode < 0)
        kernelRelease = "unknown";
    else
        kernelRelease = procKernelRelease->readAll().trimmed();

    emit kernelReleaseChanged();
}

void DeviceInfo::procCpuModelNameFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitStatus);

    if (exitCode < 0) {
        cpuModelName = "unknown";
    } else {
        QRegularExpression rx("(model name\\t+: )([^\\n]+)");
        cpuModelName = rx.match(procCpuModelName->readAll()).captured(2);
    }

    emit cpuModelNameChanged();
}

void DeviceInfo::procRamFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitStatus);

    if (exitCode < 0) {
        ram = "unknown";
    } else {
        QRegularExpression rx("(MemTotal:\\s+)([^\\n]+)");
        ram = rx.match(procRam->readAll()).captured(2);
    }

    emit ramChanged();
}

void DeviceInfo::procArchitectureFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitStatus);

    if (exitCode < 0)
        architecture = "unknown";
    else
        architecture = procArchitecture->readAll().trimmed();

    emit architectureChanged();
}
