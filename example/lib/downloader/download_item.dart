import 'package:better_player_example/downloader/player/player_page.dart';
import 'package:better_player_example/downloader/download_page.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class DownloadItem extends StatefulWidget {
  final ContentModel model;

  const DownloadItem({Key? key, required this.model}) : super(key: key);

  @override
  State<DownloadItem> createState() => _DownloadItemState();
}

class _DownloadItemState extends State<DownloadItem> {
  final _hlsDownloaderPlugin = HlsDownloader();
  DownloadState? _state;

  @override
  void initState() {
    final configuration = HlsDownloaderConfiguration(
      url: widget.model.url,
      title: widget.model.name,
      duration: widget.model.duration,
    );
    _hlsDownloaderPlugin.create(configuration: configuration).whenComplete(() {
      print("Created success");
    });
    HlsDownloader.getDownloadState(url: widget.model.url).then((value) {
      setState(() => _state = value);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DownloadEvent>(
      stream: _hlsDownloaderPlugin.videoEventStreamController.stream,
      builder: (context, snapshot) {
        if (snapshot.data?.status != null) {
          _state = snapshot.data?.status;
        }
        return ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 8),
          onTap: () async {
            if (Platform.isIOS) {
              await _hlsDownloaderPlugin.playIos(
                successCallBack: () {},
                errorCallBack: (error) {},
              );
            } else {
              Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(builder: (_) {
                  return const PlayerPage();
                }),
              );
            }
          },
          title: Text(widget.model.name),
          subtitle: _state == DownloadState.downloading
              ? LinearProgressIndicator(value: (snapshot.data?.progress ?? 1) / 100)
              : Text(_state?.name ?? ''),
          trailing: IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              showBottomSheet<void>(
                context: context,
                builder: (_) {
                  return Container(
                    color: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: double.infinity),
                        if (_state == null || _state == DownloadState.initial)
                          TextButton(onPressed: _download, child: Text("Download")),
                        if (_state == DownloadState.completed) TextButton(onPressed: _delete, child: Text("Remove")),
                        if (_state == DownloadState.downloading) TextButton(onPressed: _pause, child: Text("Pause")),
                        if (_state == DownloadState.stopped) TextButton(onPressed: _resume, child: Text("Resume")),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _download() async {
    Navigator.of(context).pop();
    await _hlsDownloaderPlugin.getCacheOptions(
      errorCallBack: (code) {},
      successCallBack: (result) {
        if (result != null) {
          showModalBottomSheet<dynamic>(
            context: context,
            builder: (_) {
              return Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: result.keys.length,
                  itemBuilder: (_, index) {
                    final key = result.keys.elementAt(index);
                    final value = result.values.elementAt(index);
                    return ListTile(
                      onTap: () {
                        _hlsDownloaderPlugin.onSelectCacheOptions(
                          key,
                          errorCallBack: (code) {},
                          successCallBack: () {},
                        );
                        Navigator.pop(context);
                      },
                      title: Text("Quality: ${key}p - $value"),
                    );
                  },
                ),
              );
            },
          );
        }
      },
    );
  }

  void _delete() async {
    Navigator.of(context).pop();
    await HlsDownloader.deleteDownload(widget.model.url);
  }

  void _pause() async {
    Navigator.of(context).pop();
    await HlsDownloader.pauseDownload(widget.model.url);
  }

  void _resume() async {
    Navigator.of(context).pop();
    await HlsDownloader.resumeDownload(widget.model.url);
  }
}
