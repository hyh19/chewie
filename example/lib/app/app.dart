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

  int _currentSegmentIndex = 0;
  bool _isPlaylistExpanded = true;

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

    // 重置当前区间索引
    _currentSegmentIndex = 0;
    if (mounted) {
      setState(() {});
    }

    // 创建新的管理器
    _segmentManager = SegmentPlaybackManager(
      videoController: _videoPlayerController,
      segments: currentConfig.segments,
      onAllSegmentsComplete: () {
        // 当当前视频的所有区间播放完毕时，切换到下一个视频
        toggleVideo();
      },
      onSegmentChanged: (index) {
        if (mounted) {
          setState(() {
            _currentSegmentIndex = index;
          });
        }
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

  void _onVideoSelected(int index) {
    if (index != currPlayIndex) {
      currPlayIndex = index;
      initializePlayer();
    }
  }

  void _onSegmentSelected(int videoIndex, int segmentIndex) async {
    // 如果选择的是不同视频，先切换视频
    if (videoIndex != currPlayIndex) {
      currPlayIndex = videoIndex;
      await initializePlayer();
      // 等待初始化完成后跳转到指定区间
      if (_segmentManager != null &&
          segmentIndex < videoConfigs[videoIndex].segments.length) {
        _segmentManager!.jumpToSegment(segmentIndex);
      }
    } else {
      // 同一视频，直接跳转到指定区间
      if (_segmentManager != null &&
          segmentIndex < videoConfigs[videoIndex].segments.length) {
        _segmentManager!.jumpToSegment(segmentIndex);
      }
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
                          currentVideoIndex: currPlayIndex,
                          currentSegmentIndex: _currentSegmentIndex,
                          onVideoSelected: _onVideoSelected,
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
