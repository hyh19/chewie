import 'package:chewie_example/controllers/video_playlist_controller.dart';
import 'package:chewie_example/models/playback_segment.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 播放区间条目组件，用于显示单个播放区间的信息
class SegmentItemWidget extends StatelessWidget {
  const SegmentItemWidget({super.key, required this.segment});

  // 该组件展示的播放区间对象
  final PlaybackSegment segment;

  /// 格式化时间显示为 mm:ss 或 hh:mm:ss 格式
  String _formatDuration(Duration duration) {
    // 将数字格式化为两位数，不足两位前面补 0
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    // 超过 1 小时时显示小时部分
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Obx 响应式包装，自动更新播放状态的高亮显示
    return Obx(() {
      // 追踪当前区间的播放状态
      final isPlaying = segment.isPlaying.value;

      return ListTile(
        dense: true,
        // 左侧彩色指示条，播放中的区间显示主题色，否则为灰色
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
        // 播放中的区间显示播放图标
        trailing: isPlaying
            ? Icon(Icons.play_arrow, color: Theme.of(context).primaryColor)
            : null,
        // 点击区间时调用控制器切换或跳转到该区间
        onTap: () {
          Get.find<VideoPlaylistController>().onSegmentTapped(segment);
        },
      );
    });
  }
}
