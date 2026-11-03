// lib/services/community_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_version/core/config/app_config.dart';

class CommunityComment {
  final String id;
  final String postId;
  final String? parentId; // preenchido quando é resposta
  final String? authorName;
  final bool isAnonymous;
  final bool isMine;
  final String text;
  final DateTime? createdAt;
  int likes;
  bool likedByMe;

  CommunityComment({
    required this.id,
    required this.postId,
    this.parentId,
    this.authorName,
    required this.isAnonymous,
    required this.isMine,
    required this.text,
    this.createdAt,
    required this.likes,
    required this.likedByMe,
  });

  String get displayName =>
      isAnonymous ? 'Anônimo' : (authorName ?? 'Usuário');

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['uuid'] as String,
      postId: json['post_uuid'] as String,
      parentId: json['parent_uuid'] as String?,
      authorName: json['author_name'] as String?,
      isAnonymous: (json['is_anonymous'] as bool?) ?? false,
      isMine: (json['is_mine'] as bool?) ?? false,
      text: (json['comment'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '')?.toLocal(),
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      likedByMe: (json['liked_by_me'] as bool?) ?? false,
    );
  }
}

class CommunityPost {
  final String id;
  final String? authorName;
  final bool isAnonymous;
  final bool isMine;
  final int cleanDays;
  final String text;
  final DateTime? createdAt;
  int likes;
  bool likedByMe;
  int commentsCount;
  final List<CommunityComment> comments;

  CommunityPost({
    required this.id,
    this.authorName,
    required this.isAnonymous,
    required this.isMine,
    required this.cleanDays,
    required this.text,
    this.createdAt,
    required this.likes,
    required this.likedByMe,
    required this.commentsCount,
    required this.comments,
  });

  String get displayName =>
      isAnonymous ? 'Anônimo' : (authorName ?? 'Usuário');

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['uuid'] as String,
      authorName: json['author_name'] as String?,
      isAnonymous: (json['is_anonymous'] as bool?) ?? false,
      isMine: (json['is_mine'] as bool?) ?? false,
      cleanDays: (json['dias_limpos'] as num?)?.toInt() ?? 0,
      text: (json['comment'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '')?.toLocal(),
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      likedByMe: (json['liked_by_me'] as bool?) ?? false,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      comments: ((json['comments'] as List<dynamic>?) ?? const [])
          .map((e) => CommunityComment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LikeResult {
  final bool liked;
  final int likes;

  const LikeResult({required this.liked, required this.likes});
}

class CommunityService {
  static String get _baseUrl => AppConfig.apiBaseUrl;

  Map<String, String> _headers() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw Exception('Nenhuma sessão ativa encontrada');
    }
    return {
      'Authorization': 'Bearer ${session.accessToken}',
      'Content-Type': 'application/json',
    };
  }

  dynamic _decode(http.Response res, String action) {
    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode == 200) return jsonDecode(body);
    if (res.statusCode == 403) {
      throw Exception('Você só pode alterar o que você mesmo publicou.');
    }
    throw Exception('Falha ao $action (${res.statusCode}): $body');
  }

  Future<List<CommunityPost>> listPosts() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/community/posts'),
      headers: _headers(),
    );
    final data = _decode(res, 'carregar a comunidade') as List<dynamic>;
    return data
        .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommunityPost> getPost(String postId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/community/posts/$postId'),
      headers: _headers(),
    );
    return CommunityPost.fromJson(
      _decode(res, 'carregar a publicação') as Map<String, dynamic>,
    );
  }

  Future<CommunityPost> createPost(String text, {bool anonymous = false}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/community/posts'),
      headers: _headers(),
      body: jsonEncode({'comment': text, 'is_anonymous': anonymous}),
    );
    return CommunityPost.fromJson(
      _decode(res, 'publicar') as Map<String, dynamic>,
    );
  }

  Future<void> deletePost(String postId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/community/posts/$postId'),
      headers: _headers(),
    );
    _decode(res, 'excluir a publicação');
  }

  Future<CommunityComment> createComment(
    String postId,
    String text, {
    String? parentId,
    bool anonymous = false,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/community/posts/$postId/comments'),
      headers: _headers(),
      body: jsonEncode({
        'comment': text,
        'parent_uuid': parentId,
        'is_anonymous': anonymous,
      }),
    );
    return CommunityComment.fromJson(
      _decode(res, 'comentar') as Map<String, dynamic>,
    );
  }

  Future<void> deleteComment(String commentId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/community/comments/$commentId'),
      headers: _headers(),
    );
    _decode(res, 'excluir o comentário');
  }

  Future<LikeResult> togglePostLike(String postId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/community/posts/$postId/like'),
      headers: _headers(),
    );
    final data = _decode(res, 'curtir') as Map<String, dynamic>;
    return LikeResult(
      liked: data['liked'] as bool,
      likes: (data['likes'] as num).toInt(),
    );
  }

  Future<LikeResult> toggleCommentLike(String commentId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/community/comments/$commentId/like'),
      headers: _headers(),
    );
    final data = _decode(res, 'curtir') as Map<String, dynamic>;
    return LikeResult(
      liked: data['liked'] as bool,
      likes: (data['likes'] as num).toInt(),
    );
  }
}