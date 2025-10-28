import 'package:chewie/chewie.dart';
import 'package:chewie_example/app/theme.dart';
import 'package:chewie_example/controllers/video_playlist_controller.dart';
import 'package:chewie_example/widgets/add_video_page.dart';
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
      appBar: AppBar(title: const Text('')),
      body: GetX<VideoPlaylistController>(
        builder: (controller) {
          // 根据播放列表是否为空，决定是否显示播放器
          final List<Widget> children;

          if (controller.playlistVideos.isEmpty) {
            // 播放列表为空时，只显示播放列表区域
            children = [
              Expanded(
                child: Container(
                  // 添加浅灰背景，区分播放列表区域
                  decoration: BoxDecoration(color: Colors.grey.shade100),
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
            ];
          } else {
            // 播放列表不为空时，显示完整的布局（播放器 + 播放列表）
            children = [
              // 正方形播放器区域，自适应屏幕宽度
              SizedBox(
                height: screenWidth,
                width: screenWidth,
                child: GetX<VideoPlaylistController>(
                  builder: (controller) {
                    // 如果发生错误，显示错误 UI
                    if (controller.hasError.value) {
                      return Container(
                        color: Colors.black87,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 64,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  '视频加载失败',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  controller.errorMessage.value,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          controller.retryCurrentVideo(),
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('重试'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    OutlinedButton.icon(
                                      onPressed:
                                          controller
                                                  .currentPlayingVideo
                                                  .value !=
                                              null
                                          ? () => controller.deleteVideo(
                                              controller
                                                  .currentPlayingVideo
                                                  .value!,
                                            )
                                          : null,
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text('删除视频'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(
                                          color: Colors.white70,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    // 播放器初始化完成后显示 Chewie 控件
                    if (controller.isInitialized.value) {
                      return Chewie(controller: controller.chewieController!);
                    } else {
                      // 初始化中显示加载指示器
                      return Container(
                        color: Colors.black87,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 20),
                              Text(
                                '正在加载视频...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
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
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
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
            ];
          }

          return Column(children: children);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 使用 GetX 显示 BottomSheet
          final urls = await Get.bottomSheet<List<String>>(
            const AddVideoBottomSheet(),
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          );

          // 如果返回了 URL 列表，添加到播放列表
          if (urls != null && urls.isNotEmpty) {
            await controller.addVideos(urls);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
