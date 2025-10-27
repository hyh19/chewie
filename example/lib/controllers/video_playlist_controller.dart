import 'package:chewie/chewie.dart';
import 'package:chewie_example/segment_playback_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

/// 视频播放列表控制器
///
/// 管理视频播放列表的所有状态和逻辑
class VideoPlaylistController extends GetxController {
  // 视频配置列表
  final RxList<VideoSegmentConfig> videoConfigs = <VideoSegmentConfig>[].obs;

  // 当前播放的视频配置
  final Rx<VideoSegmentConfig?> currentPlayingConfig = Rx<VideoSegmentConfig?>(
    null,
  );

  // 是否已初始化（响应式变量）
  final RxBool isInitialized = false.obs;

  // 视频播放器控制器
  VideoPlayerController? _videoPlayerController;

  // Chewie 控制器
  ChewieController? _chewieController;

  // 区间播放管理器
  SegmentPlaybackManager? _segmentManager;

  // Getter: 获取 videoPlayerController
  VideoPlayerController? get videoPlayerController => _videoPlayerController;

  // Getter: 获取 chewieController
  ChewieController? get chewieController => _chewieController;

  @override
  void onInit() {
    super.onInit();
    _initializeVideoConfigs();
  }

  /// 初始化视频配置列表
  void _initializeVideoConfigs() {
    final configs = <VideoSegmentConfig>[];

    // 创建第一个视频配置
    final config1 = VideoSegmentConfig(
      url: "http://192.168.31.174:3923/Downloads/VolkswagenGTIReview.mp4",
    );
    config1.addSegment(
      PlaybackSegment(
        start: const Duration(seconds: 15),
        end: const Duration(seconds: 30),
      ),
    );
    config1.addSegment(
      PlaybackSegment(
        start: const Duration(seconds: 45),
        end: const Duration(minutes: 1, seconds: 0),
      ),
    );
    config1.addSegment(
      PlaybackSegment(
        start: const Duration(minutes: 1, seconds: 15),
        end: const Duration(minutes: 1, seconds: 30),
      ),
    );
    configs.add(config1);

    // 创建第二个视频配置
    final config2 = VideoSegmentConfig(
      url: "http://192.168.31.174:3923/Downloads/TearsOfSteel.mp4",
    );
    config2.addSegment(
      PlaybackSegment(
        start: const Duration(seconds: 30),
        end: const Duration(seconds: 45),
      ),
    );
    config2.addSegment(
      PlaybackSegment(
        start: const Duration(minutes: 1, seconds: 0),
        end: const Duration(minutes: 1, seconds: 15),
      ),
    );
    config2.addSegment(
      PlaybackSegment(
        start: const Duration(minutes: 1, seconds: 30),
        end: const Duration(minutes: 1, seconds: 45),
      ),
    );
    configs.add(config2);

    // 创建第三个视频配置
    final config3 = VideoSegmentConfig(
      url: "http://192.168.31.174:3923/Downloads/Sintel.mp4",
    );
    config3.addSegment(
      PlaybackSegment(
        start: const Duration(seconds: 20),
        end: const Duration(seconds: 35),
      ),
    );
    config3.addSegment(
      PlaybackSegment(
        start: const Duration(seconds: 50),
        end: const Duration(minutes: 1, seconds: 5),
      ),
    );
    config3.addSegment(
      PlaybackSegment(
        start: const Duration(minutes: 1, seconds: 30),
        end: const Duration(minutes: 1, seconds: 45),
      ),
    );
    configs.add(config3);

    videoConfigs.value = configs;
  }

  /// 初始化播放器
  Future<void> initializePlayer(VideoSegmentConfig config) async {
    final currentSegment = config.currentPlayingSegment.value;
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
  }

  /// 创建 Chewie 控制器
  void _createChewieController({
    required VideoPlayerController videoPlayerController,
    required VideoSegmentConfig config,
  }) {
    _chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
      autoPlay: true,
      zoomAndPan: true,
      looping: false, // Disable looping for segment playback

      startAt: config.currentPlayingSegment.value?.start,

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

    // 监听视频播放器初始化状态
    _videoPlayerController!.addListener(_updateInitializedState);
    _updateInitializedState();
  }

  /// 更新初始化状态
  void _updateInitializedState() {
    isInitialized.value =
        _chewieController != null &&
        _videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized;
  }

  /// 设置区间播放管理器
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
        // Rx 变量会自动触发更新，无需手动 setState
      },
    );

    // 启动管理器
    _segmentManager!.start(config: config);
  }

  /// 切换视频
  Future<void> toggleVideo() async {
    if (_videoPlayerController == null) return;
    if (currentPlayingConfig.value == null) return;

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
    currentPlayingConfig.value = nextConfig;
    await initializePlayer(nextConfig);
  }

  /// 处理区间点击
  void onSegmentTapped(PlaybackSegment segment) {
    final parentConfig = segment.parentConfig;
    parentConfig.setPlayingSegment(segment);
    onSegmentSelected(parentConfig);
  }

  /// 处理区间选择
  void onSegmentSelected(VideoSegmentConfig config) async {
    final currentConfig = currentPlayingConfig.value;

    // 直接比较配置是否相等（包括 null 情况）
    if (currentConfig != config) {
      // 不相等：切换新视频
      // 重置旧配置状态（如果存在）
      currentConfig?.reset();
      // 赋值新配置
      currentPlayingConfig.value = config;
      await initializePlayer(config);
    } else {
      // 相等：同一视频，直接跳转到指定区间
      _segmentManager?.jumpToSegment(config);
    }
  }

  @override
  void onClose() {
    _videoPlayerController?.removeListener(_updateInitializedState);
    isInitialized.value = false;
    _segmentManager?.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.onClose();
  }
}
