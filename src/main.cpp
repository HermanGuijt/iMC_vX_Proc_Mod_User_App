/*
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2021 PHYTEC Messtechnik GmbH
 */

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QCommandLineParser>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSettings>
#include <QFile>
#include "device_info.hpp"
#include "rauc.hpp"

#ifdef QML_SINK
#include "multimedia_qmlsink.hpp"
#endif

void writeDefaultSettings()
{
    QSettings settings;
    QList<QString> enabledPages = {
        "Image Viewer",
        "Multimedia",
        "RAUC – Update Client",
        "Multitouch",
        "Device Information",
        "Widget Factory",
        "About PHYTEC"
    };

    settings.beginWriteArray("enabled-pages", enabledPages.size());
    for (int i = 0; i < enabledPages.size(); ++i) {
        settings.setArrayIndex(i);
        settings.setValue("name", enabledPages.at(i));
    }
    settings.endArray();
}

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName("PHYTEC Messtechnik GmbH");
    app.setApplicationName("qtphy");

    QCommandLineParser parser;
    parser.addHelpOption();
    parser.addOptions({
            {
                {"c", "rauc-hawkbit-config"},
                "RAUC hawkBit client configuration path",
                "path",
                "/etc/rauc-hawkbit-updater/config.conf"
            }
    });
    parser.process(app);

    QSettings settings;
    QFile file(settings.fileName());
    if (!file.exists()) {
        qWarning() << "Settings file " << file.fileName() << "not found!";
        qWarning() << "Writing new settings file with default values.";
        writeDefaultSettings();
    }

    QVariantList enabledPages;
    int size = settings.beginReadArray("enabled-pages");
    for (int i = 0; i < size; ++i) {
        settings.setArrayIndex(i);
        enabledPages.append(settings.value("name").toString());
    }

    qmlRegisterSingletonType<DeviceInfo>("Phytec.DeviceInfo", 1, 0, "DeviceInfo",
                                         DeviceInfo::singletontypeProvider);
    qmlRegisterType<Rauc>("Phytec.Rauc", 1, 0, "Rauc");

    QQmlApplicationEngine engine;
    engine.addImportPath("qrc:///themes");
    engine.rootContext()->setContextProperty("raucHawkbitConfigPath",
                                             parser.value("rauc-hawkbit-config"));
    engine.rootContext()->setContextProperty("enabledPages", enabledPages);
    engine.rootContext()->setContextProperty("multimediaPage", "multimedia.qml");
#ifdef QML_SINK
    MultimediaGST *multimediaGST = new MultimediaGST(&app, argc, argv);
    engine.rootContext()->setContextProperty("multimediaPage", "multimedia_qmlsink.qml");
    engine.rootContext()->setContextProperty("multimediaGST", multimediaGST);
#endif

    engine.load(QUrl(QStringLiteral("qrc:///main.qml")));

#ifdef QML_SINK
    multimediaGST->setRootObject(static_cast<QQuickWindow *> (engine.rootObjects().first()));
#endif

    return app.exec();
}
