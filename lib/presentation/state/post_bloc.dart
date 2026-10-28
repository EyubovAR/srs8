import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import 'post_event.dart';
import 'post_state.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  final PostRepository repository;
  static const int _limit = 10;

  PostBloc({required this.repository}) : super(const PostState()) {
    on<LoadPostsEvent>(_onLoadPosts);
    on<LoadMorePostsEvent>(_onLoadMorePosts);
    on<FilterByUserEvent>(_onFilterByUser);
    on<SearchPostsEvent>(_onSearchPosts);
    on<SortPostsEvent>(_onSortPosts);
    on<AddCreatedPostEvent>(_onAddCreatedPost);
  }

  Future<void> _onLoadPosts(LoadPostsEvent event, Emitter<PostState> emit) async {
    // 1. Сначала проверяем и показываем кэш, если это не ручной рефреш
    if (!event.isRefresh) {
      final cachedPosts = await repository.getCachedPosts();
      if (cachedPosts.isNotEmpty) {
        emit(state.copyWith(
          status: PostStatus.cached,
          posts: cachedPosts,
          filteredPosts: _applyFilters(cachedPosts, state.searchQuery, state.isAscending),
          currentPage: 1,
          hasReachedMax: false,
        ));
      } else {
        emit(state.copyWith(status: PostStatus.loading));
      }
    }

    try {
      final result = await repository.getPosts(
        page: 1,
        limit: _limit,
        userId: state.selectedUserId,
      );

      final posts = result.posts;
      final status = result.isFromCache ? PostStatus.cached : PostStatus.success;

      emit(state.copyWith(
        status: status,
        posts: posts,
        filteredPosts: _applyFilters(posts, state.searchQuery, state.isAscending),
        currentPage: 1,
        hasReachedMax: posts.length < _limit,
      ));
    } catch (e) {
      // Если уже есть посты из кэша — не затираем их ошибкой полностью
      if (state.posts.isEmpty) {
        emit(state.copyWith(
          status: PostStatus.error,
          errorMessage: e.toString(),
        ));
      }
    }
  }

  Future<void> _onLoadMorePosts(LoadMorePostsEvent event, Emitter<PostState> emit) async {
    // Защита от дублирования подгрузки и превышения страниц
    if (state.isLoadingMore || state.hasReachedMax) return;

    emit(state.copyWith(isLoadingMore: true));

    final nextPage = state.currentPage + 1;

    try {
      final result = await repository.getPosts(
        page: nextPage,
        limit: _limit,
        userId: state.selectedUserId,
      );

      final newPosts = result.posts;
      final updatedPosts = List<Post>.from(state.posts)..addAll(newPosts);

      emit(state.copyWith(
        posts: updatedPosts,
        filteredPosts: _applyFilters(updatedPosts, state.searchQuery, state.isAscending),
        currentPage: nextPage,
        hasReachedMax: newPosts.length < _limit,
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  void _onFilterByUser(FilterByUserEvent event, Emitter<PostState> emit) {
    emit(state.copyWith(
      selectedUserId: event.userId,
      clearSelectedUserId: event.userId == null,
      currentPage: 1,
      hasReachedMax: false,
      posts: [],
      filteredPosts: [],
      status: PostStatus.loading,
    ));
    add(LoadPostsEvent(isRefresh: true));
  }

  void _onSearchPosts(SearchPostsEvent event, Emitter<PostState> emit) {
    final query = event.query;
    final filtered = _applyFilters(state.posts, query, state.isAscending);
    emit(state.copyWith(
      searchQuery: query,
      filteredPosts: filtered,
    ));
  }

  void _onSortPosts(SortPostsEvent event, Emitter<PostState> emit) {
    final sorted = _applyFilters(state.posts, state.searchQuery, event.ascending);
    emit(state.copyWith(
      isAscending: event.ascending,
      filteredPosts: sorted,
    ));
  }

  void _onAddCreatedPost(AddCreatedPostEvent event, Emitter<PostState> emit) {
    if (event.post is Post) {
      final updatedPosts = [event.post as Post, ...state.posts];
      emit(state.copyWith(
        posts: updatedPosts,
        filteredPosts: _applyFilters(updatedPosts, state.searchQuery, state.isAscending),
      ));
    }
  }

  List<Post> _applyFilters(List<Post> list, String query, bool isAscending) {
    var result = List<Post>.from(list);
    if (query.trim().isNotEmpty) {
      result = result
          .where((p) => p.title.toLowerCase().contains(query.trim().toLowerCase()))
          .toList();
    }
    result.sort((a, b) {
      final idA = a.id ?? 0;
      final idB = b.id ?? 0;
      return isAscending ? idA.compareTo(idB) : idB.compareTo(idA);
    });
    return result;
  }
}