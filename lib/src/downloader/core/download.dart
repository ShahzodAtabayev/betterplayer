import 'package:better_player/better_player.dart';

class Download {
  final DownloadStatus status;
  final double percentDownloaded;
  final String url;

  Download({required this.status, required this.percentDownloaded, required this.url});
}