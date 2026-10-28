import 'package:dio/dio.dart';
import '../../core/error/app_exception.dart';
import '../local/post_cache.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../remote/post_api.dart';

class FetchPostsResult {
  final List<Post> posts;
  final bool isFromCache;

  FetchPostsResult({
    required this.posts,
    required this.isFromCache,
  });
}

class PostRepository {
  final PostApi api;
  final PostCache cache;

  PostRepository({
    required this.api,
    required this.cache,
  });

  // Получение сохранённого кэша для мгновенного отображения
  Future<List<Post>> getCachedPosts() async {
    return await cache.getCachedPosts();
  }

  // Загрузка постов с пагинацией и фильтрацией
  Future<FetchPostsResult> getPosts({
    required int page,
    required int limit,
    int? userId,
  }) async {
    try {
      List<Post> serverPosts;
      if (userId != null) {
        serverPosts = await api.getPostsByUserId(userId, page, limit);
      } else {
        serverPosts = await api.getPosts(page, limit);
      }

      // Если это первая страница без фильтра — обновляем локальный кэш
      if (page == 1 && userId == null) {
        await cache.savePosts(serverPosts);
      }

      return FetchPostsResult(posts: serverPosts, isFromCache: false);
    } on DioException catch (e) {
      // При сетевой ошибке на первой странице пробуем вернуть кэш
      if (page == 1 && userId == null) {
        final cached = await cache.getCachedPosts();
        if (cached.isNotEmpty) {
          return FetchPostsResult(posts: cached, isFromCache: true);
        }
      }

      if (e.error is AppException) {
        throw e.error as AppException;
      }
      throw UnknownException(e.message ?? 'Сетевая ошибка');
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // Детали поста
  Future<Post> getPostDetails(int id) async {
    try {
      return await api.getPostById(id);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw UnknownException(e.message ?? 'Ошибка получения поста');
    }
  }

  // Комментарии к посту
  Future<List<Comment>> getComments(int postId) async {
    try {
      return await api.getCommentsByPostId(postId);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw UnknownException(e.message ?? 'Ошибка получения комментариев');
    }
  }

  // Список пользователей для выбора автора
  Future<List<User>> getUsers() async {
    try {
      return await api.getUsers();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw UnknownException(e.message ?? 'Ошибка получения пользователей');
    }
  }

  // Создание поста с отметкой локального создания
  Future<Post> createPost({
    required String title,
    required String body,
    required int userId,
  }) async {
    try {
      final payload = {
        'title': title,
        'body': body,
        'userId': userId,
      };
      final createdPost = await api.createPost(payload);
      return createdPost.copyWith(isLocallyCreated: true);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw UnknownException(e.message ?? 'Ошибка создания поста');
    }
  }
}