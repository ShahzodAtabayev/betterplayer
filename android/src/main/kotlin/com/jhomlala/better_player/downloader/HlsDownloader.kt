package com.jhomlala.better_player.downloader

import android.content.ContentValues.TAG
import android.content.Context
import android.net.Uri
import android.util.Log
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.offline.Download
import com.google.android.exoplayer2.util.MimeTypes
import com.jhomlala.better_player.QueuingEventSink
import com.jhomlala.better_player.downloader.core.DownloadUtil
import com.jhomlala.better_player.downloader.core.MediaItemTag
import com.jhomlala.better_player.downloader.core.DownloadTracker
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.collect

class HlsDownloader(
    private val context: Context,
    private val eventChannel: EventChannel,
    private val url: String,
    private val duration: Long
) :
    DownloadTracker.Listener {

    private val mediaItem: MediaItem by lazy {
        MediaItem.Builder()
            .setUri(url)
            .setMimeType(MimeTypes.APPLICATION_M3U8)
            .setTag(MediaItemTag(duration, url))
            .build()
    }

    private val eventSink = QueuingEventSink()

    init {
        eventChannel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(o: Any?, sink: EventChannel.EventSink) {
                    eventSink.setDelegate(sink)
                }

                override fun onCancel(o: Any?) {
                    eventSink.setDelegate(null)
                }
            })

        DownloadUtil.getDownloadTracker(context).addListener(this)

        DownloadUtil.getDownloadTracker(context).downloads[mediaItem.localConfiguration?.uri!!]?.let {
            // Not so clean, used to set the right drawable on the ImageView
            // And start the Flow if the download is in progress
            onDownloadsChanged(it)
        }
    }

    fun getOptionsDownload(
        preparedCallback: ((Map<String, Double>) -> Unit)? = null,
        errorCallback: ((String) -> Unit)? = null
    ) {
        if (DownloadUtil.getDownloadTracker(context).isDownloaded(mediaItem)) {
            return
        }
        val item = mediaItem.buildUpon()
            .setTag((mediaItem.localConfiguration?.tag as MediaItemTag))
            .build()

        if (!DownloadUtil.getDownloadTracker(context)
                .hasDownload(item.localConfiguration?.uri)
        ) {
            DownloadUtil.getDownloadTracker(context)
                .getDownloadOptionsHelper(context, item) {
                    preparedCallback?.invoke(it)
                }
        } else {
            errorCallback?.invoke("Cannot download this file")
        }

        Log.d(TAG, "get options success")

    }

    fun onSelectOptionsDownload(
        selectedKey: String,
        successCallBack: (() -> Unit),
        notSpaceError: (() -> Unit)
    ) {
        Log.d(TAG, "select options key:${selectedKey}")
        DownloadUtil.getDownloadTracker(context)
            .onSelectOptionsDownload(
                selectedKey = selectedKey,
                successCallBack = successCallBack,
                notSpaceError = notSpaceError
            )
    }


    fun onDismissOptionsDownload() {
        Log.d(TAG, "dismiss options")
        DownloadUtil.getDownloadTracker(context)
            .onDismissOptionsDownload()
    }

    override fun onDownloadsChanged(download: Download) {
        when (download.state) {
            Download.STATE_DOWNLOADING -> {
                startFlow(context, download.request.uri)
            }
            Download.STATE_QUEUED -> {
                val result: MutableMap<String, Any> = mutableMapOf()
                result["status"] = "queued"
                result["progress"] = 0.0
                eventSink.success(result)
                stopFlow()
            }
            Download.STATE_STOPPED -> {
                val result: MutableMap<String, Any> = mutableMapOf()
                result["status"] = "stopped"
                result["progress"] = 0.0
                eventSink.success(result)
                stopFlow()
            }
            Download.STATE_COMPLETED -> {
                val result: MutableMap<String, Any> = mutableMapOf()
                result["status"] = "downloaded"
                result["progress"] = 100.0
                eventSink.success(result)
                stopFlow()
                Log.d(TAG, " Download.STATE_COMPLETED ==========================")
            }
            Download.STATE_REMOVING -> {
                val result: MutableMap<String, Any> = mutableMapOf()
                result["status"] = "removed"
                result["progress"] = 0.0
                eventSink.success(result)
                stopFlow()
            }
            Download.STATE_FAILED, Download.STATE_RESTARTING -> {
                val result: MutableMap<String, Any> = mutableMapOf()
                result["status"] = "failed"
                result["progress"] = 0.0
                eventSink.success(result)
                stopFlow()
            }
            else -> {
                val result: MutableMap<String, Any> = mutableMapOf()
                result["status"] = "failed"
                result["progress"] = 0.0
                eventSink.success(result)
                stopFlow()
            }
        }
    }

    private var coroutineScope: CoroutineScope? = null

    @OptIn(ExperimentalCoroutinesApi::class)
    fun startFlow(context: Context, uri: Uri) {
        coroutineScope?.cancel()
        val job = SupervisorJob()
        coroutineScope = CoroutineScope(Dispatchers.Main + job).apply {
            launch {
                DownloadUtil.getDownloadTracker(context).getCurrentProgressDownload(uri).collect {
                    val result: MutableMap<String, Any> = mutableMapOf()
                    result["status"] = "downloading"
                    result["progress"] = it ?: 0
                    eventSink.success(result)
                }
            }
        }
    }

    private fun stopFlow() {
        coroutineScope?.cancel()
    }

    fun dispose() {
        stopFlow()
        DownloadUtil.getDownloadTracker(context).removeListener(this)
    }

}