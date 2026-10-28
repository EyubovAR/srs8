import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';

enum CreateStatus { initial, submitting, success, error }

class CreatePostState {
  final CreateStatus status;
  final Post? createdPost;
  final String? errorMessage;

  const CreatePostState({
    this.status = CreateStatus.initial,
    this.createdPost,
    this.errorMessage,
  });
}

class CreatePostCubit extends Cubit<CreatePostState> {
  final PostRepository repository;

  CreatePostCubit({required this.repository}) : super(const CreatePostState());

  Future<void> submitPost({
    required String title,
    required String body,
    required int userId,
  }) async {
    // Валидация по ТЗ
    if (title.trim().length < 5 || title.trim().length > 100) {
      emit(const CreatePostState(
        status: CreateStatus.error,
        errorMessage: 'Заголовок должен содержать от 5 до 100 символов',
      ));
      return;
    }

    if (body.trim().length < 10 || body.trim().length > 1000) {
      emit(const CreatePostState(
        status: CreateStatus.error,
        errorMessage: 'Текст поста должен содержать от 10 до 1000 символов',
      ));
      return;
    }

    emit(const CreatePostState(status: CreateStatus.submitting));

    try {
      final post = await repository.createPost(
        title: title.trim(),
        body: body.trim(),
        userId: userId,
      );
      emit(CreatePostState(status: CreateStatus.success, createdPost: post));
    } catch (e) {
      emit(CreatePostState(status: CreateStatus.error, errorMessage: e.toString()));
    }
  }
}