#ifndef MULTIMEDIA_GST_HPP
#define MULTIMEDIA_GST_HPP

#include <QQuickItem>
#include <QRunnable>
#include <QObject>
#include <gst/gst.h>

struct CustomData
{
    GstElement *pipeline;
    GstElement *source;
    GstElement *video_convert;
    GstElement *glupload;
    GstElement *video_sink;
    GstElement *audio_convert;
    GstElement *audio_resample;
    GstElement *audio_sink;
};

class InitState : public QObject, public QRunnable
{
    Q_OBJECT
public:
    InitState(GstElement *);
    ~InitState();

    void run ();

private:
    GstElement * pipeline_;

signals:
    void pipelineReady();
};

class MultimediaGST : public QObject
{
    Q_OBJECT

private:
    QQuickWindow *m_rootObject;
    CustomData gstData;
    InitState *initState;
    QTimer *seek_timer;
    /* Handler for the pad-added signal */
    static void pad_added_handler (GstElement * src, GstPad * pad, CustomData * data);
    void setupPipeline(QString file);
    void cleanPipeline();
    void getDuration();
    void getPosition();
    void pipelineReady();

public:
    explicit MultimediaGST(QObject *parent = nullptr, int argc = 0, char *argv[] = nullptr);
    ~MultimediaGST();

public slots:
    void setupNewPipeline(QString file);
    void play();
    void pause();
    void seek(gint64 val);
    void positionStop();
    void positionStart();
    void setRootObject(QQuickWindow * rootObject);

signals:
    void durationChanged(qint64 len);
    void positionChanged(qint64 cur);
};

#endif // MULTIMEDIA_GST_HPP
