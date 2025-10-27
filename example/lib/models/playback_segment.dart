import 'package:get/get.dart';

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
