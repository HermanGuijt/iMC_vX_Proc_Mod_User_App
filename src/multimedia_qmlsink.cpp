#include "multimedia_qmlsink.hpp"
#include <QDebug>
#include <QQuickItem>
#include <QQuickWindow>
#include <QRunnable>
#include <QString>
#include <QTimer>
#include <gst/gst.h>

InitState::InitState (GstElement * pipeline)
{
    this->pipeline_ = pipeline ? static_cast<GstElement *> (gst_object_ref (pipeline)) : NULL;
}

InitState::~InitState ()
{
    if (this->pipeline_)
        gst_object_unref (this->pipeline_);
}

void InitState::run ()
{
    if (this->pipeline_) {
        // First set pipeline to PAUSED and wait for async state change
        gst_element_set_state (this->pipeline_, GST_STATE_PAUSED);
        gst_element_get_state(this->pipeline_, nullptr, nullptr, GST_CLOCK_TIME_NONE);

        // Uncoment botom line for dumping the pipeline .dot file -> Useful for debugging.
        // GST_DEBUG_BIN_TO_DOT_FILE(GST_BIN(this->pipeline_), GST_DEBUG_GRAPH_SHOW_ALL, "pipeline");

        emit pipelineReady();
    }
}


MultimediaGST::MultimediaGST(QObject *parent, int argc, char *argv[])
    : QObject(parent)
{
    seek_timer = new QTimer(this);
    connect(seek_timer, &QTimer::timeout, this, &MultimediaGST::getPosition);
    seek_timer->setInterval(20);

    gst_init (&argc, &argv);

    // The plugin must be loaded before loading the qml file to register the
    // GstGLVideoItem qml item.
    gstData.video_sink = gst_element_factory_make ("qml6glsink", NULL);
}

void MultimediaGST::setupPipeline(QString file)
{
    gstData.pipeline = gst_pipeline_new ("pipeline");
    gstData.source = gst_element_factory_make ("uridecodebin", "source");
    gstData.video_convert = gst_element_factory_make ("videoconvert", "video-convert");
    gstData.audio_convert = gst_element_factory_make ("audioconvert", "audio-convert");
    gstData.audio_resample = gst_element_factory_make ("audioresample", "audio-resample");
    gstData.glupload = gst_element_factory_make ("glupload", "glupload");
    gstData.video_sink = gst_element_factory_make ("qml6glsink", "video-sink");
    gstData.audio_sink = gst_element_factory_make ("autoaudiosink", "audio-sink");

    // Set source file to be played.
    g_object_set (gstData.source, "uri", file.toStdString().c_str(), NULL);

    if (!gstData.pipeline || !gstData.source || !gstData.video_convert || !gstData.glupload
        || !gstData.video_sink || !gstData.audio_convert || !gstData.audio_resample || !gstData.audio_sink) {
        qFatal() << "Not all elements could be created.";
    }

    // Build the pipeline. Note that we are NOT linking the source at this
    // point. We will do it later.
    gst_bin_add_many (GST_BIN (gstData.pipeline), gstData.source, gstData.video_convert,
                     gstData.glupload, gstData.video_sink,
                     gstData.audio_convert, gstData.audio_resample, gstData.audio_sink, NULL);

    // Link video part of pipeline
    if (!gst_element_link_many (gstData.video_convert, gstData.glupload, gstData.video_sink, NULL)) {
        gst_object_unref (gstData.pipeline);
        qFatal() << "Elements in video pipeline could not be linked.";
    }

    // Link audio part of pipeline
    if (!gst_element_link_many (gstData.audio_convert, gstData.audio_resample, gstData.audio_sink, NULL)) {
        gst_object_unref (gstData.pipeline);
        qFatal() << "Elements in audio pipeline could not be linked.";
    }

    // Register a calback for everytime a pad-added signal is emited.
    g_signal_connect (gstData.source, "pad-added", G_CALLBACK (pad_added_handler),
                     &gstData);
}

void MultimediaGST::cleanPipeline()
{
    if(!gstData.pipeline)
        return;

    seek_timer->stop();
    gst_element_set_state (gstData.pipeline, GST_STATE_NULL);

    // Unlinke all elements in pipeline.
    gst_element_unlink(gstData.source, gstData.video_convert);
    gst_element_unlink(gstData.video_convert, gstData.glupload);
    gst_element_unlink(gstData.glupload, gstData.video_sink);
    gst_element_unlink(gstData.source, gstData.audio_convert);
    gst_element_unlink(gstData.audio_convert, gstData.audio_resample);
    gst_element_unlink(gstData.audio_resample, gstData.audio_sink);
    gst_object_unref (gstData.pipeline);
}

void MultimediaGST::setupNewPipeline(QString file)
{
    cleanPipeline();
    setupPipeline(file);

    QQuickItem *videoItem;
    QQuickWindow *rootObject = m_rootObject;

    // Find and set the videoItem on the sink
    videoItem = rootObject->findChild<QQuickItem *> ("videoItem");
    g_assert (videoItem);
    g_object_set(gstData.video_sink, "widget", videoItem, NULL);

    // Schedule render job for pipeline. This makes it possible to obtain video duration.
    initState = new InitState (gstData.pipeline);
    QObject::connect(initState, &InitState::pipelineReady, this, &MultimediaGST::pipelineReady);
    rootObject->scheduleRenderJob (initState,
                                  QQuickWindow::BeforeSynchronizingStage);
}

void MultimediaGST::pipelineReady()
{
    getDuration();
    seek_timer->start();
}

// This function will be called by the pad-added signal
void MultimediaGST::pad_added_handler (GstElement * src, GstPad * new_pad, CustomData *data)
{
    GstPad *video_sink_pad = gst_element_get_static_pad (data->video_convert, "sink");
    GstPad *audio_sink_pad = gst_element_get_static_pad (data->audio_convert, "sink");
    GstPadLinkReturn ret;
    GstCaps *new_pad_caps = NULL;
    GstStructure *new_pad_struct = NULL;
    const gchar *new_pad_type = NULL;

    // Return if both (audio & video) sub-pipelines are already linked
    if (gst_pad_is_linked (video_sink_pad) && gst_pad_is_linked (audio_sink_pad))
        goto exit;

    // Check the new pad's type
    new_pad_caps = gst_pad_get_current_caps (new_pad);
    new_pad_struct = gst_caps_get_structure (new_pad_caps, 0);
    new_pad_type = gst_structure_get_name (new_pad_struct);

    if (g_str_has_prefix (new_pad_type, "video/x-raw")) {
        // Attempt the link of video pads
        ret = gst_pad_link (new_pad, video_sink_pad);
        if (GST_PAD_LINK_FAILED (ret)) {
            qWarning() << "Type is " << new_pad_type << "but link failed";
        } else {
            qDebug() << "Link succeeded (type "<< new_pad_type << ").";
        }
    } else if (g_str_has_prefix (new_pad_type, "audio/x-raw")) {
        // Attempt the link of audio pads
        ret = gst_pad_link (new_pad, audio_sink_pad);
        if (GST_PAD_LINK_FAILED (ret)) {
            qWarning() << "Type is " << new_pad_type << "but link failed";
        } else {
            qDebug() << "Link succeeded (type "<< new_pad_type << ").";
        }
    } else {
        qDebug() << "It has type " << new_pad_type << "which is not raw video/audio. Ignoring.";
    }

exit:
    // Unreference the new pad's caps, if we got them
    if (new_pad_caps != NULL)
        gst_caps_unref (new_pad_caps);

    // Unreference the sink pad
    gst_object_unref (video_sink_pad);
    gst_object_unref (audio_sink_pad);
}

MultimediaGST::~MultimediaGST()
{
    gst_element_set_state (gstData.pipeline, GST_STATE_NULL);
    gst_object_unref (gstData.pipeline);
    gst_deinit();
}

void MultimediaGST::setRootObject(QQuickWindow * rootObject)
{
    m_rootObject = rootObject;
}

void MultimediaGST::play()
{
    gst_element_set_state (gstData.pipeline, GST_STATE_PLAYING);
}

void MultimediaGST::pause()
{
    gst_element_set_state (gstData.pipeline, GST_STATE_PAUSED);
}

void MultimediaGST::seek(gint64 val)
{
    GstState state;
    gst_element_get_state(gstData.pipeline, &state, nullptr, GST_CLOCK_TIME_NONE);

    // First set pipeline to PAUSED and wait for async state change
    gst_element_set_state (gstData.pipeline, GST_STATE_PAUSED);
    gst_element_get_state(gstData.pipeline, nullptr, nullptr, GST_CLOCK_TIME_NONE);
    if (!gst_element_seek (gstData.pipeline, 1.0, GST_FORMAT_TIME, GST_SEEK_FLAG_FLUSH, GST_SEEK_TYPE_SET, val * GST_MSECOND, GST_SEEK_TYPE_NONE, -1))
        qWarning() << "Seek failed!";

    gst_element_get_state(gstData.pipeline, nullptr, nullptr, GST_CLOCK_TIME_NONE);

    // Put the pipeline in the same state that it was in before the seek
    if (state > 3)
        gst_element_set_state (gstData.pipeline, GST_STATE_PLAYING);
    else
        gst_element_set_state (gstData.pipeline, GST_STATE_PAUSED);

    // Emit position in ms
    emit positionChanged(val);
}

void MultimediaGST::getDuration()
{
    gint64 len;
    if (!gst_element_query_duration (gstData.pipeline, GST_FORMAT_TIME, &len))
    {
        qWarning() << "seek duration failed";
        return;
    }

    // Emit duration in ms
    emit durationChanged(len/GST_MSECOND);
}

void MultimediaGST::getPosition()
{
    gint64 pos;
    if (!gst_element_query_position (gstData.pipeline, GST_FORMAT_TIME, &pos))
    {
        qWarning() << "seek position failed";
        return;
    }

    // Emit position in ms
    emit positionChanged(pos/GST_MSECOND);
}

void MultimediaGST::positionStop()
{
    seek_timer->stop();
}

void MultimediaGST::positionStart()
{
    seek_timer->start();
}
