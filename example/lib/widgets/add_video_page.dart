import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 添加视频 URL 输入 BottomSheet
///
/// 支持多行输入，每行一个视频 URL，解析后返回 URL 列表
class AddVideoBottomSheet extends StatefulWidget {
  const AddVideoBottomSheet({super.key});

  @override
  State<AddVideoBottomSheet> createState() => _AddVideoBottomSheetState();
}

class _AddVideoBottomSheetState extends State<AddVideoBottomSheet> {
  final TextEditingController _textController = TextEditingController();

  /// 解析输入的文本，提取有效的 URL
  List<String> _parseUrls(String text) {
    if (text.isEmpty) return [];

    // 按行分割
    final lines = text.split('\n');

    // 过滤空行和无效 URL
    final validUrls = <String>[];
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // 验证 URL 格式
      final uri = Uri.tryParse(trimmedLine);
      if (uri != null && (uri.hasScheme && uri.hasAuthority)) {
        validUrls.add(trimmedLine);
      }
    }

    return validUrls;
  }

  /// 确认添加视频
  void _onConfirm() {
    final urls = _parseUrls(_textController.text);
    if (urls.isEmpty) {
      // 如果没有有效的 URL，显示提示
      Get.snackbar(
        '提示',
        '请输入至少一个有效的视频 URL',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // 返回 URL 列表并关闭 BottomSheet
    Get.back(result: urls);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  '添加视频',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 提示文字
            Text(
              '请输入视频 URL，每行一个：',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            // 输入框
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
                minHeight: 200,
              ),
              child: TextField(
                controller: _textController,
                maxLines: null,
                minLines: 8,
                decoration: const InputDecoration(
                  hintText:
                      '例如：\nhttp://example.com/video1.mp4\nhttp://example.com/video2.mp4',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                textAlignVertical: TextAlignVertical.top,
              ),
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
