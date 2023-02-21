import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({Key? key}) : super(key: key);

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late BetterPlayerController _betterPlayerController;
  late BetterPlayerDataSource _betterPlayerDataSource;

  @override
  void initState() {
    BetterPlayerConfiguration betterPlayerConfiguration = const BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      autoPlay: true,
      looping: true,
      autoDispose: false,
      allowedScreenSleep: false,
    );
    _betterPlayerDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      "https://cdn.voxe.tv/s3/trailers/the-boss-baby-family-business-official-trailer/master.m3u8",
      useDownloadedFile: true,
      bufferingConfiguration: const BetterPlayerBufferingConfiguration(
        maxBufferMs: 500000,
        minBufferMs: 350000,
      ),
      headers: {"Referer": "https://voxe.tv/"},
      startAt: Duration(seconds: 12),
      videoFormat: BetterPlayerVideoFormat.hls,
      rotation: 1.6,
      title: "sdvdsv",
    );

    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(_betterPlayerDataSource);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: BetterPlayer(controller: _betterPlayerController),
          ),
        ],
      ),
    );
  }
}
