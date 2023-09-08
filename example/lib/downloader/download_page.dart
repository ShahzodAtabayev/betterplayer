import 'package:better_player_example/downloader/download_item.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

class ContentModel {
  final String url;
  final String name;
  final int duration;

  ContentModel({required this.url, required this.name, required this.duration});
}

class DownloadPage extends StatefulWidget {
  const DownloadPage({Key? key}) : super(key: key);

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final List<ContentModel> _list = [
    ContentModel(
      url: "https://cdn.voxe.tv/s3/trailers/the-boss-baby-family-business-official-trailer/master.m3u8",
      name: "Boss family trailer",
      duration: 137,
    ),
    ContentModel(
      url: "https://videos.voxe.tv/movies/ford-protiv-ferrari-Qv-qKBNmEXV/master.m3u8",
      name: "Ford Ferrari",
      duration: 9120,
    ),
  ];

  @override
  void initState() {
    HlsDownloader.getDownloads();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Example"),
        actions: [
          IconButton(
            onPressed: () async {},
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
      body: ListView.separated(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemBuilder: (_, index) {
          return DownloadItem(model: _list[index]);
        },
        separatorBuilder: (_, index) {
          return SizedBox(height: 4);
        },
        itemCount: _list.length,
      ),
    );
  }
}
