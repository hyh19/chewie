import 'package:chewie/chewie.dart';
import 'package:chewie_example/app/theme.dart';
import 'package:chewie_example/segment_playback_manager.dart';
import 'package:chewie_example/video_playlist_widget.dart';
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

  bool _isPlaylistExpanded = true;

  @override
  void initState() {
    super.initState();
    // 初始化时将第一个视频的第一个区间设置为当前播放区间
    final firstConfig = videoConfigs.first;
    final firstSegment = firstConfig.segments.first;
    initializePlayer(
      videoConfigs.first.copyWith(currentPlayingSegment: firstSegment),
    );
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

    final segmentIndex = config.segments.indexOf(currentSegment);
    if (segmentIndex < 0) return;

    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(config.url),
    );
    await _videoPlayerController.initialize();
    _createChewieController(config: config, segmentIndex: segmentIndex);
    _setupSegmentManager(config: config, segmentIndex: segmentIndex);
    setState(() {});
  }

  void _createChewieController({
    required VideoSegmentConfig config,
    required int segmentIndex,
  }) {
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      zoomAndPan: true,
      looping: false, // Disable looping for segment playback

      startAt:
          config.segments.isNotEmpty && segmentIndex < config.segments.length
          ? config.segments[segmentIndex].start
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

  void _setupSegmentManager({
    required VideoSegmentConfig config,
    required int segmentIndex,
  }) {
    // 停止旧的管理器
    _segmentManager?.stop();

    // 创建新的管理器
    _segmentManager = SegmentPlaybackManager(
      videoController: _videoPlayerController,
      config: config,
      onAllSegmentsComplete: () {
        // 当当前视频的所有区间播放完毕时，切换到下一个视频
        toggleVideo();
      },
      onSegmentChanged: (updatedConfig) {
        if (mounted) {
          setState(() {
            // 更新对应配置的当前播放区间
            final index = videoConfigs.indexWhere((c) => c.url == config.url);
            if (index >= 0) {
              videoConfigs[index] = updatedConfig;
            }
          });
        }
      },
    );

    // 启动管理器
    _segmentManager!.start(config: config);
  }

  VideoSegmentConfig get currentPlayingConfig {
    return videoConfigs.firstWhere(
      (config) => config.currentPlayingSegment != null,
      orElse: () => videoConfigs.first,
    );
  }

  Future<void> toggleVideo() async {
    await _videoPlayerController.pause();

    // 找到当前播放的配置
    final currentIndex = videoConfigs.indexWhere(
      (config) => config.currentPlayingSegment != null,
    );

    // 切换到下一个视频
    final nextIndex = (currentIndex + 1) % videoConfigs.length;
    final nextConfig = videoConfigs[nextIndex];
    final firstSegment = nextConfig.segments.first;

    // 更新配置并初始化播放器
    videoConfigs[nextIndex] = nextConfig.copyWith(
      currentPlayingSegment: firstSegment,
    );
    await initializePlayer(videoConfigs[nextIndex]);
  }

  void _onSegmentSelected(
    VideoSegmentConfig config,
    PlaybackSegment segment,
  ) async {
    // 检查是否切换到不同视频
    final currentConfig = currentPlayingConfig;

    if (config.url != currentConfig.url) {
      // 切换视频：更新配置并初始化播放器
      final index = videoConfigs.indexWhere((c) => c.url == config.url);
      if (index >= 0) {
        videoConfigs[index] = config.copyWith(currentPlayingSegment: segment);
        await initializePlayer(videoConfigs[index]);
      }
    } else {
      // 同一视频，直接跳转到指定区间
      final newConfig = config.copyWith(currentPlayingSegment: segment);
      _segmentManager?.jumpToSegment(newConfig);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return MaterialApp(
      title: widget.title,
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: Icon(
                _isPlaylistExpanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_up,
              ),
              onPressed: () {
                setState(() {
                  _isPlaylistExpanded = !_isPlaylistExpanded;
                });
              },
              tooltip: _isPlaylistExpanded ? '收起列表' : '展开列表',
            ),
          ],
        ),
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
            if (_isPlaylistExpanded)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
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
