import 'package:better_player_example/downloader/player/player_page.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({Key? key}) : super(key: key);

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final _hlsDownloaderPlugin = HlsDownloader();
  final url = 'https://cdn.voxe.tv/s3/trailers/the-boss-baby-family-business-official-trailer/master.m3u8';
  final duration = 148000; //ms

  @override
  void initState() {
    final configuration = HlsDownloaderConfiguration(url: url, duration: duration);
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
              Navigator.push<dynamic>(context, MaterialPageRoute<dynamic>(builder: (_) {
                return const PlayerPage();
              }));
            },
            icon: const Icon(Icons.play_arrow),
          ),
          IconButton(
            onPressed: () {
              HlsDownloader.deleteAllDownloads();
            },
            icon: Icon(Icons.delete),
          ),
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
                            }),
                      );
                    });
              }
            },
          );
        },
        child: const Icon(Icons.download),
      ),
    );
  }
}
