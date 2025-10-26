import 'package:chewie_example/segment_playback_manager.dart';
import 'package:flutter/material.dart';

/// 视频播放列表组件
///
/// 显示所有视频 URL 及其播放区间，支持折叠/展开，高亮当前播放项
class VideoPlaylistWidget extends StatelessWidget {
  const VideoPlaylistWidget({
    super.key,
    required this.videoConfigs,
    required this.currentVideoIndex,
    required this.currentSegmentIndex,
    required this.onVideoSelected,
    required this.onSegmentSelected,
  });

  final List<VideoSegmentConfig> videoConfigs;
  final int currentVideoIndex;
  final int currentSegmentIndex;
  final void Function(int videoIndex) onVideoSelected;
  final void Function(int videoIndex, int segmentIndex) onSegmentSelected;

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
    return ListView.builder(
      itemCount: videoConfigs.length,
      itemBuilder: (context, videoIndex) {
        final config = videoConfigs[videoIndex];
        final isCurrentVideo = videoIndex == currentVideoIndex;

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
              _extractFileName(config.url),
              style: TextStyle(
                fontWeight: isCurrentVideo
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isCurrentVideo ? Theme.of(context).primaryColor : null,
              ),
            ),
            subtitle: Text(
              '${config.segments.length} 个播放区间',
              style: const TextStyle(fontSize: 12),
            ),
            children: config.segments.map((segment) {
              final segmentIndex = config.segments.indexOf(segment);
              final isCurrentSegment =
                  isCurrentVideo && segmentIndex == currentSegmentIndex;

              return ListTile(
                dense: true,
                leading: Container(
                  width: 4,
                  height: double.infinity,
                  color: isCurrentSegment
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                ),
                title: Text(
                  '区间 ${segmentIndex + 1}',
                  style: TextStyle(
                    fontWeight: isCurrentSegment
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isCurrentSegment
                        ? Theme.of(context).primaryColor
                        : null,
                  ),
                ),
                subtitle: Text(
                  '${_formatDuration(segment.start)} - ${_formatDuration(segment.end)}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
                trailing: isCurrentSegment
                    ? Icon(
                        Icons.play_arrow,
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
                onTap: () {
                  if (videoIndex != currentVideoIndex) {
                    onVideoSelected(videoIndex);
                  }
                  onSegmentSelected(videoIndex, segmentIndex);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
