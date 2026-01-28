import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:sarmay_player/other_data.dart';

export 'package:media_kit/media_kit.dart' show PlayerConfiguration;
export 'package:media_kit_video/media_kit_video.dart'
    show VideoControllerConfiguration;

export 'package:sarmay_player/other_data.dart';

class MediaPlayer {
  final Player _player;
  late final VideoController _videoController;
  MediaUrl _mediaUrl = MediaUrl(url: '');
  bool _isDisposed = false;
  bool _isInitialized = false;
  bool _playing = false;
  bool _isBuffering = false;
  bool _showTip = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration? _tipTime;
  Widget? _tipWidget;
  Widget? _castWidget;
  DevicesType _castDevicesType = DevicesType.all;
  Duration? _seekPosition;

  // 自定义初始化状态流
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  final StreamController<bool> _initializedController =
      StreamController<bool>.broadcast();

  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();

  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();

  final StreamController<bool> _playingController =
      StreamController<bool>.broadcast();

  final StreamController<bool> _bufferingController =
      StreamController<bool>.broadcast();

  final StreamController<bool> _showTipController =
      StreamController<bool>.broadcast();

  MediaPlayer({
    PlayerConfiguration playerConfig = const PlayerConfiguration(),
    VideoControllerConfiguration controllerConfig =
        const VideoControllerConfiguration(),
  }) : _player = Player(configuration: playerConfig) {
    _videoController = VideoController(
      _player,
      configuration: controllerConfig,
    );
    _setupStreams();
  }

  void _setupStreams() {
    try {
      _positionController.onListen = () {
        try {
          if (!_positionController.isClosed && !_isDisposed) {
            _positionController.add(_position);
          }
        } catch (e) {
          if (kDebugMode) {
            print("positionController onListen error: $e");
          }
        }
      };

      _durationController.onListen = () {
        try {
          if (!_durationController.isClosed && !_isDisposed) {
            _durationController.add(_duration);
          }
        } catch (e) {
          if (kDebugMode) {
            print("durationController onListen error: $e");
          }
        }
      };

      _playingController.onListen = () {
        try {
          if (!_playingController.isClosed && !_isDisposed) {
            _playingController.add(_playing);
          }
        } catch (e) {
          if (kDebugMode) {
            print("playingController onListen error: $e");
          }
        }
      };

      _bufferingController.onListen = () {
        try {
          if (!_bufferingController.isClosed && !_isDisposed) {
            _bufferingController.add(_isBuffering);
          }
        } catch (e) {
          if (kDebugMode) {
            print("bufferingController onListen error: $e");
          }
        }
      };

      _showTipController.onListen = () {
        try {
          if (!_showTipController.isClosed && !_isDisposed) {
            _showTipController.add(_showTip);
          }
        } catch (e) {
          if (kDebugMode) {
            print("showTipController onListen error: $e");
          }
        }
      };

      _player.stream.position.listen((Duration position) {
        try {
          if (_isDisposed) {
            return;
          }
          _position = position;
          if (_seekPosition != null) {
            final seekPos = _seekPosition!;
            _seekPosition = null;
            _player.seek(seekPos);
          }
          if (!_positionController.isClosed && !_isDisposed) {
            _positionController.add(position);
          }
          if (_tipTime != null) {
            if (position >= _tipTime!) {
              _showTip = true;
              _player.pause();
              if (!_showTipController.isClosed && !_isDisposed) {
                _showTipController.add(true);
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print("position stream error: $e");
          }
        }
      });

      _player.stream.playing.listen((bool playing) {
        try {
          if (_isDisposed) {
            return;
          }
          _playing = playing;
          if (!_playingController.isClosed && !_isDisposed) {
            _playingController.add(playing);
          }
          if (!_durationController.isClosed && !_isDisposed) {
            _durationController.add(_duration);
          }
        } catch (e) {
          if (kDebugMode) {
            print("playing stream error: $e");
          }
        }
      });

      _player.stream.buffering.listen((bool buffering) {
        try {
          if (_isDisposed) {
            return;
          }
          _isBuffering = buffering;
          if (!_bufferingController.isClosed && !_isDisposed) {
            _bufferingController.add(buffering);
          }
          if (!_playingController.isClosed && !_isDisposed) {
            _playingController.add(!buffering);
          }
          if (!_durationController.isClosed && !_isDisposed) {
            _durationController.add(_duration);
          }
        } catch (e) {
          if (kDebugMode) {
            print("buffering stream error: $e");
          }
        }
      });

      _player.stream.error.listen((String error) {
        try {
          if (_isDisposed) {
            return;
          }
          if (kDebugMode) {
            print("play error: $error");
          }
          if (!_errorController.isClosed && !_isDisposed) {
            _errorController.add(error);
          }
        } catch (e) {
          if (kDebugMode) {
            print("error stream error: $e");
          }
        }
      });

      _player.stream.duration.listen((Duration duration) {
        try {
          if (_isDisposed) {
            return;
          }
          _duration = duration;
          if (!_durationController.isClosed && !_isDisposed) {
            _durationController.add(duration);
          }
          bool calcInitialized = duration.inMicroseconds > 0;
          if (!_initializedController.isClosed &&
              !_isDisposed &&
              _isInitialized != calcInitialized) {
            _isInitialized = calcInitialized;
            _initializedController.add(_isInitialized);
          }
        } catch (e) {
          if (kDebugMode) {
            print("duration stream error: $e");
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print("setup streams error: $e");
      }
    }
  }

  // VideoController 访问器
  VideoController get videoController => _videoController;

  // 重写打开
  Future<void> open(MediaUrl mediaUrl, {bool play = true}) {
    _checkDisposed();
    try {
      _playing = play;
      _mediaUrl = mediaUrl;
      _isInitialized = false;
      _showTip = false;
      if (!_initializedController.isClosed && !_isDisposed) {
        _initializedController.add(false);
      }
      if (!_showTipController.isClosed && !_isDisposed) {
        _showTipController.add(false);
      }
      _player.stop();
      _tipTime = mediaUrl.tipTime;
      _tipWidget = mediaUrl.tipWidget;
      _castWidget = mediaUrl.castWidget;
      _castDevicesType = mediaUrl.castDevicesType;
      return _player.open(Media(mediaUrl.url), play: play);
    } catch (e) {
      if (!_errorController.isClosed && !_isDisposed) {
        _errorController.add(e.toString());
      }
      return Future.value();
    }
  }

  Future<void> setUrl(MediaUrl mediaUrl, {bool play = true}) {
    _checkDisposed();
    try {
      _playing = play;
      _mediaUrl = mediaUrl;
      _tipTime = mediaUrl.tipTime;
      _tipWidget = mediaUrl.tipWidget;
      _castWidget = mediaUrl.castWidget;
      _castDevicesType = mediaUrl.castDevicesType;
      return _player.open(Media(mediaUrl.url), play: play);
    } catch (e) {
      _errorController.add(e.toString());
      return Future.value();
    }
  }

  Future<void> setUrlAndSeek(
    MediaUrl mediaUrl,
    Duration position, {
    bool play = true,
  }) async {
    await setUrl(mediaUrl, play: play);
    _position = position;
    _seekPosition = position;
    return;
  }

  Future<void> play() {
    _checkDisposed();
    return _player.play();
  }

  Future<void> pause() {
    _checkDisposed();
    return _player.pause();
  }

  Future<void> setRate(double rate) {
    _checkDisposed();
    return _player.setRate(rate);
  }

  Future<void> stop() {
    _checkDisposed();
    _mediaUrl = MediaUrl(url: '');
    _isInitialized = false;
    _initializedController.add(false);
    return _player.stop();
  }

  Future<void> seek(Duration position) {
    _checkDisposed();
    if (_playing) {
      _isBuffering = true;
      if (!_bufferingController.isClosed && !_isDisposed) {
        _bufferingController.add(_isBuffering);
      }
    }
    return _player.seek(position);
  }

  Future<void> playOrPause() {
    _checkDisposed();
    return _player.playOrPause();
  }

  void seekForward() {
    _checkDisposed();
    final newPosition = _position + const Duration(seconds: 10);
    if (newPosition <= _duration) {
      _player.seek(newPosition);
    } else {
      _player.seek(_duration);
    }
  }

  void seekBackward() {
    _checkDisposed();
    final newPosition = _position - const Duration(seconds: 10);
    if (newPosition >= Duration.zero) {
      _player.seek(newPosition);
    } else {
      _player.seek(Duration.zero);
    }
  }

  void setDevicesType(DevicesType devicesType) {
    _checkDisposed();
    _castDevicesType = devicesType;
  }

  // 流数据
  Stream<Playlist> get playlist {
    _checkDisposed();
    return _player.stream.playlist;
  }

  Stream<bool> get completed {
    _checkDisposed();
    return _player.stream.completed;
  }

  Stream<Duration> get position {
    _checkDisposed();
    return _positionController.stream;
  }

  Stream<Duration> get duration {
    _checkDisposed();
    return _durationController.stream;
  }

  Stream<bool> get playing {
    _checkDisposed();
    return _playingController.stream;
  }

  Stream<bool> get buffering {
    _checkDisposed();
    return _bufferingController.stream;
  }

  Stream<String> get error {
    _checkDisposed();
    return _errorController.stream;
  }

  // 监听初始化
  Stream<bool> get initialized {
    _checkDisposed();
    return _initializedController.stream;
  }

  Stream<bool> get show {
    _checkDisposed();
    return _showTipController.stream;
  }

  MediaUrl get mediaUrl {
    _checkDisposed();
    return _mediaUrl;
  }

  Duration? get tipTime {
    _checkDisposed();
    return _tipTime;
  }

  Widget? get tipWidget {
    _checkDisposed();
    return _tipWidget;
  }

  Widget? get castWidget {
    _checkDisposed();
    return _castWidget;
  }

  DevicesType get castDevicesType {
    _checkDisposed();
    return _castDevicesType;
  }

  bool get showTip {
    _checkDisposed();
    return _showTip;
  }

  Duration get videoDuration {
    _checkDisposed();
    return _duration;
  }

  Duration get videoPosition {
    _checkDisposed();
    return _position;
  }

  bool get videoIsBuffering {
    _checkDisposed();
    return _isBuffering;
  }

  bool get videoIsPlaying {
    _checkDisposed();
    return _playing;
  }

  bool get videoIsInitialized {
    _checkDisposed();
    return _isInitialized;
  }

  bool get videoIsDisposed {
    _checkDisposed();
    return _isDisposed;
  }

  // 停止并初始化
  Future<void> stopAndInit() async {
    try {
      _checkDisposed();
      _playing = false;
      _mediaUrl = MediaUrl(url: '');
      _isInitialized = false;
      _showTip = false;
      if (!_initializedController.isClosed && !_isDisposed) {
        _initializedController.add(false);
      }
      if (!_showTipController.isClosed && !_isDisposed) {
        _showTipController.add(false);
      }
      _tipTime = null;
      _tipWidget = null;
      _castWidget = null;
      _castDevicesType = DevicesType.all;
      return await _player.stop();
    } catch (e) {
      if (!_errorController.isClosed && !_isDisposed) {
        _errorController.add(e.toString());
      }
      return Future.value();
    }
  }

  // 关闭
  Future<void> closeTip() {
    _checkDisposed();
    if (_showTip) {
      _showTip = false;
      _tipTime = null;
      _tipWidget = null;
      _castWidget = null;
      if (!_showTipController.isClosed && !_isDisposed) {
        _showTipController.add(false);
      }
      return _player.play();
    }
    return Future.value();
  }

  Future<void> jumpForward({int seconds = 10}) async {
    _checkDisposed();
    final current = await _player.stream.position.first;
    await seek(current + Duration(seconds: seconds));
  }

  Future<void> jumpBackward({int seconds = 10}) async {
    _checkDisposed();
    final current = await _player.stream.position.first;
    final newPosition = current - Duration(seconds: seconds);
    await seek(newPosition > Duration.zero ? newPosition : Duration.zero);
  }

  Future<void> dispose() async {
    // 先标记为已释放，防止回调中继续操作
    _isDisposed = true;
    await _bufferingController.close();
    await _playingController.close();
    await _positionController.close();
    await _durationController.close();
    await _errorController.close();
    await _initializedController.close();
    await _showTipController.close();

    if (!_isDisposed) {
      await _player.dispose();
    }
  }

  void _checkDisposed() {
    if (_isDisposed) {
      throw StateError('MediaPlayer has been disposed');
    }
  }
}

class MediaUrl {
  const MediaUrl({
    required this.url,
    this.title,
    this.tipTime,
    this.tipWidget,
    this.castWidget,
    this.castDevicesType = DevicesType.all,
  });

  final String? title;
  final String url;
  final Duration? tipTime;
  final Widget? tipWidget;
  final Widget? castWidget;
  final DevicesType castDevicesType;

  MediaUrl.fromJson(Map<String, dynamic> json)
    : title = json['title'],
      url = json['url'],
      tipTime = json['tipTime'] is int
          ? Duration(seconds: json['tipTime'])
          : json['tipTime'],
      tipWidget = json['tipWidget'],
      castWidget = json['castWidget'],
      castDevicesType = json['castDevicesType'] is String
          ? DevicesType.values.firstWhere(
              (e) => e.toString() == json['castDevicesType'],
              orElse: () => DevicesType.all,
            )
          : json['castDevicesType'] ?? DevicesType.all;

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'tipTime': tipTime,
    'tipWidget': tipWidget,
    'castWidget': castWidget,
    'castDevicesType': castDevicesType,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaUrl &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          url == other.url;

  @override
  int get hashCode => title.hashCode ^ url.hashCode;
}
