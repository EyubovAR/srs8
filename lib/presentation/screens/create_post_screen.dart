import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';
import '../state/create_post_cubit.dart';

class CreatePostScreen extends StatefulWidget {
  final PostRepository repository;

  const CreatePostScreen({super.key, required this.repository});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  int _selectedUserId = 1;
  List<User> _users = [];
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await widget.repository.getUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoadingUsers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreatePostCubit(repository: widget.repository),
      child: Scaffold(
        appBar: AppBar(title: const Text('Создать пост')),
        body: BlocConsumer<CreatePostCubit, CreatePostState>(
          listener: (context, state) {
            if (state.status == CreateStatus.success && state.createdPost != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Пост успешно создан!')),
              );
              Navigator.pop(context, state.createdPost);
            } else if (state.status == CreateStatus.error && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            final isSubmitting = state.status == CreateStatus.submitting;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int>(
                      value: _selectedUserId,
                      decoration: const InputDecoration(
                        labelText: 'Автор поста',
                        border: OutlineInputBorder(),
                      ),
                      items: _isLoadingUsers
                          ? [const DropdownMenuItem(value: 1, child: Text('Пользователь #1'))]
                          : _users.map((u) {
                              return DropdownMenuItem(
                                value: u.id,
                                child: Text('${u.name} (id: ${u.id})'),
                              );
                            }).toList(),
                      onChanged: isSubmitting ? null : (val) {
                        if (val != null) setState(() => _selectedUserId = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Заголовок (от 5 до 100 символов)',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !isSubmitting,
                      validator: (value) {
                        if (value == null || value.trim().length < 5 || value.trim().length > 100) {
                          return 'Длина заголовка должна быть от 5 до 100 символов';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bodyController,
                      decoration: const InputDecoration(
                        labelText: 'Содержимое (от 10 до 1000 символов)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      enabled: !isSubmitting,
                      validator: (value) {
                        if (value == null || value.trim().length < 10 || value.trim().length > 1000) {
                          return 'Длина текста должна быть от 10 до 1000 символов';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<CreatePostCubit>().submitPost(
                                        title: _titleController.text,
                                        body: _bodyController.text,
                                        userId: _selectedUserId,
                                      );
                                }
                              },
                        child: isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Опубликовать'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}