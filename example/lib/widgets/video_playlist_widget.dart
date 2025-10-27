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
    return Obx(
      () => ListView.builder(
        itemCount: playlistVideos.length,
        // 动态构建每个视频条目
        itemBuilder: (context, index) {
          final video = playlistVideos[index];

          return VideoPlaylistItemWidget(video: video);
        },
      ),
    );
  }
}
