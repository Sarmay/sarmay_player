import 'package:flutter/material.dart';
import 'package:sarmay_player/sarmay_player.dart';

class PlayerDetailPage extends StatefulWidget {
  final MediaUrl mediaUrl;
  final int index;
  final int totalCount;

  const PlayerDetailPage({
    super.key,
    required this.mediaUrl,
    required this.index,
    required this.totalCount,
  });

  @override
  State<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends State<PlayerDetailPage> {
  late MediaPlayer player;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    debugPrint('=== PlayerDetailPage initState ===');
    debugPrint('播放视频: ${widget.mediaUrl.title}');
    debugPrint('视频索引: ${widget.index} / ${widget.totalCount}');

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
    player.setUrl(widget.mediaUrl, play: widget.mediaUrl.play);
  }

  @override
  void dispose() {
    debugPrint('=== PlayerDetailPage dispose ===');
    debugPrint('开始释放播放器资源: ${widget.mediaUrl.title}');
    _isDisposed = true;
    player.dispose().then((_) {
      debugPrint('播放器资源释放完成: ${widget.mediaUrl.title}');
    });
    super.dispose();
  }

  void _seekToTest() {
    player.seek(Duration(seconds: 56));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        debugPrint('=== 用户按下返回键 ===');
        return true;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(widget.mediaUrl.title ?? '视频播放'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              debugPrint('=== 点击返回按钮 ===');
              Navigator.pop(context);
            },
          ),
        ),
        body: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: SarmayPlayer(
                player: player,
                controller: player.videoController,
                onPosUpdate: (position) {
                  debugPrint('播放位置: ${position.inSeconds}秒');
                },
                posUpdateInterval: const Duration(seconds: 10),
                onCompleted: () {
                  debugPrint("播放完成");
                },
                onInitialized: () {
                  debugPrint("播放器初始化完成");
                  player.seek(Duration(seconds: 30));
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
                    Text('视频信息', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('标题: ${widget.mediaUrl.title ?? "未命名"}'),
                    const SizedBox(height: 4),
                    Text(
                      'URL: ${widget.mediaUrl.url}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text('索引: ${widget.index + 1} / ${widget.totalCount}'),
                    const SizedBox(height: 24),
                    Text('测试操作', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _seekToTest,
                          child: const Text('跳转到56秒'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            player.seek(Duration.zero);
                          },
                          child: const Text('回到开头'),
                        ),

                        ElevatedButton(
                          onPressed: () {
                            player.pause();
                            debugPrint('暂停');
                          },
                          child: const Text('暂停'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            player.play();
                            debugPrint('播放');
                          },
                          child: const Text('播放'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '提示: 返回上一页时会自动释放播放器资源，\n请查看控制台日志确认资源释放情况。',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
