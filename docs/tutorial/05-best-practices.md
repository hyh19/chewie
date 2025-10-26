# 第 5 章:最佳实践

## 概述

本章将分享使用 Chewie 和 video_player 的最佳实践,帮助你编写更高效、更优雅的代码。

## 资源管理

正确的资源管理是保证应用性能的关键。

### dispose 方法实现

```dart
@override
void dispose() {
  _videoPlayerController1.dispose();
  _videoPlayerController2.dispose();
  _chewieController?.dispose();
  super.dispose();
}
```

**关键点:**

- 必须释放所有控制器资源
- 使用 `?.` 安全调用避免空指针异常
- 按照创建顺序的逆序释放
- 最后调用 `super.dispose()`

### 避免内存泄漏

```dart
// 错误示例: 忘记 dispose
late VideoPlayerController _controller;

@override
void dispose() {
  // 缺少 _controller.dispose();
  super.dispose();
}

// 正确示例: 完整释放资源
late VideoPlayerController _controller;

@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

## 异步初始化处理

正确的异步初始化避免 UI 错误。

### 完整的初始化流程

```dart
Future<void> initializePlayer() async {
  // 1. 创建控制器
  _videoPlayerController = VideoPlayerController.networkUrl(
    Uri.parse(videoUrl),
  );
  
  // 2. 等待初始化完成
  try {
    await _videoPlayerController.initialize();
  } catch (e) {
    // 处理错误
    print('初始化失败: $e');
    return;
  }
  
  // 3. 创建 Chewie 控制器
  _createChewieController();
  
  // 4. 更新 UI
  if (mounted) {
    setState(() {});
  }
}
```

### 使用 try-catch 处理错误

```dart
try {
  await _videoPlayerController.initialize();
} catch (e) {
  // 记录错误日志
  debugPrint('视频初始化失败: $e');
  
  // 通知用户
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('视频加载失败')),
  );
}
```

### 检查 mounted 状态

```dart
@override
Future<void> initializePlayer() async {
  // ... 初始化代码 ...
  
  // 确保 Widget 仍然挂载
  if (mounted) {
    setState(() {});
  }
}
```

这可以避免在 `dispose()` 后调用 `setState()`。

## 状态管理建议

### 使用 ValueNotifier

对于需要频繁更新的状态,使用 `ValueNotifier`:

```dart
class VideoPlayerPage extends StatelessWidget {
  final VideoPlayerController controller = VideoPlayerController.networkUrl(
    Uri.parse('https://example.com/video.mp4'),
  );
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        // 根据播放状态构建 UI
        if (value.isInitialized) {
          return ChewieWidget(...);
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}
```

### 合理使用 setState

```dart
// 错误示例: 频繁调用 setState
void _onVideoProgress() {
  setState(() {});  // 避免在监听器中频繁调用
}

// 正确示例: 只在必要时调用
void _onVideoProgress() {
  // 不需要立即更新 UI 时,不调用 setState
}

@override
void initState() {
  super.initState();
  _videoPlayerController.addListener(_onVideoProgress);
}
```

## 性能优化

### 预加载视频

```dart
class _ChewieDemoState extends State<ChewieDemo> {
  late VideoPlayerController _controller1;
  late VideoPlayerController _controller2;
  
  @override
  void initState() {
    super.initState();
    // 同时预加载多个视频
    _preloadVideos();
  }
  
  Future<void> _preloadVideos() async {
    _controller1 = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl1),
    );
    _controller2 = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl2),
    );
    
    await Future.wait([
      _controller1.initialize(),
      _controller2.initialize(),
    ]);
    
    if (mounted) {
      setState(() {});
    }
  }
}
```

### 使用缩略图

```dart
placeholder: Image.network(
  thumbnailUrl,
  fit: BoxFit.cover,
),
```

在视频加载时显示缩略图,提升用户体验。

### 控制缓冲指示器

```dart
progressIndicatorDelay: const Duration(milliseconds: 200),
```

设置合适的延迟时间,避免在短暂缓冲时闪烁。

## 错误处理

### 网络错误处理

```dart
Future<void> initializePlayer() async {
  try {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
    );
    await _videoPlayerController.initialize();
    
    _createChewieController();
    if (mounted) setState(() {});
    
  } on Exception catch (e) {
    // 网络错误处理
    debugPrint('网络错误: $e');
    _showErrorMessage('网络连接失败');
  }
}
```

### 文件格式错误处理

```dart
try {
  await _videoPlayerController.initialize();
} on FormatException catch (e) {
  debugPrint('视频格式错误: $e');
  _showErrorMessage('不支持的视频格式');
}
```

### 超时处理

```dart
try {
  await _videoPlayerController.initialize().timeout(
    const Duration(seconds: 10),
  );
} on TimeoutException catch (e) {
  debugPrint('初始化超时: $e');
  _showErrorMessage('视频加载超时,请重试');
}
```

## UI/UX 优化

### 加载状态提示

```dart
_chewieController != null &&
    _chewieController!
        .videoPlayerController
        .value
        .isInitialized
    ? Chewie(controller: _chewieController!)
    : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在加载视频...'),
        ],
      ),
```

提供清晰的加载反馈。

### 错误状态处理

```dart
Widget _buildPlayerOrError() {
  return FutureBuilder<void>(
    future: _initializePlayer(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _buildErrorWidget(snapshot.error);
      }
      
      if (snapshot.connectionState == ConnectionState.done) {
        return Chewie(controller: _chewieController!);
      }
      
      return _buildLoadingWidget();
    },
  );
}
```

### 播放状态监听

```dart
void _onPlaybackStateChanged() {
  final isPlaying = _videoPlayerController.value.isPlaying;
  final position = _videoPlayerController.value.position;
  
  // 更新相关 UI
  if (mounted) {
    setState(() {
      _isPlaying = isPlaying;
      _currentPosition = position;
    });
  }
}
```

## 代码组织建议

### 控制器管理

```dart
class VideoControllerManager {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  
  Future<void> initialize(String url) async {
    await _controller?.dispose();
    _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await _controller!.initialize();
    
    await _chewieController?.dispose();
    _chewieController = ChewieController(
      videoPlayerController: _controller!,
      autoPlay: true,
    );
  }
  
  Future<void> switchVideo(String newUrl) async {
    await initialize(newUrl);
  }
  
  void dispose() {
    _chewieController?.dispose();
    _controller?.dispose();
  }
}
```

### 配置分离

```dart
class VideoConfig {
  static const bool autoPlay = true;
  static const bool looping = false;
  static const bool allowFullScreen = true;
  static const Duration bufferDelay = Duration(milliseconds: 300);
  
  static ChewieController createController(
    VideoPlayerController playerController,
  ) {
    return ChewieController(
      videoPlayerController: playerController,
      autoPlay: autoPlay,
      looping: looping,
      allowFullScreen: allowFullScreen,
      progressIndicatorDelay: bufferDelay,
    );
  }
}
```

## 测试建议

### 单元测试

```dart
void main() {
  group('VideoPlayer Tests', () {
    test('初始化播放器', () async {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse('https://test.com/video.mp4'),
      );
      
      await controller.initialize();
      expect(controller.value.isInitialized, true);
      
      await controller.dispose();
    });
  });
}
```

### 集成测试

```dart
void main() {
  testWidgets('播放器可以正常显示', (tester) async {
    await tester.pumpWidget(MyApp());
    
    expect(find.byType(Chewie), findsOneWidget);
    
    // 测试播放功能
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    
    expect(find.byIcon(Icons.pause), findsOneWidget);
  });
}
```

## 常见问题解决

### 视频播放黑屏

```dart
// 确保正确初始化
_chewieController = ChewieController(
  videoPlayerController: _videoPlayerController,
  autoPlay: false,  // 不要自动播放
  autoInitialize: true,  // 自动初始化
);
```

### 内存占用过高

```dart
// 及时释放资源
@override
void dispose() {
  _chewieController?.dispose();
  _videoPlayerController.dispose();
  super.dispose();
}

// 切换视频时先释放旧的
Future<void> switchVideo(String url) async {
  await _chewieController?.dispose();
  await _videoPlayerController.dispose();
  
  await initializePlayer(url);
}
```

### 播放卡顿

```dart
// 优化视频源
final controller = VideoPlayerController.networkUrl(
  Uri.parse(videoUrl),
  httpHeaders: {'Range': 'bytes=0-'},
);

// 调整缓冲设置
_chewieController = ChewieController(
  videoPlayerController: controller,
  progressIndicatorDelay: Duration(milliseconds: 500),
);
```

## 总结

遵循这些最佳实践,你将能够:

1. **避免内存泄漏**: 正确管理资源生命周期
2. **提升用户体验**: 合理的加载和错误处理
3. **优化应用性能**: 预加载和高效的资源管理
4. **编写可维护代码**: 清晰的代码组织

结合前面章节的知识,你现在应该能够优雅地使用 Chewie 和 video_player 构建功能强大的视频播放应用了!

## 返回目录

- [教程索引](./README.md)
