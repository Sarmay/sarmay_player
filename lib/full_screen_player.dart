import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:sarmay_player/media_player.dart';

class FullScreenPlayer extends StatefulWidget {
  final MediaPlayer player;
  const FullScreenPlayer({super.key, required this.player});

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer>
    with WidgetsBindingObserver {
  bool _showControls = false;
  Timer? _hideControlsTimer;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _showTip = false;

  late StreamSubscription<bool> _playingSubscription;
  late StreamSubscription<Duration> _durationSubscription;
  late StreamSubscription<Duration> _positionSubscription;
  late StreamSubscription<bool> _bufferingSubscription;
  late StreamSubscription<bool> _showTipSubscription;

  bool _isSeeking = false;
  Duration _seekPosition = Duration.zero;
  double _seekProgress = 0.0;

  bool _isLongPressSeeking = false;
  Timer? _longPressTimer;

  static const int _seekSeconds = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setLandscapeFullScreen();
    setupStreams();
    _showControlsHandel();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideControlsTimer?.cancel();
    _longPressTimer?.cancel();
    _playingSubscription.cancel();
    _durationSubscription.cancel();
    _positionSubscription.cancel();
    _bufferingSubscription.cancel();
    _showTipSubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setLandscapeFullScreen();
    }
  }

  void setupStreams() {
    if (mounted) {
      setState(() {
        _duration = widget.player.videoDuration;
        _position = widget.player.videoPosition;
        _isPlaying = widget.player.videoIsPlaying;
        _isBuffering = widget.player.videoIsBuffering;
        _showTip = widget.player.showTip;
      });
    }

    _durationSubscription = widget.player.duration.listen((Duration duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });
    _positionSubscription = widget.player.position.listen((Duration position) {
      if (mounted && !_isSeeking && !_isLongPressSeeking) {
        setState(() {
          _position = position;
        });
      }
    });

    _playingSubscription = widget.player.playing.listen((bool playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
        });
      }
    });

    _bufferingSubscription = widget.player.buffering.listen((bool buffering) {
      if (mounted) {
        setState(() {
          _isBuffering = buffering;
        });
      }
    });

    _showTipSubscription = widget.player.show.listen((bool showTip) {
      if (mounted) {
        setState(() {
          _showTip = showTip;
        });
      }
    });
  }

  void _setLandscapeFullScreen() {
    try {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]).then((val) {
        if (_isPlaying && Platform.isIOS) {
          widget.player.pause();
          widget.player.play();
        }
      });

      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    } catch (e) {
      if (kDebugMode) {
        print('设置全屏模式失败: $e');
      }
    }
  }

  void _restorePortraitMode() {
    try {
      if (Platform.isIOS) {
        SystemChrome.setPreferredOrientations([]);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    } catch (e) {
      if (kDebugMode) {
        print('恢复竖屏模式失败: $e');
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  Future<bool> _onWillPop() {
    _restorePortraitMode();
    Navigator.of(context).pop();
    return Future.value(true);
  }

  void _showControlsHandel() {
    _hideControlsTimer?.cancel();
    if (mounted) {
      if (_showControls) {
        setState(() {
          _showControls = false;
        });
      } else {
        setState(() {
          _showControls = true;
        });
        _hideControlsTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showControls = false;
            });
          }
        });
      }
    }
  }

  void _onDoubleTapLeft() {
    widget.player.seekBackward();
    _showSeekHint(isForward: false);
  }

  void _onDoubleTapRight() {
    widget.player.seekForward();
    _showSeekHint(isForward: true);
  }

  void _onDoubleTapCenter() {
    widget.player.playOrPause();
  }

  void _showSeekHint({required bool isForward}) {
    setState(() {
      _seekProgress = isForward ? 1.0 : -1.0;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _seekProgress = 0.0;
        });
      }
    });
  }

  void _onLongPressStart(bool isForward) {
    _isLongPressSeeking = true;
    _longPressTimer?.cancel();
    _longPressTimer = Timer.periodic(const Duration(milliseconds: 200), (
      timer,
    ) {
      if (_isLongPressSeeking) {
        final currentPos = _position;
        final seekAmount = Duration(seconds: isForward ? 2 : -2);
        final newPos = currentPos + seekAmount;
        final clampedPos = Duration(
          milliseconds: newPos.inMilliseconds.clamp(
            0,
            _duration.inMilliseconds,
          ),
        );
        widget.player.seek(clampedPos);
        setState(() {
          _position = clampedPos;
          _seekProgress = isForward ? 1.0 : -1.0;
        });
      }
    });
  }

  void _onLongPressEnd() {
    _isLongPressSeeking = false;
    _longPressTimer?.cancel();
    setState(() {
      _seekProgress = 0.0;
    });
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_duration.inSeconds > 0) {
      setState(() {
        _isSeeking = true;
        _seekPosition = _position;
      });
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isSeeking && _duration.inSeconds > 0) {
      final screenWidth = MediaQuery.of(context).size.width;
      final dragProgress = details.primaryDelta! / screenWidth;
      final totalDuration = _duration.inMilliseconds.toDouble();
      final seekAmount = dragProgress * totalDuration * 2;
      final newPosition = Duration(
        milliseconds: (_seekPosition.inMilliseconds + seekAmount.toInt()).clamp(
          0,
          _duration.inMilliseconds,
        ),
      );
      setState(() {
        _seekPosition = newPosition;
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isSeeking) {
      widget.player.seek(_seekPosition);
      setState(() {
        _isSeeking = false;
        _position = _seekPosition;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, params) {
        if (!didPop) {
          _onWillPop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onHorizontalDragStart: _onHorizontalDragStart,
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              Positioned.fill(
                child: Video(controller: widget.player.videoController),
              ),
              _buildGestureAreas(),
              if (_showControls ||
                  _isBuffering ||
                  _isSeeking ||
                  _isLongPressSeeking)
                _buildControlsOverlay(),
              if (_isSeeking) _buildSeekIndicator(),
              if (_seekProgress != 0.0) _buildSeekHint(),
              if (_showTip) _backIconWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGestureAreas() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTap: _onDoubleTapLeft,
            onLongPressStart: (_) => _onLongPressStart(false),
            onLongPressEnd: (_) => _onLongPressEnd(),
            onTap: _showControlsHandel,
            child: Container(color: Colors.transparent),
          ),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTap: _onDoubleTapCenter,
            onTap: _showControlsHandel,
            child: Container(color: Colors.transparent),
          ),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTap: _onDoubleTapRight,
            onLongPressStart: (_) => _onLongPressStart(true),
            onLongPressEnd: (_) => _onLongPressEnd(),
            onTap: _showControlsHandel,
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }

  Widget _backIconWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _onWillPop,
          ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    if (_showTip) {
      Widget tipWidget = widget.player.tipWidget != null
          ? SizedBox(
              height: double.infinity,
              width: double.infinity,
              child: widget.player.tipWidget,
            )
          : Container(
              color: const Color(0xB3000000),
              child: Center(
                child: Text(
                  "默认提示信息,提示时间:${widget.player.tipTime?.inSeconds}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
      return tipWidget;
    }

    return AnimatedOpacity(
      opacity: _showControls || _isBuffering ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xB3000000),
              Colors.transparent,
              Colors.transparent,
              const Color(0xB3000000),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTopControls(),
            _buildCenterControls(),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (!_showControls) {
                _showControlsHandel();
                return;
              }
              _onWillPop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCenterControls() {
    return Expanded(
      child: Center(
        child: _isBuffering
            ? const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(color: Colors.white),
              )
            : SizedBox(
                width: 100,
                height: 100,
                child: IconButton(
                  padding: EdgeInsetsGeometry.zero,
                  icon: Icon(
                    _isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white,
                    size: 80,
                  ),
                  onPressed: () {
                    if (!_showControls) {
                      _showControlsHandel();
                      return;
                    }
                    widget.player.playOrPause();
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            _formatDuration(_isSeeking ? _seekPosition : _position),
            style: const TextStyle(color: Colors.white),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: Colors.red,
                inactiveTrackColor: Colors.grey,
                thumbColor: Colors.red,
              ),
              child: Slider(
                value: _duration.inSeconds > 0
                    ? (_isSeeking ? _seekPosition : _position).inSeconds
                          .toDouble()
                    : 0.0,
                min: 0,
                max: _duration.inSeconds > 0
                    ? _duration.inSeconds.toDouble()
                    : 1.0,
                onChanged: (value) {
                  if (_duration.inSeconds > 0) {
                    widget.player.seek(Duration(seconds: value.toInt()));
                  }
                },
              ),
            ),
          ),
          Text(
            _formatDuration(_duration),
            style: const TextStyle(color: Colors.white),
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
            onPressed: () {
              if (!_showControls) {
                _showControlsHandel();
                return;
              }
              _onWillPop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSeekIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${_formatDuration(_seekPosition)} / ${_formatDuration(_duration)}',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildSeekHint() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _seekProgress > 0 ? Icons.fast_forward : Icons.fast_rewind,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '${_seekSeconds}s',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
