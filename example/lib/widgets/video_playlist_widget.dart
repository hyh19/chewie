import 'package:chewie_example/models/video_segment_config.dart';
import 'package:chewie_example/widgets/video_playlist_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 视频播放列表组件，显示所有视频 URL 及其播放区间，支持折叠/展开和高亮当前播放项
class VideoPlaylistWidget extends StatelessWidget {
  const VideoPlaylistWidget({super.key, required this.playlistVideos});

  // 响应式视频列表，列表变化时自动更新 UI
  final RxList<PlaylistVideo> playlistVideos;

  @override
  Widget build(BuildContext context) {
    // 使用 Obx 响应式包装，列表变化时自动重新构建
    return Obx(() {
      // 如果列表为空，显示提示信息
      if (playlistVideos.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                '播放列表为空',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                '点击右下角按钮添加视频',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: playlistVideos.length,
        // 动态构建每个视频条目
        itemBuilder: (context, index) {
          final video = playlistVideos[index];

          return VideoPlaylistItemWidget(video: video);
        },
      );
    });
  }
}
