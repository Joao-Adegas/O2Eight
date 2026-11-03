// lib/screens/community/community_screen.dart
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/community_service.dart';
// import 'post_detail_screen.dart';
import '../community/widgets/post_detail_screen.dart';
import 'widgets/community_widgets.dart';

/// Feed da comunidade.
/// Pode receber um texto em `arguments` da rota (ex: vindo da janela de
/// conquista) para abrir o editor já preenchido.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _service = CommunityService();

  List<CommunityPost> _posts = [];
  bool _isLoading = true;
  String? _error;
  bool _checkedPrefill = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checkedPrefill) return;
    _checkedPrefill = true;

    final prefill = ModalRoute.of(context)?.settings.arguments;
    if (prefill is String && prefill.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openComposer(initialText: prefill),
      );
    }
  }

  // ───────────────────────── Lógica ─────────────────────────

  Future<void> _loadPosts({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final posts = await _service.listPosts();
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _toggleLike(CommunityPost post) async {
    // Atualiza na hora e confirma com o servidor
    final previousLiked = post.likedByMe;
    final previousLikes = post.likes;
    setState(() {
      post.likedByMe = !previousLiked;
      post.likes += post.likedByMe ? 1 : -1;
    });

    try {
      final result = await _service.togglePostLike(post.id);
      if (!mounted) return;
      setState(() {
        post.likedByMe = result.liked;
        post.likes = result.likes;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        post.likedByMe = previousLiked;
        post.likes = previousLikes;
      });
      _showMessage('Não foi possível curtir agora.');
    }
  }

  Future<void> _deletePost(CommunityPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir publicação?'),
        content: const Text(
          'A publicação e todos os comentários serão apagados.',
        ),
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
    if (confirmed != true) return;

    try {
      await _service.deletePost(post.id);
      if (!mounted) return;
      setState(() => _posts.removeWhere((p) => p.id == post.id));
      _showMessage('Publicação excluída.');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openPost(CommunityPost post) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
    );
    // Ao voltar, atualiza contagens de curtidas e comentários
    if (mounted) _loadPosts(silent: true);
  }

  Future<void> _openComposer({String? initialText}) async {
    final created = await showModalBottomSheet<CommunityPost>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PostComposerSheet(
        service: _service,
        initialText: initialText,
      ),
    );
    if (created != null && mounted) {
      setState(() => _posts = [created, ..._posts]);
      _showMessage('Publicado na comunidade.');
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ───────────────────────── Visual ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidade'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openComposer(),
        backgroundColor: AppColors.navy700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_outlined),
        label: const Text(
          'Publicar',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Não foi possível carregar a comunidade.',
                style: TextStyle(color: AppColors.text),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: _loadPosts,
                  child: const Text('Tentar novamente'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadPosts(silent: true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Em telas largas, o feed fica centralizado com até 640 px
          final side = ((constraints.maxWidth - 640) / 2)
              .clamp(AppSpacing.lg, double.infinity);

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(side, AppSpacing.lg, side, 96),
            children: [
              _ComposerPrompt(onTap: () => _openComposer()),
              const SizedBox(height: AppSpacing.lg),
              if (_posts.isEmpty)
                const _EmptyFeed()
              else
                ..._posts.map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: PostCard(
                      post: post,
                      onTap: () => _openPost(post),
                      onLike: () => _toggleLike(post),
                      onComment: () => _openPost(post),
                      onShare: () => sharePost(context, post),
                      onDelete: post.isMine ? () => _deletePost(post) : null,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Campo "falso" no topo do feed que abre o editor.
class _ComposerPrompt extends StatelessWidget {
  final VoidCallback onTap;

  const _ComposerPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.large,
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.edit_note, color: AppColors.navy700),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Como está sua jornada hoje?',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.forum_outlined, size: 48, color: AppColors.textSecondary),
          SizedBox(height: AppSpacing.md),
          Text(
            'Comece a conversa',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Conte como está sendo sua jornada. Sua história pode ajudar alguém.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Editor de publicação (bottom sheet).
class _PostComposerSheet extends StatefulWidget {
  final CommunityService service;
  final String? initialText;

  const _PostComposerSheet({required this.service, this.initialText});

  @override
  State<_PostComposerSheet> createState() => _PostComposerSheetState();
}

class _PostComposerSheetState extends State<_PostComposerSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText ?? '');
  bool _anonymous = false;
  bool _isPosting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isPosting) return;

    setState(() => _isPosting = true);
    try {
      final post = await widget.service.createPost(text, anonymous: _anonymous);
      if (!mounted) return;
      Navigator.of(context).pop(post);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPosting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível publicar agora.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Nova publicação',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _controller,
                autofocus: true,
                minLines: 4,
                maxLines: 8,
                maxLength: 3000,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText:
                      'Compartilhe uma conquista, uma dificuldade ou uma dica',
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _anonymous,
                activeColor: AppColors.navy700,
                onChanged: (v) => setState(() => _anonymous = v),
                title: const Text(
                  'Publicar como anônimo',
                  style: TextStyle(fontSize: 15, color: AppColors.text),
                ),
                subtitle: const Text(
                  'Seu nome não aparece. Os dias sem fumar continuam visíveis.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Seja gentil. Não compartilhe dados pessoais nem orientações médicas.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _controller.text.trim().isEmpty || _isPosting
                    ? null
                    : _publish,
                child: _isPosting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Publicar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
