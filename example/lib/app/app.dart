import 'package:chewie/chewie.dart';
import 'package:chewie_example/app/theme.dart';
import 'package:chewie_example/controllers/video_playlist_controller.dart';
import 'package:chewie_example/widgets/video_playlist_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChewieDemo extends StatelessWidget {
  const ChewieDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // 注入控制器
    final controller = Get.put(VideoPlaylistController());

    return GetMaterialApp(
      theme: AppTheme.light,
      home: _buildHome(context, controller),
    );
  }

  Widget _buildHome(BuildContext context, VideoPlaylistController controller) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: <Widget>[
          // 播放器区域（正方形）
          SizedBox(
            height: screenWidth,
            width: screenWidth,
            child: GetX<VideoPlaylistController>(
              builder: (controller) {
                if (controller.isInitialized.value) {
                  return Chewie(controller: controller.chewieController!);
                } else {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text('Loading'),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
          // 播放列表区域
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.playlist_play,
                          size: 20,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '播放列表',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: VideoPlaylistWidget(
                      playlistVideos: controller.playlistVideos,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
