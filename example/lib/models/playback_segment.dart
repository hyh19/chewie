import 'package:chewie_example/models/video_segment_config.dart';
import 'package:get/get.dart';

/// 表示一个视频播放的时间区间
class PlaybackSegment {
  PlaybackSegment({
    required this.start,
    required this.end,
    bool isPlaying = false,
  }) : isPlaying = RxBool(isPlaying);

  // 区间起始时间
  final Duration start;
  // 区间结束时间
  final Duration end;
  // 所属的视频对象，建立双向引用以便访问父对象
  late PlaylistVideo parentVideo;
  // 响应式播放状态，用于 UI 显示当前播放的区间
  final RxBool isPlaying;
  // 下一个播放区间，形成循环链表结构
  late PlaybackSegment nextSegment;

  // 判断指定时间是否在当前区间内（闭区间包含边界）
  bool contains(Duration position) {
    return position >= start && position <= end;
  }

  /// 转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {'start': start.inMilliseconds, 'end': end.inMilliseconds};
  }

  /// 从 JSON 格式创建 PlaybackSegment
  factory PlaybackSegment.fromJson(Map<String, dynamic> json) {
    return PlaybackSegment(
      start: Duration(milliseconds: json['start'] as int),
      end: Duration(milliseconds: json['end'] as int),
    );
  }
}
