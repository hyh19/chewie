import 'package:chewie/chewie.dart';
import 'package:chewie_example/models/playback_segment.dart';
import 'package:chewie_example/models/video_segment_config.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

/// 视频播放列表控制器
///
/// 管理视频播放列表的所有状态和逻辑
class VideoPlaylistController extends GetxController {
  // 播放列表中的视频列表
  final RxList<PlaylistVideo> playlistVideos = <PlaylistVideo>[].obs;

  // 当前播放的视频
  final Rx<PlaylistVideo?> currentPlayingVideo = Rx<PlaylistVideo?>(null);

  // 是否已初始化（响应式变量）
  final RxBool isInitialized = false.obs;

  // 视频播放器控制器
  VideoPlayerController? _videoPlayerController;

  // Chewie 控制器
  ChewieController? _chewieController;

  // 手动跳转标志（用于防止位置监听器干扰手动跳转）
  bool _isManualSeeking = false;

  // 视频切换中标志（防止重复触发）
  bool _isSwitchingVideo = false;

  // Getter: 获取 chewieController
  ChewieController? get chewieController => _chewieController;

  @override
  void onInit() {
    super.onInit();
    _initializePlaylistVideos();
  }

  /// 初始化播放列表视频
  void _initializePlaylistVideos() {
    final videos = <PlaylistVideo>[];

    // 创建第一个视频
    final video1 = PlaylistVideo(
      url: "http://192.168.31.174:3923/Downloads/VolkswagenGTIReview.mp4",
    );
    video1.addSegment(
      PlaybackSegment(
        start: const Duration(seconds: 15),
        end: const Duration(seconds: 30),
      ),
    );
    video1.addSegment(
      PlaybackSegment(
        start: const Duration(seconds: 45),
        end: const Duration(minutes: 1, seconds: 0),
      ),
    );
    video1.addSegment(
      PlaybackSegment(
        start: const Duration(minutes: 1, seconds: 15),
        end: const Duration(minutes: 1, seconds: 30),
      ),
    );
    videos.add(video1);

    // 创建第二个视频
    final video2 = PlaylistVideo(
      url: "http://192.168.31.174:3923/Downloads/TearsOfSteel.mp4",
    );
    video2.addSegment(
      PlaybackSegment(
        start: const Duration(seconds: 30),
        end: const Duration(seconds: 45),
      ),
    );
    video2.addSegment(
      PlaybackSegment(
        start: const Duration(minutes: 1, seconds: 0),
        end: const Duration(minutes: 1, seconds: 15),
      ),
    );
    video2.addSegment(
      PlaybackSegment(
        start: const Duration(minutes: 1, seconds: 30),
        end: const Duration(minutes: 1, seconds: 45),
      ),
    );
    videos.add(video2);

    // 创建第三个视频
    final video3 = PlaylistVideo(
      url: "http://192.168.31.174:3923/Downloads/Sintel.mp4",
    );
    video3.addSegment(
      PlaybackSegment(
        start: const Duration(seconds: 20),
        end: const Duration(seconds: 35),
      ),
    );
    video3.addSegment(
      PlaybackSegment(
        start: const Duration(seconds: 50),
        end: const Duration(minutes: 1, seconds: 5),
      ),
    );
    video3.addSegment(
      PlaybackSegment(
        start: const Duration(minutes: 1, seconds: 30),
        end: const Duration(minutes: 1, seconds: 45),
      ),
    );
    videos.add(video3);

    // 建立播放列表视频之间的循环链表
    for (int i = 0; i < videos.length; i++) {
      videos[i].nextVideo = videos[(i + 1) % videos.length];
    }

    // 为每个视频建立 segment 循环链表
    for (final video in videos) {
      video.linkSegments();
    }

    playlistVideos.value = videos;
  }

  /// 清理旧的播放器资源
  Future<void> _disposeOldPlayer() async {
    _isSwitchingVideo = false; // 重置切换标志
    _isManualSeeking = false; // 重置手动跳转标志
    _videoPlayerController?.removeListener(_onPositionChanged);

    // 移除监听器
    _videoPlayerController?.removeListener(_updateInitializedState);

    // 先释放视频播放器控制器
    await _videoPlayerController?.dispose();
    _videoPlayerController = null;

    // 再释放 Chewie 控制器
    _chewieController?.dispose();
    _chewieController = null;

    // 更新初始化状态
    isInitialized.value = false;
  }

  /// 创建 Chewie 控制器
  ChewieController _createChewieController({
    required VideoPlayerController videoPlayerController,
    required PlaylistVideo video,
  }) {
    return ChewieController(
      videoPlayerController: videoPlayerController,
      autoPlay: true,
      zoomAndPan: true,
      looping: false,
      // Disable looping for segment playback
      startAt: video.currentPlayingSegment.value?.start,
      hideControlsTimer: const Duration(seconds: 600),
    );
  }

  /// 更新初始化状态
  void _updateInitializedState() {
    isInitialized.value =
        _chewieController != null &&
        _videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized;
  }

  /// 监听播放位置变化
  void _onPositionChanged() {
    // 如果正在手动跳转或正在切换视频，则不进行自动纠正
    if (_isManualSeeking || _isSwitchingVideo) return;

    final video = currentPlayingVideo.value;
    if (video == null || video.segments.isEmpty) {
      return;
    }

    final position = _videoPlayerController!.value.position;
    final currentSegment = video.currentPlayingSegment.value;
    if (currentSegment == null) return;

    // 超出当前区间结束时间
    if (position > currentSegment.end) {
      // 使用循环链表直接获取下一个区间
      final nextSegment = currentSegment.nextSegment;

      // 检查当前区间是否是最后一个区间
      final isLastSegment = currentSegment == video.segments.last;

      if (isLastSegment) {
        // 所有区间播放完毕，切换到下一个视频
        _isSwitchingVideo = true;
        _videoPlayerController!.pause();
        video.reset();
        final nextVideo = video.nextVideo;

        // 使用 Future.microtask 延迟执行，让当前监听器回调先完成
        Future.microtask(() async {
          await _switchToVideo(nextVideo);
          _isSwitchingVideo = false;
        });
      } else {
        // 还有后续区间，跳转到下一个区间
        video.setPlayingSegment(nextSegment);
        _videoPlayerController!.seekTo(nextSegment.start);
      }
    }
    // 用户拖动到区间之前
    else if (position < currentSegment.start) {
      _videoPlayerController!.seekTo(currentSegment.start);
    }
  }

  /// 跳转到指定区间
  ///
  /// [segment] 要跳转到的区间
  Future<void> _jumpToSegment(PlaybackSegment segment) async {
    final video = segment.parentVideo;
    video.setPlayingSegment(segment);

    // 设置手动跳转标志，防止位置监听器干扰
    _isManualSeeking = true;

    // 执行跳转操作
    await _videoPlayerController!.seekTo(segment.start);

    // 等待跳转完成后重置标志（500ms 延迟确保 seek 操作完成并稳定）
    Future.delayed(const Duration(milliseconds: 500), () {
      _isManualSeeking = false;
    });
  }

  /// 切换到指定视频（初始化和切换的统一入口）
  ///
  /// [newVideo] 要切换到的视频
  Future<void> _switchToVideo(PlaylistVideo newVideo) async {
    // 重置当前视频状态(如果存在)
    currentPlayingVideo.value?.reset();
    // 赋值新视频
    currentPlayingVideo.value = newVideo;

    // 在初始化新播放器前，先清理旧的播放器资源
    await _disposeOldPlayer();

    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(newVideo.url),
    );
    await _videoPlayerController!.initialize();
    _chewieController = _createChewieController(
      videoPlayerController: _videoPlayerController!,
      video: newVideo,
    );

    // 监听视频播放器初始化状态
    _videoPlayerController!.addListener(_updateInitializedState);
    _updateInitializedState();

    // 根据是否有区间来确定播放起点
    if (newVideo.segments.isEmpty) {
      // 没有区间，从 0 秒开始播放
      await _videoPlayerController!.seekTo(Duration.zero);
    } else {
      // 有区间，确定初始区间
      if (newVideo.currentPlayingSegment.value == null) {
        // 未指定初始区间，使用第一个区间
        newVideo.setPlayingSegment(newVideo.segments.first);
      }
      // 跳转到区间起始位置
      await _videoPlayerController!.seekTo(
        newVideo.currentPlayingSegment.value!.start,
      );
    }

    _videoPlayerController!.addListener(_onPositionChanged);
  }

  /// 处理区间点击
  void onSegmentTapped(PlaybackSegment segment) async {
    final video = segment.parentVideo;
    final currentVideo = currentPlayingVideo.value;

    // 直接比较视频是否相等（包括 null 情况）
    if (currentVideo != video) {
      // 不相等：切换新视频
      video.setPlayingSegment(segment);
      await _switchToVideo(video);
    } else {
      // 相等：同一视频，直接跳转到指定区间
      await _jumpToSegment(segment);
    }
  }

  @override
  void onClose() {
    _disposeOldPlayer();
    super.onClose();
  }
}
