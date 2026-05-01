import 'package:ameko_app/features/social/data/models/social_product_model.dart';

class PostModel {
  final int id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final String? assembledProductId;
  final List<String> attachmentUrls;
  final int reactionCount;
  final int commentCount;
  final String? currentUserReaction;
  final SocialProductModel? product;
  final String? shopId;
  final String? shopName;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final String role;

  PostModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    this.assembledProductId,
    required this.attachmentUrls,
    required this.reactionCount,
    required this.commentCount,
    this.currentUserReaction,
    this.product,
    this.shopId,
    this.shopName,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    required this.role,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      assembledProductId: json['assembledProductId'],
      attachmentUrls: List<String>.from(json['attachmentUrls'] ?? []),
      reactionCount: json['reactionCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      currentUserReaction: json['currentUserReaction'],
      product: json['product'] != null ? SocialProductModel.fromJson(json['product']) : null,
      shopId: json['shopId'],
      shopName: json['shopName'],
      username: json['username'],
      fullName: json['fullName'],
      avatarUrl: json['avatarUrl'],
      role: json['role'],
    );
  }

  PostModel copyWith({
    int? id,
    String? userId,
    String? title,
    DateTime? createdAt,
    String? assembledProductId,
    List<String>? attachmentUrls,
    int? reactionCount,
    int? commentCount,
    String? currentUserReaction,
    SocialProductModel? product,
    String? shopId,
    String? shopName,
    String? username,
    String? fullName,
    String? avatarUrl,
    String? role,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      assembledProductId: assembledProductId ?? this.assembledProductId,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      reactionCount: reactionCount ?? this.reactionCount,
      commentCount: commentCount ?? this.commentCount,
      currentUserReaction: currentUserReaction ?? this.currentUserReaction,
      product: product ?? this.product,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
    );
  }
}
