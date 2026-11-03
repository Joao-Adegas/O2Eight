// lib/screens/community/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_version/core/theme/app_theme.dart';
import 'package:flutter_version/screens/community/widgets/community_widgets.dart';
import 'package:flutter_version/services/community_service.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/community_service.dart';
import '../widgets/community_widgets.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _service = CommunityService();
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();

  CommunityPost? _post;
  bool _isLoading = true;
  bool _isSending = false;
  bool _anonymous = false;

  /// Comentário que está sendo respondido (null = comentário normal)
  CommunityComment? _replyingTo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  // ───────────────────────── Lógica ─────────────────────────

  Future<void> _load() async {
    try {
      final post = await _service.getPost(widget.postId);
      if (!mounted) return;
      setState(() {
        _post = post;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Não foi possível carregar a publicação.');
    }
  }

  /// Comentários principais, cada um seguido das suas respostas.
  List<({CommunityComment comment, bool isReply})> get _thread {
    final comments = _post?.comments ?? const <CommunityComment>[];
    final result = <({CommunityComment comment, bool isReply})>[];
    for (final top in comments.where((c) => c.parentId == null)) {
      result.add((comment: top, isReply: false));
      for (final reply in comments.where((c) => c.parentId == top.id)) {
        result.add((comment: reply, isReply: true));
      }
    }
    return result;
  }

  void _startReply(CommunityComment comment) {
    setState(() => _replyingTo = comment);
    _inputFocus.requestFocus();
  }

  Future<void> _sendComment() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending || _post == null) return;

    setState(() => _isSending = true);
    try {
      await _service.createComment(
        _post!.id,
        text,
        parentId: _replyingTo?.id,
        anonymous: _anonymous,
      );
      _inputController.clear();
      _replyingTo = null;
      await _load(); // recarrega o fio já organizado pelo servidor
    } catch (e) {
      _showMessage('Não foi possível enviar o comentário.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _togglePostLike() async {
    final post = _post;
    if (post == null) return;
    final prevLiked = post.likedByMe, prevLikes = post.likes;
    setState(() {
      post.likedByMe = !prevLiked;
      post.likes += post.likedByMe ? 1 : -1;
    });
    try {
      final r = await _service.togglePostLike(post.id);
      if (!mounted) return;
      setState(() {
        post.likedByMe = r.liked;
        post.likes = r.likes;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        post.likedByMe = prevLiked;
        post.likes = prevLikes;
      });
      _showMessage('Não foi possível curtir agora.');
    }
  }

  Future<void> _toggleCommentLike(CommunityComment comment) async {
    final prevLiked = comment.likedByMe, prevLikes = comment.likes;
    setState(() {
      comment.likedByMe = !prevLiked;
      comment.likes += comment.likedByMe ? 1 : -1;
    });
    try {
      final r = await _service.toggleCommentLike(comment.id);
      if (!mounted) return;
      setState(() {
        comment.likedByMe = r.liked;
        comment.likes = r.likes;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        comment.likedByMe = prevLiked;
        comment.likes = prevLikes;
      });
      _showMessage('Não foi possível curtir agora.');
    }
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _deletePost() async {
    if (!await _confirm('Excluir publicação?',
        'A publicação e todos os comentários serão apagados.')) {
      return;
    }
    try {
      await _service.deletePost(widget.postId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deleteComment(CommunityComment comment) async {
    if (!await _confirm('Excluir comentário?',
        'O comentário e as respostas a ele serão apagados.')) {
      return;
    }
    try {
      await _service.deleteComment(comment.id);
      await _load();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ───────────────────────── Visual ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicação'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final post = _post;
    if (post == null) {
      return const Center(
        child: Text(
          'Publicação não encontrada.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final thread = _thread;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = ((constraints.maxWidth - 640) / 2)
                  .clamp(AppSpacing.lg, double.infinity);
              return ListView(
                padding: EdgeInsets.fromLTRB(side, AppSpacing.lg, side, 24),
                children: [
                  PostCard(
                    post: post,
                    onLike: _togglePostLike,
                    onComment: () {
                      setState(() => _replyingTo = null);
                      _inputFocus.requestFocus();
                    },
                    onShare: () => sharePost(context, post),
                    onDelete: post.isMine ? _deletePost : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    post.commentsCount == 1
                        ? '1 comentário'
                        : '${post.commentsCount} comentários',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (thread.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Text(
                        'Seja a primeira pessoa a apoiar esta publicação.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    ...thread.map(
                      (item) => _CommentTile(
                        comment: item.comment,
                        isReply: item.isReply,
                        onLike: () => _toggleCommentLike(item.comment),
                        onReply: () => _startReply(item.comment),
                        onDelete: item.comment.isMine
                            ? () => _deleteComment(item.comment)
                            : null,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_replyingTo != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.reply,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Respondendo a ${_replyingTo!.displayName}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _replyingTo = null),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close,
                              size: 16, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: _anonymous
                        ? 'Comentando como anônimo'
                        : 'Comentar como anônimo',
                    onPressed: () => setState(() => _anonymous = !_anonymous),
                    icon: Icon(
                      _anonymous
                          ? Icons.visibility_off
                          : Icons.visibility_off_outlined,
                      color: _anonymous
                          ? AppColors.navy700
                          : AppColors.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      focusNode: _inputFocus,
                      minLines: 1,
                      maxLines: 4,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.send,
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: [LengthLimitingTextInputFormatter(1500)],
                      onSubmitted: (_) => _sendComment(),
                      decoration: InputDecoration(
                        hintText: _anonymous
                            ? 'Comentar como anônimo'
                            : 'Escreva um comentário de apoio',
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: AppColors.navy700, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _inputController,
                    builder: (context, value, _) => IconButton.filled(
                      tooltip: 'Enviar',
                      onPressed: value.text.trim().isEmpty || _isSending
                          ? null
                          : _sendComment,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.navy700,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.border,
                      ),
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.arrow_upward_rounded),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Um comentário (ou resposta, recuada para a direita).
class _CommentTile extends StatelessWidget {
  final CommunityComment comment;
  final bool isReply;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final VoidCallback? onDelete;

  const _CommentTile({
    required this.comment,
    required this.isReply,
    required this.onLike,
    required this.onReply,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 44 : 0, bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthorAvatar(
            name: comment.displayName,
            anonymous: comment.isAnonymous,
            size: isReply ? 28 : 34,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.medium,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.isMine && !comment.isAnonymous
                            ? '${comment.displayName} (você)'
                            : comment.displayName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        comment.text,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 2),
                  child: Row(
                    children: [
                      Text(
                        timeAgo(comment.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      _TextAction(
                        label: comment.likes > 0
                            ? 'Curtir · ${comment.likes}'
                            : 'Curtir',
                        highlighted: comment.likedByMe,
                        onTap: onLike,
                      ),
                      _TextAction(label: 'Responder', onTap: onReply),
                      if (onDelete != null)
                        _TextAction(label: 'Excluir', onTap: onDelete!),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  const _TextAction({
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.small,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: highlighted ? AppColors.like : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
