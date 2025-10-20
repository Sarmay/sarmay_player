import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sarmay_player/cast_device_dialog.dart';
import 'package:sarmay_player/full_screen_player.dart';
import 'package:sarmay_player/media_player.dart';

class CustomVideoControls extends StatefulWidget {
  final MediaPlayer player;
  const CustomVideoControls({super.key, required this.player});

  @override
  State<CustomVideoControls> createState() => _CustomVideoControlsState();
}

class _CustomVideoControlsState extends State<CustomVideoControls> {
  bool _showControls = false;
  Timer? _hideControlsTimer;
  OverlayEntry? _castOverlayEntry;

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

  @override
  void initState() {
    super.initState();
    setupStreams();
    _showControlsHandel();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _playingSubscription.cancel();
    _durationSubscription.cancel();
    _positionSubscription.cancel();
    _bufferingSubscription.cancel();
    _showTipSubscription.cancel();
    super.dispose();
  }

  void setupStreams() {
    _durationSubscription = widget.player.duration.listen((Duration duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });
    _positionSubscription = widget.player.position.listen((Duration position) {
      if (mounted) {
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

  // 其他
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  // 进入全屏
  void _fullscreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenPlayer(player: widget.player),
      ),
    );
  }

  // 显示控制器
  void _showControlsHandel() {
    // 取消之前的计时器（防止多次调用）
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
        // 3秒后隐藏控制栏
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

  @override
  Widget build(BuildContext context) {
    if (_showTip) {
      Widget tipWidget =
          widget.player.tipWidget ??
          Container(
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
    return GestureDetector(
      onTap: _showControlsHandel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
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
              // Top controls
              Container(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (Platform.isIOS)
                      SizedBox(height: 24)
                    else
                      IconButton(
                        padding: EdgeInsetsGeometry.zero,
                        icon: const Icon(
                          Icons.cast_connected,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (!_showControls) {
                            _showControlsHandel();
                            return;
                          }
                          _showCastDialog(context);
                        },
                      ),
                  ],
                ),
              ),

              // Center play controls
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Seek backward
                      IconButton(
                        padding: EdgeInsetsGeometry.zero,
                        icon: const Icon(
                          Icons.replay_10,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () {
                          if (!_showControls) {
                            _showControlsHandel();
                            return;
                          }
                          widget.player.seekBackward();
                        },
                      ),

                      // Play/Pause
                      _middleButton(),

                      // Seek forward
                      IconButton(
                        padding: EdgeInsetsGeometry.zero,
                        icon: const Icon(
                          Icons.forward_10,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () {
                          if (!_showControls) {
                            _showControlsHandel();
                            return;
                          }
                          widget.player.seekForward();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom progress bar
              Container(
                padding: const EdgeInsets.only(right: 8, left: 8),
                child: Row(
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: const TextStyle(color: Colors.white),
                    ),
                    // Progress bar
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                          activeTrackColor: Colors.red,
                          inactiveTrackColor: Colors.grey,
                          thumbColor: Colors.red,
                        ),
                        child: Slider(
                          value: _duration.inSeconds > 0
                              ? _position.inSeconds.toDouble()
                              : 0.0,
                          min: 0,
                          max: _duration.inSeconds > 0
                              ? _duration.inSeconds.toDouble()
                              : 1.0,
                          onChanged: (value) {
                            if (!_showControls) {
                              _showControlsHandel();
                              return;
                            }
                            if (_duration.inSeconds > 0) {
                              widget.player.seek(
                                Duration(seconds: value.toInt()),
                              );
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
                      padding: EdgeInsetsGeometry.zero,
                      icon: const Icon(Icons.fullscreen, color: Colors.white),
                      onPressed: () {
                        if (!_showControls) {
                          _showControlsHandel();
                          return;
                        }
                        _fullscreen();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 中间按钮
  Widget _middleButton() {
    if (_isBuffering) {
      return SizedBox(
        width: 60,
        height: 60,
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return IconButton(
      padding: EdgeInsetsGeometry.zero,
      icon: Icon(
        _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
        color: Colors.white,
        size: 60,
      ),
      onPressed: () {
        if (!_showControls) {
          _showControlsHandel();
          return;
        }
        widget.player.playOrPause();
      },
    );
  }

  // 显示投屏设备选择
  void _showCastDialog(BuildContext context) {
    // 先暂停播放
    bool isPlaying = _isPlaying;
    if (isPlaying) {
      widget.player.pause();
    }
    _castOverlayEntry = OverlayEntry(
      builder: (context) => CastDeviceDialog(
        playUrl: widget.player.mediaUrl.url,
        tipTime: widget.player.tipTime,
        castWidget: widget.player.castWidget,
        devicesType: widget.player.castDevicesType,
        onClose: () {
          _castOverlayEntry?.remove();
          _castOverlayEntry = null;
          if (isPlaying) {
            widget.player.play();
          }
        },
      ),
    );
    Overlay.of(context).insert(_castOverlayEntry!);
  }
}
