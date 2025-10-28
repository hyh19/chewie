import 'dart:convert';
import 'package:chewie_example/models/video_segment_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储服务，用于保存和加载播放列表数据
class StorageService {
  static const String _playlistKey = 'playlist_videos';

  /// 保存播放列表到本地存储
  ///
  /// [videos] 要保存的视频列表
  /// 返回保存是否成功
  static Future<bool> savePlaylist(List<PlaylistVideo> videos) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 将视频列表转换为 JSON
      final jsonList = videos.map((video) => video.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      // 保存到 SharedPreferences
      return await prefs.setString(_playlistKey, jsonString);
    } catch (e) {
      // 保存失败时返回 false
      return false;
    }
  }

  /// 从本地存储加载播放列表
  ///
  /// 返回加载的视频列表，如果加载失败或没有数据则返回空列表
  static Future<List<PlaylistVideo>> loadPlaylist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_playlistKey);

      // 如果没有保存的数据，返回空列表
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      // 解析 JSON 字符串
      final jsonList = jsonDecode(jsonString) as List<dynamic>;

      // 转换为 PlaylistVideo 列表
      final videos = jsonList
          .map((json) => PlaylistVideo.fromJson(json as Map<String, dynamic>))
          .toList();

      return videos;
    } catch (e) {
      // 解析失败时返回空列表
      return [];
    }
  }

  /// 清除本地存储的播放列表
  ///
  /// 返回清除是否成功
  static Future<bool> clearPlaylist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_playlistKey);
    } catch (e) {
      return false;
    }
  }
}
