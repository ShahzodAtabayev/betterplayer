class DownloadEvent {
  final double progress;

  /// downloading, downloaded
  final DownloadStatus status;

  DownloadEvent({required this.progress, required this.status});
}

enum DownloadStatus {initial, downloading, downloaded, pause, failure }
