import 'package:chewie/chewie.dart';
import 'package:chewie_example/models/playback_segment.dart';
import 'package:chewie_example/models/video_segment_config.dart';
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

  // 区间播放状态
  bool _isSegmentPlaybackActive = false;

  // 手动跳转标志（用于防止位置监听器干扰手动跳转）
  bool _isManualSeeking = false;

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

    // 建立 video config 之间的循环链表
    for (int i = 0; i < configs.length; i++) {
      configs[i].nextVideo = configs[(i + 1) % configs.length];
    }

    // 为每个 config 建立 segment 循环链表
    for (final config in configs) {
      config.linkSegments();
    }

    videoConfigs.value = configs;
  }

  /// 清理旧的播放器资源
  Future<void> _disposeOldPlayer() async {
    // 停止区间播放管理
    _stopSegmentPlayback();

    // 移除监听器
    _videoPlayerController?.removeListener(_updateInitializedState);

    // 释放 Chewie 控制器
    _chewieController?.dispose();
    _chewieController = null;

    // 释放视频播放器控制器
    await _videoPlayerController?.dispose();
    _videoPlayerController = null;

    // 更新初始化状态
    isInitialized.value = false;
  }

  /// 初始化播放器
  Future<void> initializePlayer(VideoSegmentConfig config) async {
    // 在初始化新播放器前，先清理旧的播放器资源
    await _disposeOldPlayer();

    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(config.url),
    );
    await _videoPlayerController!.initialize();
    _chewieController = _createChewieController(
      videoPlayerController: _videoPlayerController!,
      config: config,
    );

    // 监听视频播放器初始化状态
    _videoPlayerController!.addListener(_updateInitializedState);
    _updateInitializedState();

    // 启动区间播放管理
    _isSegmentPlaybackActive = true;

    // 根据是否有区间来确定播放起点
    if (config.segments.isEmpty) {
      // 没有区间，从 0 秒开始播放
      await _videoPlayerController!.seekTo(Duration.zero);
    } else {
      // 有区间，确定初始区间
      if (config.currentPlayingSegment.value == null) {
        // 未指定初始区间，使用第一个区间
        config.setPlayingSegment(config.segments.first);
      }
      // 跳转到区间起始位置
      await _videoPlayerController!.seekTo(
        config.currentPlayingSegment.value!.start,
      );
    }

    _videoPlayerController!.addListener(_onPositionChanged);
  }

  /// 创建 Chewie 控制器
  ChewieController _createChewieController({
    required VideoPlayerController videoPlayerController,
    required VideoSegmentConfig config,
  }) {
    return ChewieController(
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

      hideControlsTimer: const Duration(seconds: 600),
    );
  }

  /// 更新初始化状态
  void _updateInitializedState() {
    isInitialized.value =
        _chewieController != null &&
        _videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized;
  }

  /// 停止区间播放管理
  void _stopSegmentPlayback() {
    _isSegmentPlaybackActive = false;
    _isManualSeeking = false; // 重置手动跳转标志
    _videoPlayerController?.removeListener(_onPositionChanged);
  }

  /// 监听播放位置变化
  void _onPositionChanged() {
    // 如果正在手动跳转，则不进行自动纠正
    if (_isManualSeeking) return;

    final config = currentPlayingConfig.value;
    if (!_isSegmentPlaybackActive ||
        config == null ||
        config.segments.isEmpty) {
      return;
    }

    final position = _videoPlayerController!.value.position;
    final currentSegment = config.currentPlayingSegment.value;
    if (currentSegment == null) return;

    // 超出当前区间结束时间
    if (position > currentSegment.end) {
      // 使用循环链表直接获取下一个区间
      final nextSegment = currentSegment.nextSegment;

      // 检查当前区间是否是最后一个区间
      final isLastSegment = currentSegment == config.segments.last;

      if (isLastSegment) {
        // 所有区间播放完毕，切换到下一个视频
        _stopSegmentPlayback();
        _videoPlayerController!.pause();
        config.reset();
        toggleVideo();
      } else {
        // 还有后续区间，跳转到下一个区间
        config.setPlayingSegment(nextSegment);
        _videoPlayerController!.seekTo(nextSegment.start);
      }
    }
    // 用户拖动到区间之前
    else if (position < currentSegment.start) {
      _videoPlayerController!.seekTo(currentSegment.start);
    }
  }

  /// 跳转到指定区间
  void _jumpToSegment(VideoSegmentConfig config) async {
    final targetSegment = config.currentPlayingSegment.value;
    if (targetSegment == null) return;

    // 设置手动跳转标志，防止位置监听器干扰
    _isManualSeeking = true;

    // 执行跳转操作
    await _videoPlayerController!.seekTo(targetSegment.start);

    // 等待跳转完成后重置标志（500ms 延迟确保 seek 操作完成并稳定）
    Future.delayed(const Duration(milliseconds: 500), () {
      _isManualSeeking = false;
    });
  }

  /// 切换视频
  Future<void> toggleVideo() async {
    if (currentPlayingConfig.value == null) return;

    // 获取当前配置
    final currentConfig = currentPlayingConfig.value!;

    // 重置当前视频状态
    currentConfig.reset();

    // 使用循环链表直接获取下一个视频
    final nextConfig = currentConfig.nextVideo;
    final firstSegment = nextConfig.segments.first;

    // 设置新的播放区间
    nextConfig.setPlayingSegment(firstSegment);
    currentPlayingConfig.value = nextConfig;
    await initializePlayer(nextConfig);
  }

  /// 处理区间点击
  void onSegmentTapped(PlaybackSegment segment) async {
    final config = segment.parentConfig;
    config.setPlayingSegment(segment);

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
      _jumpToSegment(config);
    }
  }

  @override
  void onClose() {
    _disposeOldPlayer();
    super.onClose();
  }
}
