import 'package:flutter/material.dart';
import 'package:sarmay_player/sarmay_player.dart';
import 'player_detail_page.dart';
import 'playlist_player_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ensurePlayerInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const VideoListPage(),
    );
  }
}

class VideoListPage extends StatefulWidget {
  const VideoListPage({super.key});

  @override
  State<VideoListPage> createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  final List<MediaUrl> _videoList = [];

  @override
  void initState() {
    super.initState();
    _videoList.addAll([
      MediaUrl(
        title: "Aliyun",
        url: "http://player.alicdn.com/video/aliyunmedia.mp4",
        play: true,
        tipTime: Duration(seconds: 50)
      ),
      MediaUrl(
        title: "m3u8",
        url: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
        castDevicesType: DevicesType.renderer,
        play: true,
      ),
      MediaUrl(
        title: "Sample Video 360 * 240",
        url:
            "https://sample-videos.com/video123/flv/240/big_buck_bunny_240p_10mb.flv",
      ),
      MediaUrl(
        title: "bipbop basic master playlist",
        url:
            "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8",
      ),
      MediaUrl(
        title: "bipbop basic 400x300 @ 232 kbps",
        url:
            "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/gear1/prog_index.m3u8",
      ),
      MediaUrl(
        title: "bipbop basic 640x480 @ 650 kbps",
        url:
            "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/gear2/prog_index.m3u8",
      ),
      MediaUrl(
        title: "bipbop basic 640x480 @ 1 Mbps",
        url:
            "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/gear3/prog_index.m3u8",
      ),
      MediaUrl(
        title: "bipbop basic 960x720 @ 2 Mbps",
        url:
            "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/gear4/prog_index.m3u8",
      ),
      MediaUrl(
        title: "bipbop basic 22.050Hz stereo @ 40 kbps",
        url:
            "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/gear0/prog_index.m3u8",
      ),
      MediaUrl(
        title: "bipbop advanced master playlist",
        url:
            "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8",
      ),
      MediaUrl(
        title: "bipbop advanced 416x234 @ 265 kbps",
        url:
            "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/gear1/prog_index.m3u8",
      ),
      MediaUrl(
        title: "bipbop advanced 640x360 @ 580 kbps",
        url:
            "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/gear2/prog_index.m3u8",
      ),
      MediaUrl(
        title: "bipbop advanced 960x540 @ 910 kbps",
        url:
            "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/gear3/prog_index.m3u8",
      ),
      MediaUrl(
        title: "bipbop advanced 1280x720 @ 1 Mbps",
        url:
            "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/gear4/prog_index.m3u8",
      ),
      MediaUrl(
        title: "bipbop advanced 1920x1080 @ 2 Mbps",
        url:
            "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/gear5/prog_index.m3u8",
      ),
      MediaUrl(
        title: "bipbop advanced 22.050Hz stereo @ 40 kbps",
        url:
            "http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/gear0/prog_index.m3u8",
      ),
      MediaUrl(
        title: "rtsp test",
        url: "rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mov",
      ),
      MediaUrl(
        title: "http 404",
        url: "https://fijkplayer.befovy.com/butterfly.flv",
      ),
      MediaUrl(title: "assets file", url: "asset:///assets/butterfly.mp4"),
      MediaUrl(title: "assets file", url: "asset:///assets/birthday.mp4"),
      MediaUrl(title: "assets file 404", url: "asset:///assets/beebee.mp4"),
      MediaUrl(
        title: "竖向短剧并且超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题超长标题",
        url: "https://cdn.wlcdn88.com:777/dfc69d3a/index.m3u8",
      ),
    ]);
  }

  void _navigateToPlayer(int index) {
    debugPrint('=== 导航到播放器页面 ===');
    debugPrint('视频索引: $index');
    debugPrint('视频标题: ${_videoList[index].title}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerDetailPage(
          mediaUrl: _videoList[index],
          index: index,
          totalCount: _videoList.length,
        ),
      ),
    ).then((_) {
      debugPrint('=== 从播放器页面返回 ===');
      debugPrint('检查是否有内存泄漏...');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sarmay播放器测试')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '测试说明',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• 点击视频列表项进入播放器页面\n'
                  '• 返回时会自动释放播放器资源\n'
                  '• 请查看控制台日志确认资源释放情况\n'
                  '• 多次进出页面测试内存泄漏',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlaylistPlayerPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.playlist_play),
                  label: const Text('播放列表示例'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _videoList.length,
              itemBuilder: (context, index) {
                final video = _videoList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(
                      video.title ?? '未命名视频',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      video.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.play_circle_outline),
                    onTap: () => _navigateToPlayer(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
