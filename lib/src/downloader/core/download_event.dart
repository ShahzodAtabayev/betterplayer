class DownloadEvent {
  final double progress;

  /// downloading, downloaded
  final String status;

  DownloadEvent({required this.progress, required this.status});
}
