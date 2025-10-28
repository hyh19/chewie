import 'package:chewie_example/controllers/video_playlist_controller.dart';
import 'package:chewie_example/models/video_segment_config.dart';
import 'package:chewie_example/widgets/add_segment_bottom_sheet.dart';
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
            video.segments.isEmpty ? '无播放区间' : '${video.segments.length} 个播放区间',
            style: const TextStyle(fontSize: 12),
          ),
          // 如果视频没有播放区间，点击时直接播放；否则展开显示区间列表
          onExpansionChanged: video.segments.isEmpty
              ? (expanded) {
                  // 无区间时点击直接播放视频
                  final controller = Get.find<VideoPlaylistController>();
                  controller.onVideoTapped(video);
                }
              : null,
          // 将每个 segment 映射为 SegmentItemWidget，并在末尾添加"添加区间"按钮
          children: [
            ...video.segments.map((segment) {
              return SegmentItemWidget(segment: segment);
            }),
            // 添加区间按钮
            ListTile(
              dense: true,
              leading: Icon(
                Icons.add_circle_outline,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text(
                '添加区间',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                final controller = Get.find<VideoPlaylistController>();

                // 如果该视频正在播放，暂停视频
                final wasPlaying = video.isPlaying;
                if (wasPlaying) {
                  controller.pauseVideo();
                }

                // 获取视频最大时长
                final maxDuration = controller.getVideoMaxDuration(video);

                // 显示添加区间 BottomSheet
                final result = await Get.bottomSheet<Map<String, Duration>>(
                  AddSegmentBottomSheet(maxDuration: maxDuration),
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                );

                // 如果返回了时间段，添加到视频
                if (result != null) {
                  controller.addSegmentToVideo(
                    video: video,
                    start: result['start']!,
                    end: result['end']!,
                  );
                }

                // 不自动恢复播放，让用户自己控制
              },
            ),
          ],
        ),
      );
    });
  }
}
