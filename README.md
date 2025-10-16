# sarmay_player

A new Flutter plugin project.

## Getting Started

```dart
import 'package:flutter/material.dart';
import 'package:sarmay_player/sarmay_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Necessary initialization for package:media_kit.
  ensurePlayerInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // 将MediaPlayerManager放在顶层，以便在整个应用中访问
      home: PlayerScreen(),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  List<MediaUrl> sampleList = [];

  late MediaUrl curPlay;
  int curIndex = 0;

  final MediaPlayer player = MediaPlayer(
    playerConfig: const PlayerConfiguration(),
    controllerConfig: const VideoControllerConfiguration(),
  );

  @override
  void initState() {
    sampleList = [
      MediaUrl(
        title: "Aliyun",
        url: "http://player.alicdn.com/video/aliyunmedia.mp4",
        // tipTime: Duration(seconds: 30),
        // tipWidget: InkWell(
        //   onTap: () {
        //     print("点击了呀");
        //     player.closeTip();
        //   },
        //   child: Container(color: Colors.white, child: Text("测试")),
        // ),
        // castWidget: Text("请先付费吧"),
        // castDevicesType: DevicesType.all,
      ),
      MediaUrl(
        title: "m3u8",
        url: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
        castDevicesType: DevicesType.renderer,
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
        title: "Protocol not found",
        url: "noprotocol://assets/butterfly.mp4",
      ),
    ];
    curPlay = sampleList[curIndex];
    // 初始化时预加载第一个视频
    super.initState();
    player.setUrlAndSeek(curPlay, Duration(seconds: 56), play: false);
  }

  @override
  void dispose() async {
    await player.dispose();
    super.dispose();
  }

  void playPrevious() {
    setState(() {
      curIndex = (curIndex - 1) % sampleList.length;
      if (curIndex < 0) curIndex = sampleList.length - 1;
      curPlay = sampleList[curIndex];
    });
    // player.open(curPlay, play: true);
    player.setUrlAndSeek(curPlay, Duration(seconds: 30), play: true);
  }

  void playNext() async {
    await player.stopAndInit();
    setState(() {
      curIndex = (curIndex + 1) % sampleList.length;
      curPlay = sampleList[curIndex];
    });
    Future.delayed(Duration(seconds: 10), () {
      // player.open(curPlay, play: true);
      player.setUrlAndSeek(curPlay, Duration(seconds: 30), play: true);
    });
  }

  void playAtIndex(int index) {
    if (index >= 0 && index < sampleList.length) {
      setState(() {
        curIndex = index;
        curPlay = sampleList[curIndex];
      });
      // player.open(curPlay, play: true);
      player.setUrlAndSeek(curPlay, Duration(seconds: 30), play: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sarmay测试视频投屏和播放器')),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              SarmayPlayer(
                player: player,
                controller: player.videoController,
                onCompleted: (bool completed) {
                  print("主页面completed：$completed");
                  if (completed) {
                    playNext();
                  }
                },
                onInitialized: (bool initialized) {
                  print("主页面initialized：$initialized");
                  if (initialized) {
                    // player.seek(Duration(seconds: 56));
                  }
                },
                onError: (String errMsg) {
                  print("主页面errMsg：$errMsg");
                },
              ),
              const SizedBox(height: 16),
              // 显示当前播放的视频标题
              InkWell(
                onTap: () {
                  player.seek(Duration(seconds: 56));
                },
                child: Text(
                  "当前播放: ${curPlay.title ?? '未命名视频'}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 控制按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MaterialButton(
                    color: Colors.blue,
                    onPressed: playPrevious,
                    child: const Text(
                      "上一个",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  MaterialButton(
                    color: Colors.red,
                    onPressed: playNext,
                    child: const Text(
                      "下一个",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 视频列表选择器
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: sampleList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final mediaUrl = entry.value;
                    return ListTile(
                      title: Text(mediaUrl.title ?? '未命名视频'),
                      subtitle: Text(
                        mediaUrl.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      tileColor: index == curIndex
                          ? Colors.blue.shade100
                          : null,
                      onTap: () => playAtIndex(index),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

