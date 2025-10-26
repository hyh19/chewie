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
    required this.segments,
    required this.config,
    this.onAllSegmentsComplete,
    this.onSegmentChanged,
  });

  final VideoPlayerController videoController;
  final List<PlaybackSegment> segments;
  final VideoSegmentConfig config;
  final void Function()? onAllSegmentsComplete;
  final void Function(VideoSegmentConfig config)? onSegmentChanged;

  int _currentSegmentIndex = 0;
  bool _isActive = false;

  /// 获取当前区间索引
  int get currentSegmentIndex => _currentSegmentIndex;

  /// 启动区间播放管理
  void start({required int initialSegmentIndex}) {
    _isActive = true;
    _currentSegmentIndex = initialSegmentIndex;
    videoController.addListener(_onPositionChanged);

    // 跳转到指定区间的起始位置
    if (segments.isNotEmpty && initialSegmentIndex < segments.length) {
      videoController.seekTo(segments[initialSegmentIndex].start);
      final updatedConfig = config.copyWith(
        currentPlayingSegment: segments[initialSegmentIndex],
      );
      onSegmentChanged?.call(updatedConfig);
    }
  }

  /// 停止区间播放管理
  void stop() {
    _isActive = false;
    videoController.removeListener(_onPositionChanged);
  }

  void _onPositionChanged() {
    if (!_isActive || segments.isEmpty) return;

    final position = videoController.value.position;
    final currentSegment = segments[_currentSegmentIndex];

    // 超出当前区间结束时间
    if (position > currentSegment.end) {
      if (_currentSegmentIndex < segments.length - 1) {
        // 跳转到下一个区间
        _currentSegmentIndex++;
        videoController.seekTo(segments[_currentSegmentIndex].start);
        final updatedConfig = config.copyWith(
          currentPlayingSegment: segments[_currentSegmentIndex],
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
  void jumpToSegment(int index) {
    if (index >= 0 && index < segments.length) {
      _currentSegmentIndex = index;
      videoController.seekTo(segments[index].start);
      final updatedConfig = config.copyWith(
        currentPlayingSegment: segments[index],
      );
      onSegmentChanged?.call(updatedConfig);
    }
  }

  /// 释放资源
  void dispose() {
    stop();
  }
}
