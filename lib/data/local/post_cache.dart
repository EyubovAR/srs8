import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';

class PostCache {
  static const String _postsKey = 'cached_posts_list';

  Future<void> savePosts(List<Post> posts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = posts.map((post) => post.toJson()).toList();
    await prefs.setString(_postsKey, jsonEncode(jsonList));
  }

  Future<List<Post>> getCachedPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_postsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .map((item) => Post.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_postsKey);
  }
}