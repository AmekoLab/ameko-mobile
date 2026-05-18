class CommentEditHistory {
  final String oldContent;
  final DateTime editedAt;

  CommentEditHistory({
    required this.oldContent,
    required this.editedAt,
  });

  factory CommentEditHistory.fromJson(Map<String, dynamic> json) {
    return CommentEditHistory(
      oldContent: json['oldContent'],
      editedAt: DateTime.parse(json['editedAt']),
    );
  }
}

class CommentModel {
  final int id;
  final String userId;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final String content;
  final DateTime createdAt;
  final bool isEdited;
  final List<CommentEditHistory> editHistory;

  CommentModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    required this.content,
    required this.createdAt,
    required this.isEdited,
    required this.editHistory,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      userId: json['userId'],
      username: json['username'],
      fullName: json['fullName'],
      avatarUrl: json['avatarUrl'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      isEdited: json['isEdited'] ?? false,
      editHistory: (json['editHistory'] as List?)
              ?.map((e) => CommentEditHistory.fromJson(e))
              .toList() ??
          [],
    );
  }
}
