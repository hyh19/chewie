import 'package:chewie/chewie.dart';
import 'package:chewie_example/app/theme.dart';
import 'package:chewie_example/segment_playback_manager.dart';
import 'package:chewie_example/video_playlist_widget.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ChewieDemo extends StatefulWidget {
  const ChewieDemo({super.key});

  @override
  State<StatefulWidget> createState() {
    return _ChewieDemoState();
  }
}

class _ChewieDemoState extends State<ChewieDemo> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  SegmentPlaybackManager? _segmentManager;
  VideoSegmentConfig? _currentPlayingConfig;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _segmentManager?.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  List<VideoSegmentConfig> videoConfigs = [
    VideoSegmentConfig(
      url: "http://192.168.31.174:3923/Downloads/VolkswagenGTIReview.mp4",
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
      url: "http://192.168.31.174:3923/Downloads/TearsOfSteel.mp4",
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
      url: "http://192.168.31.174:3923/Downloads/Sintel.mp4",
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

  Future<void> initializePlayer(VideoSegmentConfig config) async {
    final currentSegment = config.currentPlayingSegment;
    if (currentSegment == null) return;

    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(config.url),
    );
    await _videoPlayerController!.initialize();
    _createChewieController(
      videoPlayerController: _videoPlayerController!,
      config: config,
    );
    _setupSegmentManager(
      videoPlayerController: _videoPlayerController!,
      config: config,
    );
    _currentPlayingConfig = config;
    setState(() {});
  }

  void _createChewieController({
    required VideoPlayerController videoPlayerController,
    required VideoSegmentConfig config,
  }) {
    _chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
      autoPlay: true,
      zoomAndPan: true,
      looping: false, // Disable looping for segment playback

      startAt: config.currentPlayingSegment?.start,

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

  void _setupSegmentManager({
    required VideoPlayerController videoPlayerController,
    required VideoSegmentConfig config,
  }) {
    // 停止旧的管理器
    _segmentManager?.stop();

    // 创建新的管理器
    _segmentManager = SegmentPlaybackManager(
      videoController: videoPlayerController,
      config: config,
      onAllSegmentsComplete: () {
        // 当当前视频的所有区间播放完毕时，切换到下一个视频
        toggleVideo();
      },
      onSegmentChanged: (updatedConfig) {
        if (mounted) {
          // 由于 config 是直接修改的，只需要触发 setState
          setState(() {});
        }
      },
    );

    // 启动管理器
    _segmentManager!.start(config: config);
  }

  VideoSegmentConfig? get currentPlayingConfig {
    return _currentPlayingConfig;
  }

  Future<void> toggleVideo() async {
    if (_videoPlayerController == null) return;
    if (_currentPlayingConfig == null) return;

    await _videoPlayerController!.pause();

    // 找到当前播放的配置
    final currentIndex = videoConfigs.indexWhere((config) => config.isPlaying);

    // 重置当前视频状态
    if (currentIndex >= 0 && currentIndex < videoConfigs.length) {
      videoConfigs[currentIndex].reset();
    }

    // 切换到下一个视频
    final nextIndex = (currentIndex + 1) % videoConfigs.length;
    final nextConfig = videoConfigs[nextIndex];
    final firstSegment = nextConfig.segments.first;

    // 设置新的播放区间
    nextConfig.setPlayingSegment(firstSegment);
    await initializePlayer(videoConfigs[nextIndex]);
  }

  void _onSegmentSelected(VideoSegmentConfig config) async {
    // 检查是否切换到不同视频
    final currentConfig = currentPlayingConfig;

    if (currentConfig == null) {
      // 如果没有正在播放的视频，直接初始化播放选中的视频
      await initializePlayer(config);
      return;
    }

    if (config.url != currentConfig.url) {
      // 切换视频：重置当前视频状态，设置新视频区间
      currentConfig.reset();

      // 切换视频：更新配置并初始化播放器
      await initializePlayer(config);
    } else {
      // 同一视频，直接跳转到指定区间
      _segmentManager?.jumpToSegment(config);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Column(
          children: <Widget>[
            // 播放器区域（正方形）
            SizedBox(
              height: screenWidth,
              width: screenWidth,
              child:
                  _chewieController != null &&
                      _chewieController!
                          .videoPlayerController
                          .value
                          .isInitialized
                  ? Chewie(controller: _chewieController!)
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 20),
                          Text('Loading'),
                        ],
                      ),
                    ),
            ),
            // 播放列表区域
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.playlist_play,
                            size: 20,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '播放列表',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: VideoPlaylistWidget(
                        videoConfigs: videoConfigs,
                        onSegmentSelected: _onSegmentSelected,
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
