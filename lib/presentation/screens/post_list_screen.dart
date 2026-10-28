import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';
import '../state/post_bloc.dart';
import '../state/post_event.dart';
import '../state/post_state.dart';
import '../widgets/post_card.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class PostListScreen extends StatefulWidget {
  final PostRepository repository;

  const PostListScreen({super.key, required this.repository});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUsers();
  }

  void _loadUsers() async {
    try {
      final users = await widget.repository.getUsers();
      if (mounted) setState(() => _users = users);
    } catch (_) {}
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<PostBloc>().add(LoadMorePostsEvent());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Explorer'),
        actions: [
          BlocBuilder<PostBloc, PostState>(
            builder: (context, state) {
              return IconButton(
                icon: Icon(state.isAscending ? Icons.arrow_upward : Icons.arrow_downward),
                tooltip: 'Сортировка по ID',
                onPressed: () {
                  context.read<PostBloc>().add(SortPostsEvent(ascending: !state.isAscending));
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Фильтр по автору',
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newPost = await Navigator.push<Post>(
            context,
            MaterialPageRoute(
              builder: (_) => CreatePostScreen(repository: widget.repository),
            ),
          );
          if (newPost != null && context.mounted) {
            context.read<PostBloc>().add(AddCreatedPostEvent(newPost));
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по заголовку (среди загруженных)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<PostBloc>().add(SearchPostsEvent(''));
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
              onChanged: (query) {
                context.read<PostBloc>().add(SearchPostsEvent(query));
              },
            ),
          ),
          BlocBuilder<PostBloc, PostState>(
            builder: (context, state) {
              if (state.status == PostStatus.cached) {
                return Container(
                  width: double.infinity,
                  color: Colors.amber.shade100,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_off, size: 18, color: Colors.amber.shade900),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Отображаются сохраненные данные (офлайн/кэш)',
                          style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (state.selectedUserId != null) {
                return Container(
                  width: double.infinity,
                  color: Colors.blue.shade50,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Фильтр: Автор ID ${state.selectedUserId}',
                        style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w500),
                      ),
                      TextButton(
                        onPressed: () => context.read<PostBloc>().add(FilterByUserEvent(null)),
                        child: const Text('Сбросить'),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: BlocBuilder<PostBloc, PostState>(
              builder: (context, state) {
                if (state.status == PostStatus.loading && state.posts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == PostStatus.error && state.posts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(
                            state.errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.read<PostBloc>().add(LoadPostsEvent(isRefresh: true)),
                            child: const Text('Повторить попытку'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state.isEmpty) {
                  return const Center(
                    child: Text('Посты не найдены.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  );
                }

                final posts = state.filteredPosts;

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<PostBloc>().add(LoadPostsEvent(isRefresh: true));
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: posts.length + (state.hasReachedMax ? 0 : 1),
                    itemBuilder: (context, index) {
                      if (index >= posts.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: state.isLoadingMore
                                ? const CircularProgressIndicator()
                                : ElevatedButton(
                                    onPressed: () => context.read<PostBloc>().add(LoadMorePostsEvent()),
                                    child: const Text('Загрузить еще'),
                                  ),
                          ),
                        );
                      }

                      final post = posts[index];
                      return PostCard(
                        post: post,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(
                                post: post,
                                repository: widget.repository,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Выберите автора'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _users.length + 1,
              itemBuilder: (ctx, index) {
                if (index == 0) {
                  return ListTile(
                    title: const Text('Все авторы'),
                    onTap: () {
                      context.read<PostBloc>().add(FilterByUserEvent(null));
                      Navigator.pop(dialogCtx);
                    },
                  );
                }
                final user = _users[index - 1];
                return ListTile(
                  title: Text(user.name),
                  subtitle: Text('ID: ${user.id} • ${user.email}'),
                  onTap: () {
                    context.read<PostBloc>().add(FilterByUserEvent(user.id));
                    Navigator.pop(dialogCtx);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}