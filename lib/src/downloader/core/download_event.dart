class DownloadEvent {
  final double progress;

  final DownloadStatus status;

  final String url;

  DownloadEvent({required this.progress, required this.status, required this.url});
}

enum DownloadStatus { initial, downloading, completed, failed, queued, stopped, removed, restarting, unknown }
