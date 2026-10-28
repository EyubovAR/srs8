import 'package:json_annotation/json_annotation.dart';

part 'post.g.dart';

@JsonSerializable()
class Post {
  final int? id;
  final int userId;
  final String title;
  final String body;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isLocallyCreated;

  const Post({
    this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.isLocallyCreated = false,
  });

  Post copyWith({
    int? id,
    int? userId,
    String? title,
    String? body,
    bool? isLocallyCreated,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      isLocallyCreated: isLocallyCreated ?? this.isLocallyCreated,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  Map<String, dynamic> toJson() => _$PostToJson(this);
}