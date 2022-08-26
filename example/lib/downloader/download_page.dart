import 'package:better_player/better_player.dart';
import 'package:better_player_example/downloader/player/player_page.dart';
import 'package:flutter/material.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({Key? key}) : super(key: key);

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final _hlsDownloaderPlugin = HlsDownloader();
  final url =
      'https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8';
  final duration = 210000; //ms

  @override
  void initState() {
    final configuration =
        HlsDownloaderConfiguration(url: url, duration: duration);
    _hlsDownloaderPlugin.create(configuration: configuration).whenComplete(() {
      print("Created success");
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Example"),
        actions: [
          IconButton(
            onPressed: () async {
              Navigator.push<dynamic>(context,
                  MaterialPageRoute<dynamic>(builder: (_) {
                return const PlayerPage();
              }));
            },
            icon: const Icon(Icons.play_arrow),
          )
        ],
      ),
      body: StreamBuilder<DownloadEvent>(
          stream: _hlsDownloaderPlugin.videoEventStreamController.stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Center(
                child: Text(
                  "Progress: ${snapshot.data?.progress}\n"
                  "Status: ${snapshot.data?.status}",
                ),
              );
            } else {
              return const Center(
                child: Text("No download"),
              );
            }
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await _hlsDownloaderPlugin.getCacheOptions();
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
                              _hlsDownloaderPlugin.onSelectCacheOptions(key);
                              Navigator.pop(context);
                            },
                            title: Text("Quality: ${key}p - $value"),
                          );
                        }),
                  );
                });
          } else {
            print("no result");
          }
        },
        child: const Icon(Icons.download),
      ),
    );
  }
}
