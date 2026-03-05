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
    player.openPlaylist(playlist, startIndex: 0, play: true);
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
                  Text('当前播放: 第 ${player.currentPlaylistIndex + 1} 个'),
                  const SizedBox(height: 16),
                  const Text(
                    '提示: 点击全屏按钮进入全屏模式，在全屏模式下右下角会显示"下一个"按钮（仅在播放列表模式下显示）',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(media.title ?? '未命名'),
                        subtitle: Text(
                          media.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10),
                        ),
                        onTap: () {
                          player.openPlaylist(playlist, startIndex: index, play: true);
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
