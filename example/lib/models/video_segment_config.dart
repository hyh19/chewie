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
  late final VideoSegmentConfig nextVideo;

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

  /// 在所有 segment 添加完成后，建立循环链表
  /// 最后一个 segment 指向第一个 segment，形成循环
  void linkSegments() {
    if (segments.isEmpty) return;

    for (int i = 0; i < segments.length; i++) {
      segments[i].nextSegment = segments[(i + 1) % segments.length];
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

  /// 根据播放时间查找对应的播放区间
  /// 返回第一个包含该时间点的区间,如果不属于任何区间则返回 null
  PlaybackSegment? findSegmentAtPosition(Duration position) {
    for (final segment in segments) {
      if (segment.contains(position)) {
        return segment;
      }
    }
    return null;
  }

  /// 判断是否正在播放
  bool get isPlaying {
    return currentPlayingSegment.value != null &&
        currentPlayingSegment.value!.isPlaying.value;
  }
}
