class DownloadEvent {
  final double progress;

  final DownloadState status;

  final String url;
  final int? size;

  DownloadEvent({required this.progress, required this.status, required this.url, required this.size});
}

enum DownloadState {
  initial,
  downloading,
  completed,
  failed,
  queued,
  stopped,
  removed,
  restarting,
  unknown
}
