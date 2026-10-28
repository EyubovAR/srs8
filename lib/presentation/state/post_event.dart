abstract class PostEvent {}

class LoadPostsEvent extends PostEvent {
  final bool isRefresh;
  LoadPostsEvent({this.isRefresh = false});
}

class LoadMorePostsEvent extends PostEvent {}

class FilterByUserEvent extends PostEvent {
  final int? userId;
  FilterByUserEvent(this.userId);
}

class SearchPostsEvent extends PostEvent {
  final String query;
  SearchPostsEvent(this.query);
}

class SortPostsEvent extends PostEvent {
  final bool ascending;
  SortPostsEvent({required this.ascending});
}

class AddCreatedPostEvent extends PostEvent {
  final dynamic post;
  AddCreatedPostEvent(this.post);
}