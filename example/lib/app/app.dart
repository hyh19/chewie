import 'package:chewie/chewie.dart';
import 'package:chewie_example/app/theme.dart';
import 'package:chewie_example/controllers/video_playlist_controller.dart';
import 'package:chewie_example/widgets/video_playlist_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 应用主入口，包含播放器和播放列表的主要 UI
class ChewieDemo extends StatelessWidget {
  const ChewieDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // 注入并获取视频播放列表控制器
    final controller = Get.put(VideoPlaylistController());

    return GetMaterialApp(
      theme: AppTheme.light,
      // 构建主页面：播放器在上，播放列表在下
      home: _buildHome(context, controller),
    );
  }

  /// 构建主页面布局：正方形播放器和可滚动播放列表
  Widget _buildHome(BuildContext context, VideoPlaylistController controller) {
    // 获取屏幕宽度，用于创建正方形播放器
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: <Widget>[
          // 正方形播放器区域，自适应屏幕宽度
          SizedBox(
            height: screenWidth,
            width: screenWidth,
            child: GetX<VideoPlaylistController>(
              builder: (controller) {
                // 播放器初始化完成后显示 Chewie 控件
                if (controller.isInitialized.value) {
                  return Chewie(controller: controller.chewieController!);
                } else {
                  // 初始化中显示加载指示器
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
          // 播放列表区域，占据剩余空间
          Expanded(
            child: Container(
              // 添加浅灰背景和顶部边框，区分播放列表区域
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                children: [
                  // 播放列表标题栏
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
                  // 播放列表内容区域，可滚动
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
