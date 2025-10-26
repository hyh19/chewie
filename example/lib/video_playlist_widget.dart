import 'package:chewie_example/segment_playback_manager.dart';
import 'package:chewie_example/widgets/video_playlist_item_widget.dart';
import 'package:flutter/material.dart';

/// 视频播放列表组件
///
/// 显示所有视频 URL 及其播放区间，支持折叠/展开，高亮当前播放项
class VideoPlaylistWidget extends StatelessWidget {
  const VideoPlaylistWidget({
    super.key,
    required this.videoConfigs,
    required this.onSegmentSelected,
  });

  final List<VideoSegmentConfig> videoConfigs;
  final void Function(VideoSegmentConfig config, PlaybackSegment segment)
  onSegmentSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: videoConfigs.length,
      itemBuilder: (context, index) {
        final config = videoConfigs[index];
        // 判断是否为当前播放视频：检查是否至少有一个区间正在播放
        final isCurrentVideo = config.currentPlayingSegment != null;

        return VideoPlaylistItemWidget(
          config: config,
          isCurrentVideo: isCurrentVideo,
          onSegmentSelected: onSegmentSelected,
        );
      },
    );
  }
}
