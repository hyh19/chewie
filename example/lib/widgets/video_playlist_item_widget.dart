import 'package:chewie_example/models/video_segment_config.dart';
import 'package:chewie_example/widgets/segment_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 视频播放列表条目组件，用于显示单个视频及其所有播放区间
class VideoPlaylistItemWidget extends StatelessWidget {
  const VideoPlaylistItemWidget({super.key, required this.video});

  // 该组件展示的视频对象
  final PlaylistVideo video;

  /// 从 URL 中提取文件名
  String _extractFileName(String url) {
    try {
      // 解析 URL 并提取最后一个路径段作为文件名
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
      return url;
    } catch (e) {
      // 解析失败时返回原始 URL
      return url;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Obx 响应式包装，自动更新当前播放视频的高亮状态
    return Obx(() {
      // 判断当前视频是否正在播放
      final isCurrentVideo = video.isPlaying;

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        // 当前播放视频使用更高的 elevation 和主题色背景
        elevation: isCurrentVideo ? 4 : 1,
        color: isCurrentVideo
            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
            : null,
        child: ExpansionTile(
          leading: Icon(
            isCurrentVideo ? Icons.play_circle_filled : Icons.movie,
            color: isCurrentVideo
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),
          title: Text(
            _extractFileName(video.url),
            style: TextStyle(
              fontWeight: isCurrentVideo ? FontWeight.bold : FontWeight.normal,
              color: isCurrentVideo ? Theme.of(context).primaryColor : null,
            ),
          ),
          subtitle: Text(
            '${video.segments.length} 个播放区间',
            style: const TextStyle(fontSize: 12),
          ),
          // 将每个 segment 映射为 SegmentItemWidget
          children: video.segments.map((segment) {
            return SegmentItemWidget(segment: segment);
          }).toList(),
        ),
      );
    });
  }
}
