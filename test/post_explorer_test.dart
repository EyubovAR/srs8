import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:srs8/core/error/app_exception.dart';
import 'package:srs8/data/local/post_cache.dart';
import 'package:srs8/data/models/post.dart';
import 'package:srs8/data/remote/post_api.dart';
import 'package:srs8/data/repositories/post_repository.dart';

class MockPostCache extends Mock implements PostCache {}
class MockPostApi extends Mock implements PostApi {}

void main() {
  group('SRS 8: Тестирование Post Explorer', () {
    late MockPostCache mockCache;
    late MockPostApi mockApi;
    late PostRepository repository;

    setUp(() {
      mockCache = MockPostCache();
      mockApi = MockPostApi();
      repository = PostRepository(api: mockApi, cache: mockCache);
    });

    // 1. Преобразование JSON в Post
    test('1. Успешное преобразование JSON в объект Post', () {
      final jsonMap = {
        'id': 1,
        'userId': 10,
        'title': 'Тестовый заголовок',
        'body': 'Тестовое содержимое поста'
      };

      final post = Post.fromJson(jsonMap);

      expect(post.id, 1);
      expect(post.userId, 10);
      expect(post.title, 'Тестовый заголовок');
      expect(post.body, 'Тестовое содержимое поста');
      expect(post.isLocallyCreated, false);
    });

    // 2. Преобразование Post обратно в JSON
    test('2. Успешное преобразование Post обратно в JSON Map', () {
      const post = Post(
        id: 2,
        userId: 20,
        title: 'Заголовок 2',
        body: 'Текст 2',
      );

      final jsonMap = post.toJson();

      expect(jsonMap['id'], 2);
      expect(jsonMap['userId'], 20);
      expect(jsonMap['title'], 'Заголовок 2');
      expect(jsonMap['body'], 'Текст 2');
    });

    // 3. Успешная загрузка постов через репозиторий
    test('3. Успешная загрузка постов через репозиторий и сохранение в кэш', () async {
      final dummyPosts = [
        const Post(id: 1, userId: 1, title: 'Title 1', body: 'Body 1'),
        const Post(id: 2, userId: 1, title: 'Title 2', body: 'Body 2'),
      ];

      when(() => mockApi.getPosts(1, 10)).thenAnswer((_) async => dummyPosts);
      when(() => mockCache.savePosts(dummyPosts)).thenAnswer((_) async {});

      final result = await repository.getPosts(page: 1, limit: 10);

      expect(result.posts.length, 2);
      expect(result.isFromCache, false);
      verify(() => mockCache.savePosts(dummyPosts)).called(1);
    });

    // 4. Обработка ошибки сервера и fallback на кэш
    test('4. Обработка сетевой ошибки с возвратом данных из кэша', () async {
      final cachedPosts = [
        const Post(id: 1, userId: 1, title: 'Cached Title', body: 'Cached Body'),
      ];

      when(() => mockApi.getPosts(1, 10)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/posts'),
          type: DioExceptionType.connectionError,
          error: NetworkException(),
        ),
      );
      when(() => mockCache.getCachedPosts()).thenAnswer((_) async => cachedPosts);

      final result = await repository.getPosts(page: 1, limit: 10);

      expect(result.isFromCache, true);
      expect(result.posts.first.title, 'Cached Title');
    });

    // 5. Фильтрация списка постов по автору и по заголовку
    test('5. Фильтрация постов по userId и заголовку', () {
      final posts = [
        const Post(id: 1, userId: 1, title: 'Flutter Retrofit', body: 'A'),
        const Post(id: 2, userId: 2, title: 'Dart Language', body: 'B'),
        const Post(id: 3, userId: 1, title: 'Flutter BLoC', body: 'C'),
      ];

      final byUser = posts.where((p) => p.userId == 1).toList();
      expect(byUser.length, 2);

      final bySearch = posts
          .where((p) => p.title.toLowerCase().contains('bloc'))
          .toList();
      expect(bySearch.length, 1);
      expect(bySearch.first.id, 3);
    });

    // 6. Тестирование POST-запроса через MockAdapter Dio
    test('6. Отправка POST-запроса создания поста с MockAdapter', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'));
      final dioAdapter = DioAdapter(dio: dio);

      final postPayload = {
        'title': 'Новый пост о Flutter',
        'body': 'Тело нового поста для проверки',
        'userId': 1,
      };

      dioAdapter.onPost(
        '/posts',
        (server) => server.reply(201, {
          'id': 101,
          'title': 'Новый пост о Flutter',
          'body': 'Тело нового поста для проверки',
          'userId': 1,
        }),
        data: postPayload,
      );

      final testApi = PostApi(dio);
      final createdPost = await testApi.createPost(postPayload);

      expect(createdPost.id, 101);
      expect(createdPost.title, 'Новый пост о Flutter');
      expect(createdPost.userId, 1);
    });
  });
}