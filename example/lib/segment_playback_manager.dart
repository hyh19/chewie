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
  const VideoSegmentConfig({required this.url, required this.segments});

  final String url;
  final List<PlaybackSegment> segments;
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
    this.onAllSegmentsComplete,
    this.onSegmentChanged,
  });

  final VideoPlayerController videoController;
  final List<PlaybackSegment> segments;
  final void Function()? onAllSegmentsComplete;
  final void Function(int index)? onSegmentChanged;

  int _currentSegmentIndex = 0;
  bool _isActive = false;

  /// 获取当前区间索引
  int get currentSegmentIndex => _currentSegmentIndex;

  /// 启动区间播放管理
  void start() {
    _isActive = true;
    _currentSegmentIndex = 0;
    videoController.addListener(_onPositionChanged);

    // 跳转到第一个区间的起始位置
    if (segments.isNotEmpty) {
      videoController.seekTo(segments[0].start);
      onSegmentChanged?.call(0);
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
        onSegmentChanged?.call(_currentSegmentIndex);
      } else {
        // 所有区间播放完毕
        stop();
        videoController.pause();
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
      onSegmentChanged?.call(index);
    }
  }

  /// 释放资源
  void dispose() {
    stop();
  }
}
