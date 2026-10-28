import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/user.dart';

part 'post_api.g.dart';

@RestApi()
abstract class PostApi {
  factory PostApi(Dio dio, {String baseUrl}) = _PostApi;

  // 1. GET /posts с пагинацией (_page, _limit)
  @GET('/posts')
  Future<List<Post>> getPosts(
    @Query('_page') int page,
    @Query('_limit') int limit,
  );

  // 2. GET /posts/{id} детали поста
  @GET('/posts/{id}')
  Future<Post> getPostById(@Path('id') int id);

  // 3. GET /posts?userId={id} посты конкретного пользователя
  @GET('/posts')
  Future<List<Post>> getPostsByUserId(
    @Query('userId') int userId,
    @Query('_page') int page,
    @Query('_limit') int limit,
  );

  // 4. GET /posts/{id}/comments комментарии к посту
  @GET('/posts/{id}/comments')
  Future<List<Comment>> getCommentsByPostId(@Path('id') int postId);

  // 5. POST /posts создание поста
  @POST('/posts')
  Future<Post> createPost(@Body() Map<String, dynamic> body);

  // Дополнительно: получение списка пользователей для фильтра и создания постов
  @GET('/users')
  Future<List<User>> getUsers();
}