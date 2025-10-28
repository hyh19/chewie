import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

/// 添加播放区间 BottomSheet
///
/// 使用时间选择器让用户输入起始时间和结束时间
/// 支持编辑模式，传入初始值即可
class AddSegmentBottomSheet extends StatefulWidget {
  const AddSegmentBottomSheet({
    super.key,
    required this.maxDuration,
    this.initialStart,
    this.initialEnd,
  });

  // 视频最大时长，用于验证输入时间不超过总时长
  final Duration? maxDuration;
  // 初始起始时间（编辑模式）
  final Duration? initialStart;
  // 初始结束时间（编辑模式）
  final Duration? initialEnd;

  @override
  State<AddSegmentBottomSheet> createState() => _AddSegmentBottomSheetState();
}

class _AddSegmentBottomSheetState extends State<AddSegmentBottomSheet> {
  // 判断是否为编辑模式
  bool get _isEditMode =>
      widget.initialStart != null && widget.initialEnd != null;

  // 起始时间的分钟数
  late int _startMinutes;
  // 起始时间的秒数
  late int _startSeconds;
  // 结束时间的分钟数
  late int _endMinutes;
  // 结束时间的秒数
  late int _endSeconds;

  @override
  void initState() {
    super.initState();
    // 如果提供了初始值，使用初始值；否则使用默认值
    if (_isEditMode) {
      _startMinutes = widget.initialStart!.inMinutes.remainder(60);
      _startSeconds = widget.initialStart!.inSeconds.remainder(60);
      _endMinutes = widget.initialEnd!.inMinutes.remainder(60);
      _endSeconds = widget.initialEnd!.inSeconds.remainder(60);
    } else {
      _startMinutes = 0;
      _startSeconds = 0;
      _endMinutes = 0;
      _endSeconds = 30;
    }
  }

  /// 格式化时间为 Duration 对象
  Duration _getStartDuration() {
    return Duration(minutes: _startMinutes, seconds: _startSeconds);
  }

  /// 格式化时间为 Duration 对象
  Duration _getEndDuration() {
    return Duration(minutes: _endMinutes, seconds: _endSeconds);
  }

  /// 验证输入的区间是否有效
  String? _validateSegment() {
    final start = _getStartDuration();
    final end = _getEndDuration();

    // 验证起始时间小于结束时间
    if (start >= end) {
      return '起始时间必须小于结束时间';
    }

    // 如果有最大时长限制，验证不超过视频总时长
    if (widget.maxDuration != null) {
      if (end > widget.maxDuration!) {
        return '结束时间不能超过视频总时长 ${_formatDuration(widget.maxDuration!)}';
      }
    }

    return null;
  }

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

  /// 确认添加区间
  void _onConfirm() {
    final error = _validateSegment();
    if (error != null) {
      Get.snackbar('输入错误', error, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // 返回起始和结束时间
    Get.back(result: {'start': _getStartDuration(), 'end': _getEndDuration()});
  }

  /// 构建时间选择器
  Widget _buildTimePicker({
    required String label,
    required int minutes,
    required int seconds,
    required ValueChanged<int> onMinutesChanged,
    required ValueChanged<int> onSecondsChanged,
    int maxMinutes = 59,
    int maxSeconds = 59,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            // 分钟选择器
            Expanded(
              child: SizedBox(
                height: 150,
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: minutes.clamp(0, maxMinutes),
                  ),
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    onMinutesChanged(index);
                  },
                  children: List.generate(
                    maxMinutes + 1,
                    (index) => Center(
                      child: Text(
                        '${index.toString().padLeft(2, '0')} 分',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 秒数选择器
            Expanded(
              child: SizedBox(
                height: 150,
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: seconds.clamp(0, maxSeconds),
                  ),
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    onSecondsChanged(index);
                  },
                  children: List.generate(
                    maxSeconds + 1,
                    (index) => Center(
                      child: Text(
                        '${index.toString().padLeft(2, '0')} 秒',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 显示选择的时间
        Text(
          '已选择：${_formatDuration(Duration(minutes: minutes, seconds: seconds))}',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 计算最大分钟限制
    final maxMinutes = widget.maxDuration != null
        ? widget.maxDuration!.inMinutes
        : 59;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditMode ? '编辑播放区间' : '添加播放区间',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 起始时间选择器
            _buildTimePicker(
              label: '起始时间',
              minutes: _startMinutes,
              seconds: _startSeconds,
              onMinutesChanged: (value) {
                setState(() {
                  _startMinutes = value.clamp(0, maxMinutes);
                });
              },
              onSecondsChanged: (value) {
                setState(() {
                  _startSeconds = value.clamp(0, 59);
                });
              },
              maxMinutes: maxMinutes,
            ),
            const SizedBox(height: 24),
            // 结束时间选择器
            _buildTimePicker(
              label: '结束时间',
              minutes: _endMinutes,
              seconds: _endSeconds,
              onMinutesChanged: (value) {
                setState(() {
                  _endMinutes = value.clamp(0, maxMinutes);
                });
              },
              onSecondsChanged: (value) {
                setState(() {
                  _endSeconds = value.clamp(0, 59);
                });
              },
              maxMinutes: maxMinutes,
            ),
            const SizedBox(height: 16),
            // 按钮区域
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _onConfirm, child: const Text('确定')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
