import 'package:chewie/chewie.dart';
import 'package:chewie_example/app/theme.dart';
import 'package:chewie_example/segment_playback_manager.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ChewieDemo extends StatefulWidget {
  const ChewieDemo({super.key, this.title = 'Chewie Demo'});

  final String title;

  @override
  State<StatefulWidget> createState() {
    return _ChewieDemoState();
  }
}

class _ChewieDemoState extends State<ChewieDemo> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  SegmentPlaybackManager? _segmentManager;

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  @override
  void dispose() {
    _segmentManager?.dispose();
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  List<VideoSegmentConfig> videoConfigs = [
    VideoSegmentConfig(
      url:
          "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
      segments: [
        PlaybackSegment(
          start: const Duration(minutes: 1),
          end: const Duration(minutes: 2),
        ),
        PlaybackSegment(
          start: const Duration(minutes: 4),
          end: const Duration(minutes: 5),
        ),
      ],
    ),
    VideoSegmentConfig(
      url:
          "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
      segments: [
        PlaybackSegment(
          start: const Duration(minutes: 0, seconds: 30),
          end: const Duration(minutes: 1, seconds: 30),
        ),
        PlaybackSegment(
          start: const Duration(minutes: 2),
          end: const Duration(minutes: 3),
        ),
      ],
    ),
    VideoSegmentConfig(
      url:
          "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
      segments: [
        PlaybackSegment(
          start: const Duration(seconds: 10),
          end: const Duration(seconds: 40),
        ),
        PlaybackSegment(
          start: const Duration(minutes: 1, seconds: 30),
          end: const Duration(minutes: 2, seconds: 30),
        ),
      ],
    ),
  ];

  Future<void> initializePlayer() async {
    final currentConfig = videoConfigs[currPlayIndex];

    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(currentConfig.url),
    );
    await _videoPlayerController.initialize();
    _createChewieController();
    _setupSegmentManager();
    setState(() {});
  }

  void _createChewieController() {
    final currentConfig = videoConfigs[currPlayIndex];

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      zoomAndPan: true,
      looping: false, // Disable looping for segment playback

      startAt: currentConfig.segments.isNotEmpty
          ? currentConfig.segments[0].start
          : null,

      additionalOptions: (context) {
        return <OptionItem>[
          OptionItem(
            onTap: (context) => toggleVideo(),
            iconData: Icons.live_tv_sharp,
            title: 'Toggle Video Src',
          ),
        ];
      },

      hideControlsTimer: const Duration(seconds: 1),
    );
  }

  void _setupSegmentManager() {
    final currentConfig = videoConfigs[currPlayIndex];

    // 停止旧的管理器
    _segmentManager?.stop();

    // 创建新的管理器
    _segmentManager = SegmentPlaybackManager(
      videoController: _videoPlayerController,
      segments: currentConfig.segments,
      onAllSegmentsComplete: () {
        // 当当前视频的所有区间播放完毕时，切换到下一个视频
        toggleVideo();
      },
    );

    // 启动管理器
    _segmentManager!.start();
  }

  int currPlayIndex = 0;

  Future<void> toggleVideo() async {
    await _videoPlayerController.pause();
    currPlayIndex += 1;
    if (currPlayIndex >= videoConfigs.length) {
      currPlayIndex = 0;
    }
    await initializePlayer();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.title,
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child:
                    _chewieController != null &&
                        _chewieController!
                            .videoPlayerController
                            .value
                            .isInitialized
                    ? Chewie(controller: _chewieController!)
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 20),
                          Text('Loading'),
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
