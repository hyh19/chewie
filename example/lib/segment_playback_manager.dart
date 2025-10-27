import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

/// 表示一个视频播放的时间区间
class PlaybackSegment {
  PlaybackSegment({
    required this.start,
    required this.end,
    bool isPlaying = false,
  }) : isPlaying = RxBool(isPlaying);

  final Duration start;
  final Duration end;
  late final parentConfig;
  final RxBool isPlaying;

  bool contains(Duration position) {
    return position >= start && position <= end;
  }
}

/// 视频及其播放区间的配置
class VideoSegmentConfig {
  VideoSegmentConfig({
    required this.url,
    PlaybackSegment? currentPlayingSegment,
  }) : segments = <PlaybackSegment>[],
       currentPlayingSegment = Rx<PlaybackSegment?>(currentPlayingSegment);

  final String url;
  final List<PlaybackSegment> segments;
  final Rx<PlaybackSegment?> currentPlayingSegment;

  /// 添加一个 segment
  void addSegment(PlaybackSegment segment) {
    segment.parentConfig = this;
    segments.add(segment);
  }

  /// 重置配置到初始状态
  void reset() {
    currentPlayingSegment.value = null;
    for (final segment in segments) {
      segment.isPlaying.value = false;
    }
  }

  /// 切换到新的播放区间
  /// 自动处理旧区间和新区间的播放状态
  void setPlayingSegment(PlaybackSegment newSegment) {
    // 将旧区间的播放状态设为 false
    if (currentPlayingSegment.value != null) {
      currentPlayingSegment.value!.isPlaying.value = false;
    }

    // 将新区间的播放状态设为 true
    newSegment.isPlaying.value = true;

    // 设置新区间
    currentPlayingSegment.value = newSegment;
  }

  /// 判断是否正在播放
  bool get isPlaying {
    return currentPlayingSegment.value != null &&
        currentPlayingSegment.value!.isPlaying.value;
  }
}

/// 视频区间播放管理器
///
/// 负责管理视频的区间播放逻辑，包括：
/// - 监听播放位置变化
/// - 自动跳转到下一个区间
/// - 在区间外时自动跳回区间内
/// - 所有区间播放完毕后触发回调
class SegmentPlaybackManager {
  SegmentPlaybackManager({
    required this.videoController,
    required this.config,
    this.onAllSegmentsComplete,
    this.onSegmentChanged,
  });

  final VideoPlayerController videoController;
  final VideoSegmentConfig config;
  final void Function()? onAllSegmentsComplete;
  final void Function(VideoSegmentConfig config)? onSegmentChanged;

  bool _isActive = false;

  /// 启动区间播放管理
  void start({required VideoSegmentConfig config}) {
    _isActive = true;

    // 确定初始区间：使用传入的 config 的 currentPlayingSegment
    final initialSegment = config.currentPlayingSegment.value;
    if (initialSegment == null) {
      // 如果没有指定初始区间，使用第一个区间
      if (config.segments.isNotEmpty) {
        config.setPlayingSegment(config.segments.first);
        onSegmentChanged?.call(config);
      }
    }

    videoController.addListener(_onPositionChanged);

    // 跳转到指定区间的起始位置
    if (config.segments.isNotEmpty &&
        config.currentPlayingSegment.value != null) {
      videoController.seekTo(config.currentPlayingSegment.value!.start);
    }
  }

  /// 停止区间播放管理
  void stop() {
    _isActive = false;
    videoController.removeListener(_onPositionChanged);
  }

  void _onPositionChanged() {
    if (!_isActive || config.segments.isEmpty) return;

    final position = videoController.value.position;
    final currentSegment = config.currentPlayingSegment.value;
    if (currentSegment == null) return;

    // 超出当前区间结束时间
    if (position > currentSegment.end) {
      final currentIndex = config.segments.indexOf(currentSegment);
      if (currentIndex < 0) return;

      if (currentIndex < config.segments.length - 1) {
        // 跳转到下一个区间
        final nextSegment = config.segments[currentIndex + 1];
        config.setPlayingSegment(nextSegment);
        videoController.seekTo(nextSegment.start);
        onSegmentChanged?.call(config);
      } else {
        // 所有区间播放完毕
        stop();
        videoController.pause();
        config.reset();
        onSegmentChanged?.call(config);
        onAllSegmentsComplete?.call();
      }
    }
    // 用户拖动到区间之前
    else if (position < currentSegment.start) {
      videoController.seekTo(currentSegment.start);
    }
  }

  /// 跳转到指定区间
  void jumpToSegment(VideoSegmentConfig config) {
    final targetSegment = config.currentPlayingSegment.value;
    videoController.seekTo(targetSegment!.start);
    onSegmentChanged?.call(config);
  }

  /// 释放资源
  void dispose() {
    stop();
  }
}
