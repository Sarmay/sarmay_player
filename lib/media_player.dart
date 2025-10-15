import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

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

  MediaPlayer({PlayerConfiguration configuration = const PlayerConfiguration()})
    : _player = Player(configuration: configuration) {
    _videoController = VideoController(_player);
    _setupStreams();
  }

  void _setupStreams() {
    _positionController.onListen = () {
      _positionController.add(_position);
    };

    _durationController.onListen = () {
      _durationController.add(_duration);
    };

    _playingController.onListen = () {
      _playingController.add(_playing);
    };

    _bufferingController.onListen = () {
      _bufferingController.add(_isBuffering);
    };

    _showTipController.onListen = () {
      _showTipController.add(_showTip);
    };

    _player.stream.position.listen((Duration position) {
      _position = position;
      if (!_positionController.isClosed) {
        _positionController.add(position);
      }
      if (_tipTime != null) {
        if (position >= _tipTime!) {
          _showTip = true;
          _player.pause();
          _showTipController.add(true);
        }
      }
    });

    _player.stream.playing.listen((bool playing) {
      _playing = playing;
      if (!_playingController.isClosed) {
        _playingController.add(playing);
      }
      if (!_durationController.isClosed) {
        _durationController.add(_duration);
      }
    });

    _player.stream.buffering.listen((bool buffering) {
      _isBuffering = buffering;
      if (!_bufferingController.isClosed) {
        _bufferingController.add(buffering);
      }
      if (!_playingController.isClosed) {
        _playingController.add(!buffering);
      }
      if (!_durationController.isClosed) {
        _durationController.add(_duration);
      }
    });

    _player.stream.error.listen((String error) {
      print("play error: $error");
      if (!_errorController.isClosed) {
        _errorController.add(error);
      }
    });

    _player.stream.duration.listen((Duration duration) {
      _duration = duration;
      if (!_durationController.isClosed) {
        _durationController.add(duration);
      }
      bool calcInitialized = duration.inMicroseconds > 0;
      if (!_initializedController.isClosed &&
          _isInitialized != calcInitialized) {
        _isInitialized = calcInitialized;
        _initializedController.add(_isInitialized);
      }
    });
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
      _initializedController.add(false);
      _showTipController.add(false);
      _player.stop();
      _tipTime = mediaUrl.tipTime;
      _tipWidget = mediaUrl.tipWidget;
      return _player.open(Media(mediaUrl.url), play: play);
    } catch (e) {
      _errorController.add(e.toString());
      return Future.value();
    }
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
    _isInitialized = false;
    _initializedController.add(false);
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

  // 自定义功能
  Future<void> customSeek(Duration position) async {
    _checkDisposed();
    if (kDebugMode) {
      print('Custom seek to: $position');
    }
    await _player.seek(position);
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
    await _bufferingController.close();
    await _playingController.close();
    await _positionController.close();
    await _durationController.close();
    await _errorController.close();
    await _initializedController.close();

    if (!_isDisposed) {
      await _player.dispose();
      _isDisposed = true;
    }
  }

  void _checkDisposed() {
    if (_isDisposed) {
      throw StateError('MediaPlayer has been disposed');
    }
  }
}

class MediaUrl {
  const MediaUrl({required this.url, this.title, this.tipTime, this.tipWidget});

  final String? title;
  final String url;
  final Duration? tipTime;
  final Widget? tipWidget;

  MediaUrl.fromJson(Map<String, dynamic> json)
    : title = json['title'],
      url = json['url'],
      tipTime = json['tipTime'],
      tipWidget = json['tipWidget'];

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'tipTime': tipTime,
    'tipWidget': tipWidget,
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
