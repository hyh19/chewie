import 'package:chewie_example/models/playback_segment.dart';
import 'package:get/get.dart';

/// 播放列表中的视频及其播放区间
class PlaylistVideo {
  PlaylistVideo({required this.url, PlaybackSegment? currentPlayingSegment})
    : segments = <PlaybackSegment>[],
      currentPlayingSegment = Rx<PlaybackSegment?>(currentPlayingSegment);

  // 视频网络地址
  final String url;
  // 该视频的所有播放区间列表
  final List<PlaybackSegment> segments;
  // 当前正在播放的区间（响应式），用于追踪播放状态
  final Rx<PlaybackSegment?> currentPlayingSegment;
  // 下一个视频对象，形成循环链表结构以实现无限播放
  late PlaylistVideo nextVideo;

  /// 添加一个 segment
  void addSegment(PlaybackSegment segment) {
    // 建立双向引用，让 segment 可以访问所属的视频对象
    segment.parentVideo = this;
    segments.add(segment);
  }

  /// 重置视频到初始状态
  void reset() {
    // 清除当前播放的区间引用
    currentPlayingSegment.value = null;
    // 将所有区间的播放状态重置为 false
    for (final segment in segments) {
      segment.isPlaying.value = false;
    }
  }

  /// 建立 segment 循环链表，实现无缝循环播放
  void linkSegments() {
    if (segments.isEmpty) return;

    // 使用模运算实现循环链表，最后一个 segment 指向第一个
    for (int i = 0; i < segments.length; i++) {
      segments[i].nextSegment = segments[(i + 1) % segments.length];
    }
  }

  /// 切换到新的播放区间，自动处理旧区间和新区间的播放状态
  void setPlayingSegment(PlaybackSegment newSegment) {
    // 取消旧区间的播放状态
    if (currentPlayingSegment.value != null) {
      currentPlayingSegment.value!.isPlaying.value = false;
    }

    // 激活新区间的播放状态，触发 UI 更新
    newSegment.isPlaying.value = true;

    // 更新当前播放区间引用
    currentPlayingSegment.value = newSegment;
  }

  /// 根据播放时间查找对应的播放区间，返回第一个匹配的区间
  PlaybackSegment? findSegmentAtPosition(Duration position) {
    // 遍历所有 segment，返回第一个包含该时间点的区间
    for (final segment in segments) {
      if (segment.contains(position)) {
        return segment;
      }
    }
    return null;
  }

  /// 判断是否正在播放，需要同时满足有当前区间且该区间正在播放
  bool get isPlaying {
    return currentPlayingSegment.value != null &&
        currentPlayingSegment.value!.isPlaying.value;
  }
}
