import 'package:video_player/video_player.dart';

/// 表示一个视频播放的时间区间
class PlaybackSegment {
  const PlaybackSegment({required this.start, required this.end});

  final Duration start;
  final Duration end;

  bool contains(Duration position) {
    return position >= start && position <= end;
  }
}

/// 视频及其播放区间的配置
class VideoSegmentConfig {
  const VideoSegmentConfig({
    required this.url,
    required this.segments,
    this.currentPlayingSegment,
  });

  final String url;
  final List<PlaybackSegment> segments;
  final PlaybackSegment? currentPlayingSegment;

  /// 创建配置的副本并更新指定字段
  VideoSegmentConfig copyWith({
    String? url,
    List<PlaybackSegment>? segments,
    PlaybackSegment? currentPlayingSegment,
  }) {
    return VideoSegmentConfig(
      url: url ?? this.url,
      segments: segments ?? this.segments,
      currentPlayingSegment:
          currentPlayingSegment ?? this.currentPlayingSegment,
    );
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

  int _currentSegmentIndex = 0;
  bool _isActive = false;

  /// 获取当前区间索引
  int get currentSegmentIndex => _currentSegmentIndex;

  /// 启动区间播放管理
  void start({required VideoSegmentConfig config}) {
    _isActive = true;

    // 确定初始区间：使用传入的 config 的 currentPlayingSegment
    final initialSegment = config.currentPlayingSegment;
    if (initialSegment == null) {
      // 如果没有指定初始区间，使用第一个区间
      if (config.segments.isNotEmpty) {
        final updatedConfig = config.copyWith(
          currentPlayingSegment: config.segments.first,
        );
        onSegmentChanged?.call(updatedConfig);
        _currentSegmentIndex = 0;
      }
    } else {
      // 查找指定区间在列表中的位置
      final segmentIndex = config.segments.indexWhere(
        (segment) =>
            segment.start == initialSegment.start &&
            segment.end == initialSegment.end,
      );
      if (segmentIndex >= 0) {
        _currentSegmentIndex = segmentIndex;
      } else {
        _currentSegmentIndex = 0;
      }
    }

    videoController.addListener(_onPositionChanged);

    // 跳转到指定区间的起始位置
    if (config.segments.isNotEmpty &&
        _currentSegmentIndex < config.segments.length) {
      videoController.seekTo(config.segments[_currentSegmentIndex].start);
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
    final currentSegment = config.segments[_currentSegmentIndex];

    // 超出当前区间结束时间
    if (position > currentSegment.end) {
      if (_currentSegmentIndex < config.segments.length - 1) {
        // 跳转到下一个区间
        _currentSegmentIndex++;
        videoController.seekTo(config.segments[_currentSegmentIndex].start);
        final updatedConfig = config.copyWith(
          currentPlayingSegment: config.segments[_currentSegmentIndex],
        );
        onSegmentChanged?.call(updatedConfig);
      } else {
        // 所有区间播放完毕
        stop();
        videoController.pause();
        final updatedConfig = config.copyWith(currentPlayingSegment: null);
        onSegmentChanged?.call(updatedConfig);
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
    final targetSegment = config.currentPlayingSegment;
    if (targetSegment == null) return;

    // 查找目标区间在列表中的位置
    final segmentIndex = config.segments.indexWhere(
      (segment) =>
          segment.start == targetSegment.start &&
          segment.end == targetSegment.end,
    );

    if (segmentIndex >= 0) {
      _currentSegmentIndex = segmentIndex;
      videoController.seekTo(config.segments[segmentIndex].start);
      final updatedConfig = config.copyWith(
        currentPlayingSegment: config.segments[segmentIndex],
      );
      onSegmentChanged?.call(updatedConfig);
    }
  }

  /// 释放资源
  void dispose() {
    stop();
  }
}
