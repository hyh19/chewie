import 'package:chewie_example/controllers/video_playlist_controller.dart';
import 'package:chewie_example/segment_playback_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 播放区间条目组件
///
/// 用于显示单个播放区间的信息
class SegmentItemWidget extends StatelessWidget {
  const SegmentItemWidget({super.key, required this.segment});

  final PlaybackSegment segment;

  /// 格式化时间显示
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isPlaying = segment.isPlaying.value;

      return ListTile(
        dense: true,
        leading: Container(
          width: 4,
          height: double.infinity,
          color: isPlaying
              ? Theme.of(context).primaryColor
              : Colors.grey.shade300,
        ),
        title: Text(
          '${_formatDuration(segment.start)} - ${_formatDuration(segment.end)}',
          style: TextStyle(
            fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
            color: isPlaying ? Theme.of(context).primaryColor : null,
            fontFamily: 'monospace',
            fontSize: 13,
          ),
        ),
        trailing: isPlaying
            ? Icon(Icons.play_arrow, color: Theme.of(context).primaryColor)
            : null,
        onTap: () {
          Get.find<VideoPlaylistController>().onSegmentTapped(segment);
        },
      );
    });
  }
}
