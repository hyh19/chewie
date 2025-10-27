import 'package:chewie_example/models/video_segment_config.dart';
import 'package:chewie_example/widgets/segment_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 视频播放列表条目组件
///
/// 用于显示单个视频及其所有播放区间
class VideoPlaylistItemWidget extends StatelessWidget {
  const VideoPlaylistItemWidget({super.key, required this.video});

  final PlaylistVideo video;

  /// 从 URL 中提取文件名
  String _extractFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
      return url;
    } catch (e) {
      return url;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isCurrentVideo = video.isPlaying;

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          children: video.segments.map((segment) {
            return SegmentItemWidget(segment: segment);
          }).toList(),
        ),
      );
    });
  }
}
