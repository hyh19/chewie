import 'package:chewie_example/models/video_segment_config.dart';
import 'package:chewie_example/widgets/video_playlist_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 视频播放列表组件
///
/// 显示所有视频 URL 及其播放区间，支持折叠/展开，高亮当前播放项
class VideoPlaylistWidget extends StatelessWidget {
  const VideoPlaylistWidget({super.key, required this.videoConfigs});

  final RxList<VideoSegmentConfig> videoConfigs;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ListView.builder(
        itemCount: videoConfigs.length,
        itemBuilder: (context, index) {
          final config = videoConfigs[index];

          return VideoPlaylistItemWidget(config: config);
        },
      ),
    );
  }
}
