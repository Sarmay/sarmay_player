import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:sarmay_player/media_player.dart';

/// 全屏播放器页面，自动切换为横向模式
class FullScreenPlayer extends StatefulWidget {
  final MediaPlayer player;
  const FullScreenPlayer({super.key, required this.player});

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {
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

  @override
  void initState() {
    super.initState();
    _setLandscapeFullScreen();
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

  // @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 应用从后台回到前台时，重新设置方向
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

  // 设置为全屏横向模式
  void _setLandscapeFullScreen() {
    try {
      // 先隐藏状态栏和导航栏
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

      // 可选：隐藏状态栏（双重保险）
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    } catch (e) {
      if (kDebugMode) {
        print('设置全屏模式失败: $e');
      }
    }
  }

  // 取消为全屏横向模式
  void _restorePortraitMode() {
    try {
      if (Platform.isIOS) {
        SystemChrome.setPreferredOrientations([]);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
      // 显示状态栏和导航栏
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      // 可选：显示状态栏
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

  // 切换播放与暂停
  void _togglePlayPause() {
    widget.player.playOrPause();
  }

  Future<bool> _onWillPop() {
    _restorePortraitMode();
    Navigator.of(context).pop();
    return Future.value(true);
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
          onTap: _showControlsHandel,
          child: Stack(
            children: [
              // 视频播放器
              Positioned.fill(
                child: Video(controller: widget.player.videoController),
              ),
              // 自定义控制按钮
              _customControl(),
              //
              if (_showTip) _backIconWidget(),
            ],
          ),
        ),
      ),
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

  Widget _customControl() {
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
            // 顶部控制栏
            Container(
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
            ),

            // 中间播放控制
            Expanded(
              child: Center(
                child: _isBuffering
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 快退
                          IconButton(
                            icon: const Icon(
                              Icons.replay_10,
                              color: Colors.white,
                              size: 40,
                            ),
                            onPressed: () {
                              if (!_showControls) {
                                _showControlsHandel();
                                return;
                              }
                              widget.player.seekBackward();
                            },
                          ),

                          // 播放/暂停
                          IconButton(
                            icon: Icon(
                              _isPlaying
                                  ? Icons.pause
                                  : Icons.play_circle_filled,
                              color: Colors.white,
                              size: 80,
                            ),
                            onPressed: () {
                              if (!_showControls) {
                                _showControlsHandel();
                                return;
                              }
                              _togglePlayPause();
                            },
                          ),

                          // 快进
                          IconButton(
                            icon: const Icon(
                              Icons.forward_10,
                              color: Colors.white,
                              size: 40,
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

            // 底部进度条
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    _formatDuration(_position),
                    style: const TextStyle(color: Colors.white),
                  ),
                  // 进度条
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
                    icon: const Icon(
                      Icons.fullscreen_exit,
                      color: Colors.white,
                    ),
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
            ),
          ],
        ),
      ),
    );
  }
}
