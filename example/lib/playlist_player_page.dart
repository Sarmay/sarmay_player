import 'package:flutter/material.dart';
import 'package:sarmay_player/sarmay_player.dart';

class PlaylistPlayerPage extends StatefulWidget {
  const PlaylistPlayerPage({super.key});

  @override
  State<PlaylistPlayerPage> createState() => _PlaylistPlayerPageState();
}

class _PlaylistPlayerPageState extends State<PlaylistPlayerPage> {
  late MediaPlayer player;
  bool _isDisposed = false;
  int _currentIndex = 0;

  final List<MediaUrl> playlist = [
    MediaUrl(
      url:
          'https://user-images.githubusercontent.com/28951144/229373695-22f88f13-d18f-4288-9bf1-c3e078d83722.mp4',
      title: '视频 1',
    ),
    MediaUrl(
      url:
          'https://user-images.githubusercontent.com/28951144/229373709-603a7a89-2105-4e1b-a5a5-a6c3567c9a59.mp4',
      title: '视频 2',
    ),
    MediaUrl(
      url:
          'https://user-images.githubusercontent.com/28951144/229373716-76da0a4e-225a-44e4-9ee7-3e9006dbc3e3.mp4',
      title: '视频 3',
    ),
    MediaUrl(
      url:
          'https://user-images.githubusercontent.com/28951144/229373718-86ce5e1d-d195-45d5-baa6-ef94041d0b90.mp4',
      title: '视频 4',
    ),
    MediaUrl(
      url:
          'https://user-images.githubusercontent.com/28951144/229373720-14d69157-1a56-4a78-a2f4-d7a134d7c3e9.mp4',
      title: '视频 5',
    ),
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('=== PlaylistPlayerPage initState ===');

    player = MediaPlayer(
      playerConfig: const PlayerConfiguration(),
      controllerConfig: const VideoControllerConfiguration(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPlayer();
    });
  }

  void _initPlayer() {
    if (_isDisposed) return;
    player.open(playlist[_currentIndex], play: true);
  }

  Future<MediaUrl?> _onPlayNext() async {
    debugPrint('=== 用户请求播放下一个视频 ===');
    
    if (_currentIndex < playlist.length - 1) {
      _currentIndex++;

      if(mounted){
        setState(() {

        });
      }
      final nextMedia = playlist[_currentIndex];
      
      debugPrint('下一个视频: ${nextMedia.title}');
      debugPrint('URL: ${nextMedia.url}');
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      return nextMedia;
    } else {
      debugPrint('已经是最后一个视频了');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已经是最后一个视频了')),
        );
      }
      return null;
    }
  }

  @override
  void dispose() {
    debugPrint('=== PlaylistPlayerPage dispose ===');
    _isDisposed = true;
    player.dispose().then((_) {
      debugPrint('播放器资源释放完成');
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('播放列表示例')),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: SarmayPlayer(
              player: player,
              controller: player.videoController,
              onPlayNext: _onPlayNext,
              onCompleted: () {
                debugPrint("当前视频播放完成");
              },
              onInitialized: () {
                debugPrint("播放器初始化完成");
              },
              onError: (errMsg) {
                debugPrint("播放错误: $errMsg");
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('播放列表', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('共 ${playlist.length} 个视频'),
                  const SizedBox(height: 4),
                  Text('当前播放: 第 ${_currentIndex + 1} 个 - ${playlist[_currentIndex].title}'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '使用说明',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• 点击全屏按钮进入全屏模式\n'
                          '• 在全屏模式下右下角会显示"下一个"按钮\n'
                          '• 点击"下一个"按钮会触发 onPlayNext 回调\n'
                          '• 在回调中可以重新获取链接或处理授权\n'
                          '• 返回 MediaUrl 对象开始播放下一个视频\n'
                          '• 返回 null 表示没有下一个视频',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '播放列表内容',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...playlist.asMap().entries.map((entry) {
                    final index = entry.key;
                    final media = entry.value;
                    final isPlaying = index == _currentIndex;
                    return Card(
                      color: isPlaying ? Colors.blue.shade50 : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPlaying ? Colors.blue : null,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isPlaying ? Colors.white : null,
                            ),
                          ),
                        ),
                        title: Text(
                          media.title ?? '未命名',
                          style: TextStyle(
                            fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          media.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10),
                        ),
                        trailing: isPlaying ? const Icon(Icons.play_arrow, color: Colors.blue) : null,
                        onTap: () {
                          setState(() {
                            _currentIndex = index;
                          });
                          player.open(playlist[_currentIndex], play: true);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
