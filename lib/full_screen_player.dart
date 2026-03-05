import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:sarmay_player/media_player.dart';
import 'package:volume_controller/volume_controller.dart';

enum _DragDirection { none, horizontal, vertical }

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

  double _brightness = 0.5;
  double _volume = 1.0;
  bool _isAdjustingBrightness = false;
  bool _isAdjustingVolume = false;
  double _dragStartX = 0;
  double _dragStartY = 0;
  double _startBrightness = 0.5;
  double _startVolume = 1.0;

  _DragDirection _dragDirection = _DragDirection.none;
  bool _isDraggingLeft = false;

  bool _showBrightnessIndicator = false;
  bool _showVolumeIndicator = false;
  Timer? _brightnessIndicatorTimer;
  Timer? _volumeIndicatorTimer;

  double _playbackSpeed = 1.0;
  bool _showSpeedDialog = false;
  final List<double> _speedOptions = [0.5, 1.0, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    defaultEnterNativeFullscreen();
    setupStreams();
    _showControlsHandel();
    _initBrightness();
    _initVolume();
  }

  Future<void> _initBrightness() async {
    try {
      final brightness = await ScreenBrightness().current;
      setState(() {
        _brightness = brightness;
      });
    } catch (e) {
      debugPrint('获取亮度失败: $e');
    }
  }

  Future<void> _initVolume() async {
    try {
      VolumeController.instance.addListener((volume) {
        if (mounted) {
          setState(() {
            _volume = volume;
          });
        }
      }, fetchInitialVolume: true);
      final volume = await VolumeController.instance.getVolume();
      setState(() {
        _volume = volume;
      });
    } catch (e) {
      debugPrint('获取音量失败: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideControlsTimer?.cancel();
    _longPressTimer?.cancel();
    _brightnessIndicatorTimer?.cancel();
    _volumeIndicatorTimer?.cancel();
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
      defaultEnterNativeFullscreen();
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  Future<bool> _onWillPop() async {
    await defaultExitNativeFullscreen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
    return true;
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

  void _onPanStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _dragStartY = details.globalPosition.dy;
    _dragDirection = _DragDirection.none;

    final screenWidth = MediaQuery.of(context).size.width;
    _isDraggingLeft = details.globalPosition.dx < screenWidth / 3;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragDirection == _DragDirection.none) {
      final dx = (details.globalPosition.dx - _dragStartX).abs();
      final dy = (details.globalPosition.dy - _dragStartY).abs();

      if (dx > 20 || dy > 20) {
        if (dx > dy) {
          _dragDirection = _DragDirection.horizontal;
          if (_duration.inSeconds > 0) {
            setState(() {
              _isSeeking = true;
              _seekPosition = _position;
            });
          }
        } else {
          _dragDirection = _DragDirection.vertical;
          if (_isDraggingLeft) {
            _startBrightness = _brightness;
            setState(() {
              _isAdjustingBrightness = true;
              _showBrightnessIndicator = true;
            });
          } else {
            _startVolume = _volume;
            setState(() {
              _isAdjustingVolume = true;
              _showVolumeIndicator = true;
            });
          }
        }
      }
    }

    if (_dragDirection == _DragDirection.horizontal &&
        _isSeeking &&
        _duration.inSeconds > 0) {
      final screenWidth = MediaQuery.of(context).size.width;
      final dragProgress = details.delta.dx / screenWidth;
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
    } else if (_dragDirection == _DragDirection.vertical) {
      final screenHeight = MediaQuery.of(context).size.height;
      final dragDistance = _dragStartY - details.globalPosition.dy;

      if (_isAdjustingBrightness) {
        final brightnessChange = dragDistance / screenHeight * 2;
        final newBrightness = (_startBrightness + brightnessChange).clamp(
          0.0,
          1.0,
        );
        setState(() {
          _brightness = newBrightness;
        });
        ScreenBrightness().setScreenBrightness(newBrightness);
      } else if (_isAdjustingVolume) {
        final volumeChange = dragDistance / screenHeight * 2;
        final newVolume = (_startVolume + volumeChange).clamp(0.0, 1.0);
        setState(() {
          _volume = newVolume;
        });
        VolumeController.instance.setVolume(newVolume);
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragDirection == _DragDirection.horizontal && _isSeeking) {
      widget.player.seek(_seekPosition);
      setState(() {
        _isSeeking = false;
        _position = _seekPosition;
      });
    } else if (_dragDirection == _DragDirection.vertical) {
      if (_isAdjustingBrightness) {
        setState(() {
          _isAdjustingBrightness = false;
        });
        _brightnessIndicatorTimer?.cancel();
        _brightnessIndicatorTimer = Timer(
          const Duration(milliseconds: 800),
          () {
            if (mounted) {
              setState(() {
                _showBrightnessIndicator = false;
              });
            }
          },
        );
      } else if (_isAdjustingVolume) {
        setState(() {
          _isAdjustingVolume = false;
        });
        _volumeIndicatorTimer?.cancel();
        _volumeIndicatorTimer = Timer(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _showVolumeIndicator = false;
            });
          }
        });
      }
    }

    _dragDirection = _DragDirection.none;
  }

  void _onBrightnessDragStart(DragStartDetails details) {
    _dragStartY = details.globalPosition.dy;
    _startBrightness = _brightness;
    setState(() {
      _isAdjustingBrightness = true;
      _showBrightnessIndicator = true;
    });
  }

  void _onBrightnessDragUpdate(DragUpdateDetails details) {
    if (_isAdjustingBrightness) {
      final screenHeight = MediaQuery.of(context).size.height;
      final dragDistance = _dragStartY - details.globalPosition.dy;
      final brightnessChange = dragDistance / screenHeight * 2;
      final newBrightness = (_startBrightness + brightnessChange).clamp(
        0.0,
        1.0,
      );

      setState(() {
        _brightness = newBrightness;
      });

      ScreenBrightness().setScreenBrightness(newBrightness);
    }
  }

  void _onBrightnessDragEnd(DragEndDetails details) {
    setState(() {
      _isAdjustingBrightness = false;
    });
    _brightnessIndicatorTimer?.cancel();
    _brightnessIndicatorTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showBrightnessIndicator = false;
        });
      }
    });
  }

  void _onVolumeDragStart(DragStartDetails details) {
    _dragStartY = details.globalPosition.dy;
    _startVolume = _volume;
    setState(() {
      _isAdjustingVolume = true;
      _showVolumeIndicator = true;
    });
  }

  void _onVolumeDragUpdate(DragUpdateDetails details) {
    if (_isAdjustingVolume) {
      final screenHeight = MediaQuery.of(context).size.height;
      final dragDistance = _dragStartY - details.globalPosition.dy;
      final volumeChange = dragDistance / screenHeight * 2;
      final newVolume = (_startVolume + volumeChange).clamp(0.0, 1.0);

      setState(() {
        _volume = newVolume;
      });

      VolumeController.instance.setVolume(newVolume);
    }
  }

  void _onVolumeDragEnd(DragEndDetails details) {
    setState(() {
      _isAdjustingVolume = false;
    });
    _volumeIndicatorTimer?.cancel();
    _volumeIndicatorTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showVolumeIndicator = false;
        });
      }
    });
  }

  void _showSpeedSelectionDialog() {
    setState(() {
      _showSpeedDialog = true;
    });
  }

  void _setPlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
      _showSpeedDialog = false;
    });
    widget.player.setRate(speed);
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
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
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
              if (_showBrightnessIndicator) _buildBrightnessIndicator(),
              if (_showVolumeIndicator) _buildVolumeIndicator(),
              if (_showSpeedDialog) _buildSpeedDialog(),
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
        child: _isBuffering && !_isSeeking && !_isLongPressSeeking
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
          GestureDetector(
            onTap: () {
              if (!_showControls) {
                _showControlsHandel();
                return;
              }
              _showSpeedSelectionDialog();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                '${_playbackSpeed}x',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
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
              _isLongPressSeeking
                  ? Icons.speed
                  : (_seekProgress > 0
                        ? Icons.fast_forward
                        : Icons.fast_rewind),
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              _isLongPressSeeking ? '2x' : '${_seekSeconds}s',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrightnessIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.brightness_6, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              '${(_brightness * 100).toInt()}%',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                value: _brightness,
                backgroundColor: Colors.grey,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _volume == 0
                  ? Icons.volume_off
                  : (_volume < 0.5 ? Icons.volume_down : Icons.volume_up),
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              '${(_volume * 100).toInt()}%',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                value: _volume,
                backgroundColor: Colors.grey,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedDialog() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showSpeedDialog = false;
        });
      },
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '播放速度',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _speedOptions.map((speed) {
                    final isSelected = speed == _playbackSpeed;
                    return GestureDetector(
                      onTap: () => _setPlaybackSpeed(speed),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.red : Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${speed}x',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showSpeedDialog = false;
                    });
                  },
                  child: const Text(
                    '取消',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
