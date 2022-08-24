package com.jhomlala.better_player

import android.content.Context
import android.net.Uri
import android.os.StatFs
import com.google.android.exoplayer2.DefaultRenderersFactory
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.offline.*
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
class DownloadTracker(context: Context, private val httpDataSourceFactory: HttpDataSource.Factory, private val downloadManager: DownloadManager) {
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
    private var availableBytesLeft: Long = StatFs(DownloadUtil.getDownloadDirectory(context).path).availableBytes

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
        while(coroutineContext.isActive) {
            offer(downloads.values.toList())
            delay(1000)
        }
    }

    @ExperimentalCoroutinesApi
    suspend fun getCurrentProgressDownload(uri: Uri?): Flow<Float?> {
        var percent: Float? = downloadManager.currentDownloads.find { it.request.uri == uri }?.percentDownloaded
        return callbackFlow {
            while(percent != null) {
                percent = downloadManager.currentDownloads.find { it.request.uri == uri }?.percentDownloaded
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
        override fun onDownloadChanged(downloadManager: DownloadManager, download: Download, finalException: Exception?) {
            downloads[download.request.uri] = download
            for (listener in listeners) {
                listener.onDownloadsChanged(download)
            }
            if(download.state == Download.STATE_COMPLETED) {
                // Add delta between estimation and reality to have a better availableBytesLeft
                availableBytesLeft += Util.fromUtf8Bytes(download.request.data).toLong() - download.bytesDownloaded
            }
        }

        override fun onDownloadRemoved(downloadManager: DownloadManager, download: Download) {
            downloads.remove(download.request.uri)
            for (listener in listeners) {
                listener.onDownloadsChanged(download)
            }

            // Add the estimated or downloaded bytes to the availableBytes
            availableBytesLeft += if(download.percentDownloaded == 100f) {
                download.bytesDownloaded
            } else {
                Util.fromUtf8Bytes(download.request.data).toLong()
            }
        }
    }
}
