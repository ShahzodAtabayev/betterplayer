import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:better_player/better_player.dart';
import 'package:better_player/src/configuration/better_player_controller_event.dart';
import 'package:better_player/src/controls/better_player_cupertino_controls.dart';
import 'package:better_player/src/controls/better_player_material_controls.dart';
import 'package:better_player/src/core/better_player_controller.dart';
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_configuration.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_drawer.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart' as Vector;

class BetterPlayerWithControls extends StatefulWidget {
  final BetterPlayerController? controller;

  const BetterPlayerWithControls({Key? key, this.controller}) : super(key: key);

  @override
  _BetterPlayerWithControlsState createState() =>
      _BetterPlayerWithControlsState();
}

class _BetterPlayerWithControlsState extends State<BetterPlayerWithControls> {
  BetterPlayerSubtitlesConfiguration get subtitlesConfiguration =>
      widget.controller!.betterPlayerConfiguration.subtitlesConfiguration;

  BetterPlayerControlsConfiguration get controlsConfiguration =>
      widget.controller!.betterPlayerConfiguration.controlsConfiguration;

  final StreamController<bool> playerVisibilityStreamController =
      StreamController();

  bool _initialized = false;

  StreamSubscription? _controllerEventSubscription;

  @override
  void initState() {
    playerVisibilityStreamController.add(true);
    _controllerEventSubscription =
        widget.controller!.controllerEventStream.listen(_onControllerChanged);
    super.initState();
  }

  @override
  void didUpdateWidget(BetterPlayerWithControls oldWidget) {
    if (oldWidget.controller != widget.controller) {
      _controllerEventSubscription?.cancel();
      _controllerEventSubscription =
          widget.controller!.controllerEventStream.listen(_onControllerChanged);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    playerVisibilityStreamController.close();
    _controllerEventSubscription?.cancel();
    super.dispose();
  }

  void _onControllerChanged(BetterPlayerControllerEvent event) {
    setState(() {
      if (!_initialized) {
        _initialized = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final BetterPlayerController betterPlayerController =
        BetterPlayerController.of(context);

    double? aspectRatio;
    if (betterPlayerController.isFullScreen) {
      if (betterPlayerController.betterPlayerConfiguration
              .autoDetectFullscreenDeviceOrientation ||
          betterPlayerController
              .betterPlayerConfiguration.autoDetectFullscreenAspectRatio) {
        aspectRatio =
            betterPlayerController.videoPlayerController?.value.aspectRatio ??
                1.0;
      } else {
        aspectRatio = betterPlayerController
                .betterPlayerConfiguration.fullScreenAspectRatio ??
            BetterPlayerUtils.calculateAspectRatio(context);
      }
    } else {
      aspectRatio = betterPlayerController.getAspectRatio();
    }

    aspectRatio ??= 16 / 9;
    final innerContainer = AspectRatio(
      aspectRatio: aspectRatio,
      child: _buildPlayerWithControls(betterPlayerController, context),
    );

    if (betterPlayerController.betterPlayerConfiguration.expandToFill) {
      return Center(child: innerContainer);
    } else {
      return innerContainer;
    }
  }

  Container _buildPlayerWithControls(
      BetterPlayerController betterPlayerController, BuildContext context) {
    final configuration = betterPlayerController.betterPlayerConfiguration;
    var rotation = configuration.rotation;

    if (!(rotation <= 360 && rotation % 90 == 0)) {
      BetterPlayerUtils.log("Invalid rotation provided. Using rotation = 0");
      rotation = 0;
    }
    if (betterPlayerController.betterPlayerDataSource == null) {
      return Container();
    }
    _initialized = true;

    final bool placeholderOnTop =
        betterPlayerController.betterPlayerConfiguration.placeholderOnTop;
    // ignore: avoid_unnecessary_containers
    return Container(
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          if (placeholderOnTop) _buildPlaceholder(betterPlayerController),
          Transform.rotate(
            angle: rotation * pi / 180,
            child: _BetterPlayerVideoFitWidget(
              betterPlayerController,
              betterPlayerController.betterPlayerConfiguration.fit,
            ),
          ),
          betterPlayerController.betterPlayerConfiguration.overlay ??
              Container(),
          BetterPlayerSubtitlesDrawer(
            betterPlayerController: betterPlayerController,
            betterPlayerSubtitlesConfiguration: subtitlesConfiguration,
            subtitles: betterPlayerController.subtitlesLines,
            playerVisibilityStream: playerVisibilityStreamController.stream,
          ),
          if (!placeholderOnTop) _buildPlaceholder(betterPlayerController),
          _buildControls(context, betterPlayerController),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BetterPlayerController betterPlayerController) {
    return betterPlayerController.betterPlayerDataSource!.placeholder ??
        betterPlayerController.betterPlayerConfiguration.placeholder ??
        Container();
  }

  Widget _buildControls(
    BuildContext context,
    BetterPlayerController betterPlayerController,
  ) {
    if (controlsConfiguration.showControls) {
      BetterPlayerTheme? playerTheme = controlsConfiguration.playerTheme;
      if (playerTheme == null) {
        if (Platform.isAndroid) {
          playerTheme = BetterPlayerTheme.material;
        } else {
          playerTheme = BetterPlayerTheme.cupertino;
        }
      }

      if (controlsConfiguration.customControlsBuilder != null &&
          playerTheme == BetterPlayerTheme.custom) {
        return controlsConfiguration.customControlsBuilder!(
            betterPlayerController, onControlsVisibilityChanged);
      } else if (playerTheme == BetterPlayerTheme.material) {
        return _buildMaterialControl();
      } else if (playerTheme == BetterPlayerTheme.cupertino) {
        return _buildCupertinoControl();
      }
    }

    return const SizedBox();
  }

  Widget _buildMaterialControl() {
    return BetterPlayerMaterialControls(
      onControlsVisibilityChanged: onControlsVisibilityChanged,
      controlsConfiguration: controlsConfiguration,
    );
  }

  Widget _buildCupertinoControl() {
    return BetterPlayerCupertinoControls(
      onControlsVisibilityChanged: onControlsVisibilityChanged,
      controlsConfiguration: controlsConfiguration,
    );
  }

  void onControlsVisibilityChanged(bool state) {
    playerVisibilityStreamController.add(state);
  }
}

///Widget used to set the proper box fit of the video. Default fit is 'fill'.
class _BetterPlayerVideoFitWidget extends StatefulWidget {
  const _BetterPlayerVideoFitWidget(
    this.betterPlayerController,
    this.boxFit, {
    Key? key,
  }) : super(key: key);

  final BetterPlayerController betterPlayerController;
  final BoxFit boxFit;

  @override
  _BetterPlayerVideoFitWidgetState createState() =>
      _BetterPlayerVideoFitWidgetState();
}

class _BetterPlayerVideoFitWidgetState
    extends State<_BetterPlayerVideoFitWidget>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? get controller =>
      widget.betterPlayerController.videoPlayerController;
  late Animation _animation;
  late AnimationController _animationController;

  bool _initialized = false;

  VoidCallback? _initializedListener;

  bool _started = false;

  StreamSubscription? _controllerEventSubscription;

  late BoxFit _videoFit;

  @override
  void initState() {
    _videoFit = widget.betterPlayerController.betterPlayerConfiguration.fit;
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _animation = Tween(begin: 1.0, end: 1.25).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
          ..addListener(() {
            setState(() {});
          }));
    super.initState();
    if (!widget.betterPlayerController.betterPlayerConfiguration
        .showPlaceholderUntilPlay) {
      _started = true;
    } else {
      _started = widget.betterPlayerController.hasCurrentDataSourceStarted;
    }

    _initialize();
  }

  @override
  void didUpdateWidget(_BetterPlayerVideoFitWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.betterPlayerController.videoPlayerController != controller) {
      if (_initializedListener != null) {
        oldWidget.betterPlayerController.videoPlayerController!
            .removeListener(_initializedListener!);
      }
      _initialized = false;
      _initialize();
    }
  }

  void _initialize() {
    if (controller?.value.initialized == false) {
      _initializedListener = () {
        if (!mounted) {
          return;
        }

        if (_initialized != controller!.value.initialized) {
          _initialized = controller!.value.initialized;
          setState(() {});
        }
      };
      controller!.addListener(_initializedListener!);
    } else {
      _initialized = true;
    }

    _controllerEventSubscription =
        widget.betterPlayerController.controllerEventStream.listen((event) {
      if (event == BetterPlayerControllerEvent.play) {
        if (!_started) {
          setState(() {
            _started =
                widget.betterPlayerController.hasCurrentDataSourceStarted;
          });
        }
      }
      if (event == BetterPlayerControllerEvent.setupDataSource) {
        setState(() {
          _started = false;
        });
      }
      if (event == BetterPlayerControllerEvent.toggleZoom) {
        if (widget.betterPlayerController.isZoom) {
          _videoFit = BoxFit.cover;
        } else {
          _videoFit = BoxFit.contain;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (_initialized && _started) {
      var height = size.height;
      var rot =
          (widget.betterPlayerController.betterPlayerDataSource?.rotation ??
              1.6);
      return Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: FittedBox(
            fit: _videoFit,
            child: SizedBox(
              height: height,
              width: height * rot,
              child: VideoPlayer(controller),
            ),
          ),
        ),
      );
      /*Center(
        child: FittedBox(
          fit: widget.boxFit,
          child: SizedBox(
            height: height,
            width: height * rot,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3(
                Vector.Vector3(
                  _animation.value,
                  _animation.value,
                  _animation.value,
                ),
              ),
              child: VideoPlayer(controller),
            ),
          ),
        ),
      );*/
    } else {
      return const SizedBox();
    }
  }

  @override
  void dispose() {
    if (_initializedListener != null) {
      widget.betterPlayerController.videoPlayerController!
          .removeListener(_initializedListener!);
    }
    _controllerEventSubscription?.cancel();
    super.dispose();
  }
}
