import 'package:better_player/src/downloader/core/hls_downloader_configuration.dart';
import 'package:better_player/src/video_player/video_player_platform_interface.dart';
import 'package:better_player/src/downloader/core/download_event.dart';
import 'package:better_player/src/downloader/core/download.dart';
import 'package:flutter/services.dart';
import 'dart:async';

final VideoPlayerPlatform _videoPlayerPlatform = VideoPlayerPlatform.instance;
// This will clear all open videos on the platform when a full restart is
// performed.

enum HlsDownloaderErrorCodes { no_enough_space, cannot_download, unknown }

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

  Future<void> getCacheOptions({
    required ValueChanged<Map<String, double>?> successCallBack,
    required ValueChanged<HlsDownloaderErrorCodes>? errorCallBack,
  }) async {
    if (!_isCreated) PlatformException(message: "not created", code: '');
    await VideoPlayerPlatform.instance.getCacheOptions(
      _textureId,
      errorCallBack: errorCallBack,
      successCallBack: successCallBack,
    );
  }

  Future<void> onSelectCacheOptions(
    String selectedKey, {
    required VoidCallback successCallBack,
    required ValueChanged<HlsDownloaderErrorCodes>? errorCallBack,
  }) async {
    if (!_isCreated) PlatformException(message: "not created", code: '');
    return VideoPlayerPlatform.instance.onSelectCacheOptions(
      _textureId,
      selectedKey: selectedKey,
      errorCallBack: errorCallBack,
      successCallBack: successCallBack,
    );
  }

  Future<void> onDismissCacheOptions() async {
    if (!_isCreated) PlatformException(message: "not created", code: '');
    return VideoPlayerPlatform.instance.onDismissCacheOptions(_textureId);
  }

  Future<void> dispose() async {
    if (!_isCreated) return;
    await VideoPlayerPlatform.instance.disposeDownloader(_textureId);
    _eventSubscription?.cancel();
  }

  static Future<void> deleteDownload(String url) async {
    return VideoPlayerPlatform.instance.onDeleteDownload(url);
  }

  static Future<void> pauseDownload(String url) async {
    return VideoPlayerPlatform.instance.onPauseDownload(url);
  }

  static Future<void> resumeDownload(String url) async {
    await VideoPlayerPlatform.instance.onResumeDownload(url);
  }

  static Future<void> deleteAllDownloads() async {
    return VideoPlayerPlatform.instance.onDeleteAllDownloads();
  }

  static Future<List<Download>> getDownloads() async {
    return VideoPlayerPlatform.instance.getDownloads();
  }
}
