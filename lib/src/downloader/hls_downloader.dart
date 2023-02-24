import 'package:better_player/src/downloader/core/hls_downloader_configuration.dart';
import 'package:better_player/src/video_player/video_player_platform_interface.dart';
import 'package:better_player/src/downloader/core/download_event.dart';
import 'package:flutter/services.dart';
import 'dart:async';

final VideoPlayerPlatform _videoPlayerPlatform = VideoPlayerPlatform.instance;
// This will clear all open videos on the platform when a full restart is
// performed.

class HlsDownloader {
  int? _textureId;

  bool _isCreated = false;

  bool get isCreated => _isCreated;

  StreamSubscription<dynamic>? _eventSubscription;

  late HlsDownloaderConfiguration _configuration;

  HlsDownloaderConfiguration get configuration => _configuration;

  final StreamController<DownloadEvent> videoEventStreamController = StreamController.broadcast();

  Future<void> create({required HlsDownloaderConfiguration configuration}) async {
    _configuration = configuration;
    _textureId = await VideoPlayerPlatform.instance.createDownloader(configuration: configuration);
    _isCreated = true;

    void eventListener(DownloadEvent event) {
      videoEventStreamController.add(event);
    }

    void errorListener(Object object) {
      print(object);
    }

    _eventSubscription =
        _videoPlayerPlatform.downloadEventsFor(_textureId).listen(eventListener, onError: errorListener);
  }

  Future<Map<String, double>?> getCacheOptions({required ValueChanged<String>? errorCallBack}) async {
    if (!_isCreated) PlatformException(message: "not created", code: '');
    return VideoPlayerPlatform.instance.getCacheOptions(_textureId, errorCallBack: errorCallBack);
  }

  Future<void> onSelectCacheOptions(String selectedKey, {required ValueChanged<String>? errorCallBack}) async {
    if (!_isCreated) PlatformException(message: "not created", code: '');
    return VideoPlayerPlatform.instance.onSelectCacheOptions(
      _textureId,
      selectedKey: selectedKey,
      errorCallBack: errorCallBack,
    );
  }

  Future<void> onDismissCacheOptions() async {
    if (!_isCreated) PlatformException(message: "not created", code: '');
    return VideoPlayerPlatform.instance.onDismissCacheOptions(_textureId);
  }

  static Future<void> deleteDownload(String url) async {
    return VideoPlayerPlatform.instance.onDeleteDownload(url);
  }

  static Future<void> deleteAllDownloads() async {
    return VideoPlayerPlatform.instance.onDeleteAllDownloads();
  }

  void dispose() {
    _eventSubscription?.cancel();
  }
}
