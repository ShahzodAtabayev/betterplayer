package com.jhomlala.better_player.cache

import android.app.AlertDialog
import android.content.Context
import android.net.Uri
import android.os.StatFs
import android.view.View
import android.widget.Toast
import com.google.android.exoplayer2.C
import com.google.android.exoplayer2.DefaultRenderersFactory
import com.google.android.exoplayer2.Format
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.offline.*
import com.google.android.exoplayer2.offline.DownloadHelper.LiveContentUnsupportedException
import com.google.android.exoplayer2.source.TrackGroup
import com.google.android.exoplayer2.source.TrackGroupArray
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector
import com.google.android.exoplayer2.upstream.HttpDataSource
import com.google.android.exoplayer2.util.Assertions
import com.google.android.exoplayer2.util.Log
import com.google.android.exoplayer2.util.MimeTypes
import com.google.android.exoplayer2.util.Util
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import java.io.IOException
import java.util.*
import java.util.concurrent.CopyOnWriteArraySet

private const val TAG = "DownloadTracker"

/** Tracks media that has been downloaded.  */
class DownloadTracker(
    context: Context,
    private val httpDataSourceFactory: HttpDataSource.Factory,
    private val downloadManager: DownloadManager
) {
    /**
     * Listens for changes in the tracked downloads.
     */
    interface Listener {
        /**
         * Called when the tracked downloads changed.
         */
        fun onDownloadsChanged(download: Download)

    }

    private val applicationContext: Context = context.applicationContext
    private val listeners: CopyOnWriteArraySet<Listener> = CopyOnWriteArraySet()
    private val downloadIndex: DownloadIndex = downloadManager.downloadIndex
    private var startDownloadDialogHelper: StartDownloadDialogHelper? = null
    private var availableBytesLeft: Long =
        StatFs(DownloadUtil.getDownloadDirectory(context).path).availableBytes

    val downloads: HashMap<Uri, Download> = HashMap()

    init {
        downloadManager.addListener(DownloadManagerListener())
        loadDownloads()
    }

    fun addListener(listener: Listener) {
        Assertions.checkNotNull(listener)
        listeners.add(listener)
    }

    fun removeListener(listener: Listener) {
        listeners.remove(listener)
    }

    fun isDownloaded(mediaItem: MediaItem): Boolean {
        val download = downloads[mediaItem.playbackProperties?.uri]
        return download != null && download.state == Download.STATE_COMPLETED
    }

    fun hasDownload(uri: Uri?): Boolean = downloads.keys.contains(uri)

    fun getDownloadRequest(uri: Uri?): DownloadRequest? {
        uri ?: return null
        val download = downloads[uri]
        return if (download != null && download.state != Download.STATE_FAILED) download.request else null
    }

    fun getDownloadOptionsHelper(
        context: Context, mediaItem: MediaItem,
        positiveCallback: (() -> Unit)? = null, dismissCallback: (() -> Unit)? = null,
        preparedCallback: ((Map<String, String>) -> Unit)? = null,
    ) {
        startDownloadDialogHelper?.release()
        startDownloadDialogHelper =
            StartDownloadDialogHelper(
                context,
                getDownloadHelper(mediaItem),
                mediaItem,
                positiveCallback,
                dismissCallback,
                preparedCallback,
            )
    }

    fun onSelectOptionsDownload(selectedKey: String) {
        startDownloadDialogHelper?.onSelectOptionsDownload(selectedKey)
    }

    fun onDismissOptionsDownload() {
        startDownloadDialogHelper?.onDismissOptionsDownload()
    }


    fun toggleDownloadPopupMenu(context: Context, anchor: View, uri: Uri?) {
//        val popupMenu = PopupMenu(context, anchor).apply { inflate(R.menu.popup_menu) }
//        val download = downloads[uri]
//        download ?: return
//
//        popupMenu.menu.apply {
//            findItem(R.id.cancel_download).isVisible =
//                listOf(
//                    Download.STATE_DOWNLOADING,
//                    Download.STATE_STOPPED,
//                    Download.STATE_QUEUED,
//                    Download.STATE_FAILED
//                ).contains(download.state)
//            findItem(R.id.delete_download).isVisible = download.state == Download.STATE_COMPLETED
//            findItem(R.id.resume_download).isVisible =
//                listOf(Download.STATE_STOPPED, Download.STATE_FAILED).contains(download.state)
//            findItem(R.id.pause_download).isVisible = download.state == Download.STATE_DOWNLOADING
//        }
//
//        popupMenu.setOnMenuItemClickListener {
//            when (it.itemId) {
//                R.id.cancel_download, R.id.delete_download -> removeDownload(download.request.uri)
//                R.id.resume_download -> {
//                    DownloadService.sendSetStopReason(
//                        context,
//                        MyDownloadService::class.java,
//                        download.request.id,
//                        Download.STOP_REASON_NONE,
//                        true
//                    )
//                }
//                R.id.pause_download -> {
//                    DownloadService.sendSetStopReason(
//                        context,
//                        MyDownloadService::class.java,
//                        download.request.id,
//                        Download.STATE_STOPPED,
//                        false
//                    )
//                }
//            }
//            return@setOnMenuItemClickListener true
//        }
//        popupMenu.show()
    }

    fun removeDownload(uri: Uri?) {
        val download = downloads[uri]
        download?.let {
            DownloadService.sendRemoveDownload(
                applicationContext,
                MyDownloadService::class.java,
                download.request.id,
                false
            )
        }
    }

    private fun loadDownloads() {
        try {
            downloadIndex.getDownloads().use { loadedDownloads ->
                while (loadedDownloads.moveToNext()) {
                    val download = loadedDownloads.download
                    downloads[download.request.uri] = download
                }
            }
        } catch (e: IOException) {
            Log.w(TAG, "Failed to query downloads", e)
        }
    }

    @ExperimentalCoroutinesApi
    suspend fun getAllDownloadProgressFlow(): Flow<List<Download>> = callbackFlow {
        while (coroutineContext.isActive) {
            offer(downloads.values.toList())
            delay(1000)
        }
    }

    @ExperimentalCoroutinesApi
    suspend fun getCurrentProgressDownload(uri: Uri?): Flow<Float?> {
        var percent: Float? =
            downloadManager.currentDownloads.find { it.request.uri == uri }?.percentDownloaded
        return callbackFlow {
            while (percent != null) {
                percent =
                    downloadManager.currentDownloads.find { it.request.uri == uri }?.percentDownloaded
                offer(percent)
                withContext(Dispatchers.IO) {
                    delay(1000)
                }
            }
        }
    }


    private fun getDownloadHelper(mediaItem: MediaItem): DownloadHelper {
        return when (mediaItem.playbackProperties?.mimeType) {
            MimeTypes.APPLICATION_MPD, MimeTypes.APPLICATION_M3U8, MimeTypes.APPLICATION_SS -> {
                DownloadHelper.forMediaItem(
                    applicationContext,
                    mediaItem,
                    DefaultRenderersFactory(applicationContext),
                    httpDataSourceFactory
                )
            }
            else -> DownloadHelper.forMediaItem(applicationContext, mediaItem)
        }
    }

    private inner class DownloadManagerListener : DownloadManager.Listener {
        override fun onDownloadChanged(
            downloadManager: DownloadManager,
            download: Download,
            finalException: Exception?
        ) {
            downloads[download.request.uri] = download
            for (listener in listeners) {
                listener.onDownloadsChanged(download)
            }
            if (download.state == Download.STATE_COMPLETED) {
                // Add delta between estimation and reality to have a better availableBytesLeft
                availableBytesLeft += Util.fromUtf8Bytes(download.request.data)
                    .toLong() - download.bytesDownloaded
            }
        }

        override fun onDownloadRemoved(downloadManager: DownloadManager, download: Download) {
            downloads.remove(download.request.uri)
            for (listener in listeners) {
                listener.onDownloadsChanged(download)
            }

            // Add the estimated or downloaded bytes to the availableBytes
            availableBytesLeft += if (download.percentDownloaded == 100f) {
                download.bytesDownloaded
            } else {
                Util.fromUtf8Bytes(download.request.data).toLong()
            }
        }
    }

    // Can't use applicationContext because it'll result in a crash, instead
    // Use context of the activity calling for the AlertDialog
    private inner class StartDownloadDialogHelper(
        private val context: Context,
        private val downloadHelper: DownloadHelper,
        private val mediaItem: MediaItem,
        private val positiveCallback: (() -> Unit)? = null,
        private val dismissCallback: (() -> Unit)? = null,
        private val preparedCallback: ((Map<String, String>) -> Unit)? = null
    ) : DownloadHelper.Callback {

        private var trackSelectionDialog: AlertDialog? = null

        var formatDownloadable: MutableMap<String, Format> = mutableMapOf()


        val optionsDownload: MutableMap<String, String> = mutableMapOf()

        lateinit var qualitySelected: DefaultTrackSelector.Parameters


        init {
            downloadHelper.prepare(this)
        }

        fun release() {
            downloadHelper.release()
            trackSelectionDialog?.dismiss()
        }

        // DownloadHelper.Callback implementation.
        override fun onPrepared(helper: DownloadHelper) {
            if (helper.periodCount == 0) {
                Log.d(TAG, "No periods found. Downloading entire stream.")
//                startDownload()
                downloadHelper.release()
                return
            }

            val dialogBuilder: AlertDialog.Builder = AlertDialog.Builder(context)
            val mappedTrackInfo = downloadHelper.getMappedTrackInfo(0)

            for (i in 0 until mappedTrackInfo.rendererCount) {
                if (C.TRACK_TYPE_VIDEO == mappedTrackInfo.getRendererType(i)) {
                    val trackGroups: TrackGroupArray = mappedTrackInfo.getTrackGroups(i)
                    for (j in 0 until trackGroups.length) {
                        val trackGroup: TrackGroup = trackGroups[j]
                        for (k in 0 until trackGroup.length) {
                            val format = trackGroup.getFormat(k)
                            formatDownloadable[format.height.toString()] = format
                        }
                    }
                }
            }

            if (formatDownloadable.isEmpty()) {
                dialogBuilder.setTitle("An error occurred")
                    .setPositiveButton("OK", null)
                    .show()
                return
            }

            // We sort here because later we use formatDownloadable to select track
            val sortedMap = formatDownloadable.toList().sortedBy { it.second.height }.toMap()
            formatDownloadable.clear()
            formatDownloadable.putAll(sortedMap)

            val mediaItemTag: MediaItemTag = mediaItem.playbackProperties?.tag as MediaItemTag

            formatDownloadable.forEach {
                optionsDownload[it.key] =
                    (it.value.bitrate * mediaItemTag.duration).div(8000).formatFileSize()
            }
            preparedCallback?.invoke(optionsDownload)
        }

        override fun onPrepareError(helper: DownloadHelper, e: IOException) {
            Toast.makeText(applicationContext, "Download Start Error", Toast.LENGTH_LONG)
                .show()
            Log.e(
                TAG,
                if (e is LiveContentUnsupportedException) "Downloading live content unsupported" else "Failed to start download",
                e
            )
        }

        fun onSelectOptionsDownload(selectedKey: String) {
            val format = formatDownloadable[selectedKey] ?: return

            qualitySelected = DefaultTrackSelector(context).buildUponParameters()
                .setMinVideoSize(format.width, format.height)
                .setMinVideoBitrate(format.bitrate)
                .setMaxVideoSize(format.width, format.height)
                .setMaxVideoBitrate(format.bitrate)
                .build()
            Log.e(TAG, "format Selected= width: ${format.width}, height: ${format.height}")

            val mediaItemTag: MediaItemTag = mediaItem.playbackProperties?.tag as MediaItemTag
            downloadHelper.clearTrackSelections(0)
            downloadHelper.addTrackSelection(0, qualitySelected)
            val estimatedContentLength: Long =
                (qualitySelected.maxVideoBitrate * mediaItemTag.duration).div(C.MILLIS_PER_SECOND)
                    .div(C.BITS_PER_BYTE)
            if (availableBytesLeft > estimatedContentLength) {
                val downloadRequest: DownloadRequest = downloadHelper.getDownloadRequest(
                    (mediaItem.playbackProperties?.tag as MediaItemTag).title,
                    Util.getUtf8Bytes(estimatedContentLength.toString())
                )
                startDownload(downloadRequest)
                availableBytesLeft -= estimatedContentLength
                Log.e(TAG, "availableBytesLeft after calculation: $availableBytesLeft")
            } else {
                Toast.makeText(
                    context,
                    "Not enough space to download this file",
                    Toast.LENGTH_LONG
                ).show()
            }
            positiveCallback?.invoke()
        }

        fun onDismissOptionsDownload() {
            trackSelectionDialog = null
            downloadHelper.release()
            dismissCallback?.invoke()
        }

        // Internal methods.
        private fun startDownload(downloadRequest: DownloadRequest = buildDownloadRequest()) {
            DownloadService.sendAddDownload(
                applicationContext,
                MyDownloadService::class.java,
                downloadRequest,
                true
            )
        }

        private fun buildDownloadRequest(): DownloadRequest {
            return downloadHelper.getDownloadRequest(
                (mediaItem.playbackProperties?.tag as MediaItemTag).title,
                Util.getUtf8Bytes(mediaItem.playbackProperties?.uri.toString())
            )
        }
    }
}
