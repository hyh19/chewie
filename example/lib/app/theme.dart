import 'package:flutter/material.dart';

/// 应用主题配置类，提供浅色和深色主题
// ignore: avoid_classes_with_only_static_members
class AppTheme {
  // 浅色主题配置
  static final light = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    // 使用红色作为次要颜色（如进度条）
    colorScheme: const ColorScheme.light(secondary: Colors.red),
    disabledColor: Colors.grey.shade400,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  // 深色主题配置（当前未使用，保留供未来扩展）
  static final dark = ThemeData(
    brightness: Brightness.dark,
    // 深色模式下的次要颜色
    colorScheme: const ColorScheme.dark(secondary: Colors.red),
    disabledColor: Colors.grey.shade400,
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
