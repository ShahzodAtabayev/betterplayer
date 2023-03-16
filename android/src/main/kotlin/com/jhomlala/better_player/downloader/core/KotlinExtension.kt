package com.jhomlala.better_player.downloader.core

import android.content.Context
import android.content.Intent
import com.google.android.exoplayer2.offline.Download
import com.google.android.exoplayer2.offline.DownloadRequest
import com.google.android.exoplayer2.offline.DownloadService
import com.google.android.exoplayer2.util.Util
import com.jhomlala.better_player.BetterPlayerPlugin
import java.text.DecimalFormat

fun Long.formatFileSize(): String {
    val b = this.toDouble()
    val k = this / 1024.0
    val m = this / 1024.0 / 1024.0
    val g = this / 1024.0 / 1024.0 / 1024.0
    val t = this / 1024.0 / 1024.0 / 1024.0 / 1024.0
    val dec = DecimalFormat("0.00")
    return when {
        t > 1 -> {
            dec.format(t) + " TB"
        }
        g > 1 -> {
            dec.format(g) + " GB"
        }
        m > 1 -> {
            dec.format(m) + " MB"
        }
        k > 1 -> {
            dec.format(k) + " KB"
        }
        else -> {
            dec.format(b) + " Bytes"
        }
    }
}

fun sendAddDownloadVoxe(
    context: Context?,
    clazz: Class<out DownloadService?>?,
    downloadRequest: DownloadRequest?,
    foreground: Boolean,
    title: String?,
) {
    val intent = buildAddDownloadIntentVoxe(
        context!!,
        clazz!!, downloadRequest!!, Download.STOP_REASON_NONE, foreground, title
    )
    startServiceVoxe(context, intent, foreground)
}

fun startServiceVoxe(context: Context, intent: Intent, foreground: Boolean) {
    if (foreground) {
        Util.startForegroundService(context, intent)
    } else {
        context.startService(intent)
    }
}

fun buildAddDownloadIntentVoxe(
    context: Context?,
    clazz: Class<out DownloadService?>?,
    downloadRequest: DownloadRequest?,
    stopReason: Int,
    foreground: Boolean,
    title: String?,
): Intent {
    return getIntentVoxe(
        context!!,
        clazz!!, DownloadService.ACTION_ADD_DOWNLOAD, foreground
    ).putExtra(DownloadService.KEY_DOWNLOAD_REQUEST, downloadRequest)
        .putExtra(DownloadService.KEY_STOP_REASON, stopReason)
        .putExtra(BetterPlayerPlugin.MOVIE_TITLE, title)
}

fun getIntentVoxe(
    context: Context, clazz: Class<out DownloadService?>, action: String, foreground: Boolean
): Intent {
    return getIntentVoxe(context, clazz, action).putExtra(
        DownloadService.KEY_FOREGROUND,
        foreground
    )
}

fun getIntentVoxe(
    context: Context, clazz: Class<out DownloadService?>, action: String
): Intent {
    return Intent(context, clazz).setAction(action)
}