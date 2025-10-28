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

  // 视频播放器控制器，管理视频播放状态和位置
  VideoPlayerController? _videoPlayerController;

  // Chewie 控制器，管理播放 UI 和控制
  ChewieController? _chewieController;

  // 手动跳转标志，防止位置监听器在用户拖动时自动纠正位置
  bool _isManualSeeking = false;

  // 视频切换中标志，防止切换过程中的重复触发和冲突
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
    // 初始化为空列表，用户可以通过添加按钮添加视频
    playlistVideos.value = [];
  }

  /// 添加视频到播放列表
  ///
  /// [urls] 视频 URL 列表
  Future<void> addVideos(List<String> urls) async {
    if (urls.isEmpty) return;

    final newVideos = <PlaylistVideo>[];
    for (final url in urls) {
      // 创建新的 PlaylistVideo 对象，初始时没有播放区间
      final video = PlaylistVideo(url: url);
      newVideos.add(video);
    }

    // 判断是否是第一次添加视频
    final wasEmpty = playlistVideos.isEmpty;

    // 将新视频添加到列表末尾
    playlistVideos.addAll(newVideos);

    // 更新视频循环链表，最后一个视频指向第一个，实现无缝循环播放
    if (playlistVideos.isNotEmpty) {
      for (int i = 0; i < playlistVideos.length; i++) {
        playlistVideos[i].nextVideo =
            playlistVideos[(i + 1) % playlistVideos.length];
      }
    }

    // 如果是第一次添加视频（列表之前为空），自动初始化播放第一个视频
    if (wasEmpty && playlistVideos.isNotEmpty) {
      final firstVideo = playlistVideos.first;
      await _switchToVideo(firstVideo);
    }
  }

  /// 清理旧的播放器资源
  Future<void> _disposeOldPlayer() async {
    // 重置状态标志，避免新旧播放器状态干扰
    _isSwitchingVideo = false;
    _isManualSeeking = false;
    _videoPlayerController?.removeListener(_onPositionChanged);

    // 移除监听器，防止内存泄漏
    _videoPlayerController?.removeListener(_updateInitializedState);

    // 先释放 VideoPlayerController，再释放 ChewieController，避免依赖冲突
    await _videoPlayerController?.dispose();
    _videoPlayerController = null;

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
      // 禁用自动循环，由 segment 逻辑控制播放
      startAt: video.currentPlayingSegment.value?.start,
      hideControlsTimer: const Duration(seconds: 600),
      // 设置长时间隐藏控制栏，避免 segment 播放期间自动隐藏控制条
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
    // 跳过手动跳转和视频切换期间的位置监听，避免逻辑冲突
    if (_isManualSeeking || _isSwitchingVideo) return;

    final video = currentPlayingVideo.value;
    if (video == null || video.segments.isEmpty) {
      return;
    }

    final position = _videoPlayerController!.value.position;
    final currentSegment = video.currentPlayingSegment.value;
    if (currentSegment == null) return;

    // 播放超出当前区间结束时间，自动跳转到下一个区间或视频
    if (position > currentSegment.end) {
      final nextSegment = currentSegment.nextSegment;
      final isLastSegment = currentSegment == video.segments.last;

      if (isLastSegment) {
        // 最后一个区间播放完毕，暂停并切换到下一个视频
        _isSwitchingVideo = true;
        _videoPlayerController!.pause();
        video.reset();
        final nextVideo = video.nextVideo;

        // 使用 microtask 异步执行，确保当前监听器回调完成，避免状态不一致
        Future.microtask(() async {
          await _switchToVideo(nextVideo);
          _isSwitchingVideo = false;
        });
      } else {
        // 还有后续区间，跳转到下一个区间的起始位置
        video.setPlayingSegment(nextSegment);
        _videoPlayerController!.seekTo(nextSegment.start);
      }
    }
    // 位置在区间开始之前，自动调整到区间起始位置
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

    // 设置手动跳转标志，阻止位置监听器在跳转过程中自动调整位置
    _isManualSeeking = true;

    await _videoPlayerController!.seekTo(segment.start);

    // 延迟 500ms 重置标志，确保 seek 操作完成且位置稳定
    Future.delayed(const Duration(milliseconds: 500), () {
      _isManualSeeking = false;
    });
  }

  /// 切换到指定视频（初始化和切换的统一入口）
  ///
  /// [newVideo] 要切换到的视频
  Future<void> _switchToVideo(PlaylistVideo newVideo) async {
    // 重置当前视频状态，释放旧的 segment 引用
    currentPlayingVideo.value?.reset();
    currentPlayingVideo.value = newVideo;

    // 先清理旧的播放器资源，避免内存泄漏和状态冲突
    await _disposeOldPlayer();

    // 创建并初始化新的播放器
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(newVideo.url),
    );
    await _videoPlayerController!.initialize();
    _chewieController = _createChewieController(
      videoPlayerController: _videoPlayerController!,
      video: newVideo,
    );

    // 添加初始化状态监听器
    _videoPlayerController!.addListener(_updateInitializedState);
    _updateInitializedState();

    // 确定播放起点：无区间从 0 秒开始，有区间从指定 segment 开始
    if (newVideo.segments.isEmpty) {
      await _videoPlayerController!.seekTo(Duration.zero);
    } else {
      // 未指定区间时默认使用第一个区间
      if (newVideo.currentPlayingSegment.value == null) {
        newVideo.setPlayingSegment(newVideo.segments.first);
      }
      await _videoPlayerController!.seekTo(
        newVideo.currentPlayingSegment.value!.start,
      );
    }

    // 最后添加位置监听器，避免初始化期间的干扰
    _videoPlayerController!.addListener(_onPositionChanged);
  }

  /// 处理区间点击
  void onSegmentTapped(PlaybackSegment segment) async {
    final video = segment.parentVideo;
    final currentVideo = currentPlayingVideo.value;

    // 判断是不同视频需要切换，还是同一视频只需跳转区间
    if (currentVideo != video) {
      // 不同视频：设置目标 segment 并切换到新视频
      video.setPlayingSegment(segment);
      await _switchToVideo(video);
    } else {
      // 同一视频：仅跳转到指定区间，无需重新初始化播放器
      await _jumpToSegment(segment);
    }
  }

  /// 处理视频项点击（无区间时直接播放）
  void onVideoTapped(PlaylistVideo video) async {
    if (video.segments.isEmpty) {
      // 没有播放区间，直接切换播放该视频
      await _switchToVideo(video);
    }
  }

  @override
  void onClose() {
    _disposeOldPlayer();
    super.onClose();
  }
}
