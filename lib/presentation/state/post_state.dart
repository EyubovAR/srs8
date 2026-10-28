import '../../data/models/post.dart';

enum PostStatus { initial, loading, success, cached, error }

class PostState {
  final PostStatus status;
  final List<Post> posts;
  final List<Post> filteredPosts;
  final String errorMessage;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final int? selectedUserId;
  final String searchQuery;
  final bool isAscending;

  const PostState({
    this.status = PostStatus.initial,
    this.posts = const [],
    this.filteredPosts = const [],
    this.errorMessage = '',
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.selectedUserId,
    this.searchQuery = '',
    this.isAscending = true,
  });

  bool get isEmpty =>
      (status == PostStatus.success || status == PostStatus.cached) &&
      filteredPosts.isEmpty;

  PostState copyWith({
    PostStatus? status,
    List<Post>? posts,
    List<Post>? filteredPosts,
    String? errorMessage,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoadingMore,
    int? selectedUserId,
    bool clearSelectedUserId = false,
    String? searchQuery,
    bool? isAscending,
  }) {
    return PostState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      filteredPosts: filteredPosts ?? this.filteredPosts,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectedUserId: clearSelectedUserId ? null : (selectedUserId ?? this.selectedUserId),
      searchQuery: searchQuery ?? this.searchQuery,
      isAscending: isAscending ?? this.isAscending,
    );
  }
}