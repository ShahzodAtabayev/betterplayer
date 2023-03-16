package com.jhomlala.better_player.downloader.core

import android.app.Notification
import android.content.Context
import android.content.Intent
import android.util.Log
import com.google.android.exoplayer2.offline.Download
import com.google.android.exoplayer2.offline.DownloadManager
import com.google.android.exoplayer2.offline.DownloadRequest
import com.google.android.exoplayer2.offline.DownloadService
import com.google.android.exoplayer2.scheduler.PlatformScheduler
import com.google.android.exoplayer2.scheduler.Requirements
import com.google.android.exoplayer2.ui.DownloadNotificationHelper
import com.google.android.exoplayer2.util.NotificationUtil
import com.google.android.exoplayer2.util.Util
import com.jhomlala.better_player.BetterPlayerPlugin
import com.jhomlala.better_player.R
import com.jhomlala.better_player.downloader.core.DownloadUtil.DOWNLOAD_NOTIFICATION_CHANNEL_ID

private const val JOB_ID = 1
private const val FOREGROUND_NOTIFICATION_ID = 1

class VoxeDownloadService : DownloadService(
    FOREGROUND_NOTIFICATION_ID,
    DEFAULT_FOREGROUND_NOTIFICATION_UPDATE_INTERVAL,
    DOWNLOAD_NOTIFICATION_CHANNEL_ID,
    R.string.exo_download_notification_channel_name,
    0
) {
    private var title: String? = null


    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        title = intent?.getStringExtra(BetterPlayerPlugin.MOVIE_TITLE)
        return super.onStartCommand(intent, flags, startId)
    }

    override fun getDownloadManager(): DownloadManager {

        // This will only happen once, because getDownloadManager is guaranteed to be called only once
        // in the life cycle of the process.
        val downloadManager: DownloadManager = DownloadUtil.getDownloadManager(this)
        val downloadNotificationHelper: DownloadNotificationHelper =
            DownloadUtil.getDownloadNotificationHelper(this)
        downloadManager.addListener(
            TerminalStateNotificationHelper(
                this, downloadNotificationHelper, FOREGROUND_NOTIFICATION_ID + 1, title ?: ""
            )
        )
        return downloadManager
    }

    override fun getScheduler(): PlatformScheduler? {
        return if (Util.SDK_INT >= 21) PlatformScheduler(this, JOB_ID) else null
    }

    override fun getForegroundNotification(
        downloads: MutableList<Download>, notMetRequirements: Int
    ): Notification {

        return DownloadUtil.getDownloadNotificationHelper(this).buildProgressNotification(
            this,
            R.drawable.ic_download,
            null,
            null,
            downloads,
            Requirements.NETWORK_UNMETERED or Requirements.NETWORK
        )
    }


    /**
     * Creates and displays notifications for downloads when they complete or fail.
     *
     *
     * This helper will outlive the lifespan of a single instance of [VoxeDownloadService].
     * It is static to avoid leaking the first [VoxeDownloadService] instance.
     */
    private class TerminalStateNotificationHelper(
        context: Context,
        private val notificationHelper: DownloadNotificationHelper,
        firstNotificationId: Int,
        val title: String
    ) : DownloadManager.Listener {
        private val context: Context = context.applicationContext
        private var nextNotificationId: Int = firstNotificationId
        override fun onDownloadChanged(
            downloadManager: DownloadManager, download: Download, finalException: Exception?
        ) {
            val title =
                download.request.uri.pathSegments[download.request.uri.pathSegments.size - 2]
            val notification: Notification = when (download.state) {
                Download.STATE_COMPLETED -> {
                    notificationHelper.buildDownloadCompletedNotification(
                        context, R.drawable.ic_download_done,  /* contentIntent= */
                        null, title
                    )
                }
                Download.STATE_FAILED -> {
                    notificationHelper.buildDownloadFailedNotification(
                        context, R.drawable.ic_error,  /* contentIntent= */
                        null, title
                    )
                }
                Download.STATE_STOPPED -> {
                    notificationHelper.buildDownloadFailedNotification(
                        context, R.drawable.ic_pause_circle,  /* contentIntent= */
                        null, title
                    )
                }
                else -> {
                    return
                }
            }
            NotificationUtil.setNotification(context, nextNotificationId++, notification)
        }

    }

}