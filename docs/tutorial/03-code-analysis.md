# 第 3 章:代码逐段解析

## 概述

本章将详细分析 `example/lib/app/app.dart` 中的代码,逐段讲解每个重要功能模块的实现。

## 状态管理部分

首先来看状态的声明和管理:

```dart 17:22:example/lib/app/app.dart
class _ChewieDemoState extends State<ChewieDemo> {
  TargetPlatform? _platform;
  late VideoPlayerController _videoPlayerController1;
  late VideoPlayerController _videoPlayerController2;
  ChewieController? _chewieController;
  int? bufferDelay;
```

### 变量说明

- `_platform`: 当前使用的平台控件风格(iOS/Android/Desktop)
- `_videoPlayerController1/2`: 两个视频控制器,支持切换视频源
- `_chewieController`: Chewie 控制器,管理整个播放器 UI
- `bufferDelay`: 进度指示器的延迟时间

### 视频源列表

```dart 38:42:example/lib/app/app.dart
  List<String> srcs = [
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
  ];
```

定义了多个测试视频 URL。

## 初始化流程

### initializePlayer 方法

这是核心初始化方法:

```dart 44:57:example/lib/app/app.dart
  Future<void> initializePlayer() async {
    _videoPlayerController1 = VideoPlayerController.networkUrl(
      Uri.parse(srcs[currPlayIndex]),
    );
    _videoPlayerController2 = VideoPlayerController.networkUrl(
      Uri.parse(srcs[currPlayIndex]),
    );
    await Future.wait([
      _videoPlayerController1.initialize(),
      _videoPlayerController2.initialize(),
    ]);
    _createChewieController();
    setState(() {});
  }
```

**关键点解析:**

1. **并行初始化**: 使用 `Future.wait()` 同时初始化两个控制器,提高效率
2. **网络地址**: 使用 `VideoPlayerController.networkUrl()` 播放网络视频
3. **视频源选择**: 通过 `currPlayIndex` 变量切换不同的视频
4. **状态更新**: 初始化完成后调用 `setState()` 刷新 UI

## ChewieController 配置

### _createChewieController 方法

这是最重要的配置方法,包含了大量的功能示例:

```dart 59:155:example/lib/app/app.dart
  void _createChewieController() {
    // final subtitles = [
    //     Subtitle(
    //       index: 0,
    //       start: Duration.zero,
    //       end: const Duration(seconds: 10),
    //       text: 'Hello from subtitles',
    //     ),
    //     Subtitle(
    //       index: 0,
    //       start: const Duration(seconds: 10),
    //       end: const Duration(seconds: 20),
    //       text: 'Whats up? :)',
    //     ),
    //   ];

    final subtitles = [
      Subtitle(
        index: 0,
        start: Duration.zero,
        end: const Duration(seconds: 10),
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'Hello',
              style: TextStyle(color: Colors.red, fontSize: 22),
            ),
            TextSpan(
              text: ' from ',
              style: TextStyle(color: Colors.green, fontSize: 20),
            ),
            TextSpan(
              text: 'subtitles',
              style: TextStyle(color: Colors.blue, fontSize: 18),
            ),
          ],
        ),
      ),
      Subtitle(
        index: 0,
        start: const Duration(seconds: 10),
        end: const Duration(seconds: 20),
        text: 'Whats up? :)',
        // text: const TextSpan(
        //   text: 'Whats up? :)',
        //   style: TextStyle(color: Colors.amber, fontSize: 22, fontStyle: FontStyle.italic),
        // ),
      ),
    ];

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController1,
      autoPlay: true,
      zoomAndPan: true,
      looping: true,
      progressIndicatorDelay: bufferDelay != null
          ? Duration(milliseconds: bufferDelay!)
          : null,

      additionalOptions: (context) {
        return <OptionItem>[
          OptionItem(
            onTap: (context) => toggleVideo(),
            iconData: Icons.live_tv_sharp,
            title: 'Toggle Video Src',
          ),
        ];
      },
      subtitle: Subtitles(subtitles),
      showSubtitles: true,
      subtitleBuilder: (context, dynamic subtitle) => Container(
        padding: const EdgeInsets.all(10.0),
        child: subtitle is InlineSpan
            ? RichText(text: subtitle)
            : Text(
                subtitle.toString(),
                style: const TextStyle(color: Colors.black),
              ),
      ),

      hideControlsTimer: const Duration(seconds: 1),

      // Try playing around with some of these other options:

      // showControls: false,
      // materialProgressColors: ChewieProgressColors(
      //   playedColor: Colors.red,
      //   handleColor: Colors.blue,
      //   backgroundColor: Colors.grey,
      //   bufferedColor: Colors.lightGreen,
      // ),
      // placeholder: Container(
      //   color: Colors.grey,
      // ),
      // autoInitialize: true,
    );
  }
```

### 配置项详细说明

#### 基础配置

- `videoPlayerController`: 绑定的视频控制器
- `autoPlay: true`: 自动开始播放
- `looping: true`: 循环播放
- `zoomAndPan: true`: 支持缩放和平移手势

#### 字幕系统

本示例展示了两种字幕格式:

1. **简单文本字幕** (第 75-80 行):
   - 使用 `text` 参数传入字符串

2. **富文本字幕** (第 80-95 行):
   - 使用 `TextSpan` 创建多行富文本
   - 每行可以设置不同的颜色和字体大小
   - 实现更丰富的视觉效果

3. **自定义字幕渲染** (第 129-137 行):
   - `subtitleBuilder` 允许完全自定义字幕显示样式
   - 支持判断字幕类型(文本/富文本)
   - 使用 `RichText` 渲染富文本内容

#### 自定义选项菜单

```dart 118:126:example/lib/app/app.dart
      additionalOptions: (context) {
        return <OptionItem>[
          OptionItem(
            onTap: (context) => toggleVideo(),
            iconData: Icons.live_tv_sharp,
            title: 'Toggle Video Src',
          ),
        ];
      },
```

- `additionalOptions`: 添加自定义菜单项
- 可以添加多个 `OptionItem`
- 每个选项包含图标、标题和点击事件

## 视频切换功能

### toggleVideo 方法

```dart 159:166:example/lib/app/app.dart
  Future<void> toggleVideo() async {
    await _videoPlayerController1.pause();
    currPlayIndex += 1;
    if (currPlayIndex >= srcs.length) {
      currPlayIndex = 0;
    }
    await initializePlayer();
  }
```

**实现逻辑:**

1. 暂停当前播放
2. 切换到下一个视频索引(循环)
3. 重新初始化播放器

## UI 构建部分

### 主界面结构

```dart 169:328:example/lib/app/app.dart
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.title,
      theme: AppTheme.light.copyWith(
        platform: _platform ?? Theme.of(context).platform,
      ),
      home: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child:
                    _chewieController != null &&
                        _chewieController!
                            .videoPlayerController
                            .value
                            .isInitialized
                    ? Chewie(controller: _chewieController!)
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 20),
                          Text('Loading'),
                        ],
                      ),
              ),
            ),
            TextButton(
              onPressed: () {
                _chewieController?.enterFullScreen();
              },
              child: const Text('Fullscreen'),
            ),
            // ... 更多按钮
```

### 关键 UI 组件

#### 1. 加载状态判断

```dart 182:195:example/lib/app/app.dart
                    _chewieController != null &&
                        _chewieController!
                            .videoPlayerController
                            .value
                            .isInitialized
                    ? Chewie(controller: _chewieController!)
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 20),
                          Text('Loading'),
                        ],
                      ),
```

- 同时检查控制器和初始化状态
- 未就绪时显示加载指示器

#### 2. 全屏控制

```dart 198:203:example/lib/app/app.dart
            TextButton(
              onPressed: () {
                _chewieController?.enterFullScreen();
              },
              child: const Text('Fullscreen'),
            ),
```

- 编程方式进入全屏
- 使用安全调用操作符 `?.`

#### 3. 视频切换按钮

```dart 204:262:example/lib/app/app.dart
            Row(
              children: <Widget>[
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _videoPlayerController1.pause();
                        _videoPlayerController1.seekTo(Duration.zero);
                        _createChewieController();
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text("Landscape Video"),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _videoPlayerController2.pause();
                        _videoPlayerController2.seekTo(Duration.zero);
                        _chewieController = _chewieController!.copyWith(
                          videoPlayerController: _videoPlayerController2,
                          autoPlay: true,
                          looping: true,
                          /* subtitle: Subtitles([
                            Subtitle(
                              index: 0,
                              start: Duration.zero,
                              end: const Duration(seconds: 10),
                              text: 'Hello from subtitles',
                            ),
                            Subtitle(
                              index: 0,
                              start: const Duration(seconds: 10),
                              end: const Duration(seconds: 20),
                              text: 'Whats up? :)',
                            ),
                          ]),
                          subtitleBuilder: (context, subtitle) => Container(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              subtitle,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ), */
                        );
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text("Portrait Video"),
                    ),
                  ),
                ),
              ],
            ),
```

展示了两种切换方式:

- **方式 1**: 重新创建控制器
- **方式 2**: 使用 `copyWith()` 修改现有控制器

#### 4. 平台控件切换

```dart 263:292:example/lib/app/app.dart
            Row(
              children: <Widget>[
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _platform = TargetPlatform.android;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text("Android controls"),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _platform = TargetPlatform.iOS;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text("iOS controls"),
                    ),
                  ),
                ),
              ],
            ),
```

动态切换控件风格,适配不同平台设计规范。

#### 5. 进度指示器延迟配置

```dart 293:323:example/lib/app/app.dart
            Row(
              children: <Widget>[
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _platform = TargetPlatform.windows;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text("Desktop controls"),
                    ),
                  ),
                ),
              ],
            ),
            if (Theme.of(context).platform == TargetPlatform.android)
              ListTile(
                title: const Text("Delay"),
                subtitle: DelaySlider(
                  delay:
                      _chewieController?.progressIndicatorDelay?.inMilliseconds,
                  onSave: (delay) async {
                    if (delay != null) {
                      bufferDelay = delay == 0 ? null : delay;
                      await initializePlayer();
                    }
                  },
                ),
              ),
```

通过滑块调整缓冲指示器延迟,优化用户体验。

## DelaySlider 组件

自定义的延迟设置组件:

```dart 331:379:example/lib/app/app.dart
class DelaySlider extends StatefulWidget {
  const DelaySlider({super.key, required this.delay, required this.onSave});

  final int? delay;
  final void Function(int?) onSave;
  @override
  State<DelaySlider> createState() => _DelaySliderState();
}

class _DelaySliderState extends State<DelaySlider> {
  int? delay;
  bool saved = false;

  @override
  void initState() {
    super.initState();
    delay = widget.delay;
  }

  @override
  Widget build(BuildContext context) {
    const int max = 1000;
    return ListTile(
      title: Text(
        "Progress indicator delay ${delay != null ? "${delay.toString()} MS" : ""}",
      ),
      subtitle: Slider(
        value: delay != null ? (delay! / max) : 0,
        onChanged: (value) async {
          delay = (value * max).toInt();
          setState(() {
            saved = false;
          });
        },
      ),
      trailing: IconButton(
        icon: const Icon(Icons.save),
        onPressed: saved
            ? null
            : () {
                widget.onSave(delay);
                setState(() {
                  saved = true;
                });
              },
      ),
    );
  }
}
```

这是一个独立的功能组件,展示了如何实现一个带有保存功能的滑块。

## 下一步

现在你已经理解了代码的各个部分,接下来我们将深入探索 Chewie 的各种强大功能。请继续阅读 [第 4 章:功能特性详解](./04-features.md)
