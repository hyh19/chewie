import 'package:chewie_example/models/playback_segment.dart';
import 'package:get/get.dart';

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
