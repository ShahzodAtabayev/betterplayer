import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

class CacheOptionsPage extends StatefulWidget {
  const CacheOptionsPage({Key? key}) : super(key: key);

  @override
  State<CacheOptionsPage> createState() => _CacheOptionsPageState();
}

class _CacheOptionsPageState extends State<CacheOptionsPage> {
  late final BetterPlayerController _controller;

  @override
  void initState() {
    _controller = BetterPlayerController(BetterPlayerConfiguration());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final options = await _controller
              .getCacheOptions("https://cdn.voxe.tv/s3/cartoons/dusha-soul-2020-bdrip-720p-x264-rus-eng/master.m3u8");

          options?.forEach((key, value) {
            print("Quality: ${key} Size: ${value}");
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
