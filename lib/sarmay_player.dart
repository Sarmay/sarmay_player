import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:sarmay_player/custom_video_controls.dart';
import 'package:sarmay_player/media_player.dart';
export 'package:sarmay_player/media_player.dart';

/// 初始化media_kit，必须在runApp之前调用
void ensurePlayerInitialized({String? libMpv}) {
  MediaKit.ensureInitialized(libmpv: libMpv);
}

class SarmayPlayer extends StatefulWidget {
  final MediaPlayer player;
  final VideoController controller;
  final void Function(bool completed)? onCompleted;
  final void Function(bool initialized)? onInitialized;
  final void Function(String errMsg)? onError;

  const SarmayPlayer({
    super.key,
    required this.player,
    required this.controller,
    this.onCompleted,
    this.onInitialized,
    this.onError,
  });

  @override
  State<SarmayPlayer> createState() => _SarmayPlayerState();
}

class _SarmayPlayerState extends State<SarmayPlayer> {
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMsg = "";

  @override
  void initState() {
    super.initState();
    setupStreams();
  }

  void setupStreams() {
    widget.player.initialized.listen((bool initialized) {
      if (widget.onInitialized != null) {
        widget.onInitialized!(initialized);
      }
      if (mounted) {
        setState(() {
          _hasError = false;
          _errorMsg = "";
          _isInitialized = initialized;
        });
      }
    });

    widget.player.error.listen((String errorMsg) {
      if (mounted) {
        setState(() {
          _errorMsg = errorMsg;
          _hasError = true;
        });
      }
      if (widget.onError != null) {
        widget.onError!(errorMsg);
      }
    });

    widget.player.completed.listen((bool completed) {
      if (widget.onCompleted != null) {
        widget.onCompleted!(completed);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "播放出错!$_errorMsg",
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          // Video player
          Video(controller: widget.controller, controls: NoVideoControls),
          // Custom controls
          Positioned.fill(child: CustomVideoControls(player: widget.player)),
        ],
      ),
    );
  }
}
