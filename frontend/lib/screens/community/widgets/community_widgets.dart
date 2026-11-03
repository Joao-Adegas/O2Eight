// lib/screens/community/widgets/community_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/community_service.dart';

/// "agora", "há 5 min", "há 2 h", "há 3 d" ou a data.
String timeAgo(DateTime? date) {
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'agora';
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'há ${diff.inHours} h';
  if (diff.inDays < 7) return 'há ${diff.inDays} d';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}';
}

String cleanDaysLabel(int days) {
  if (days <= 0) return 'Começando a jornada';
  if (days == 1) return '1 dia sem fumar';
  return '$days dias sem fumar';
}

/// Avatar com iniciais, ou ícone neutro quando anônimo.
class AuthorAvatar extends StatelessWidget {
  final String name;
  final bool anonymous;
  final double size;

  const AuthorAvatar({
    super.key,
    required this.name,
    required this.anonymous,
    this.size = 40,
  });

  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: anonymous ? AppColors.background : AppColors.navy50,
        border: anonymous ? Border.all(color: AppColors.border) : null,
      ),
      child: anonymous
          ? Icon(Icons.person_outline,
              size: size * 0.5, color: AppColors.textSecondary)
          : Text(
              _initials,
              style: TextStyle(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w700,
                color: AppColors.navy700,
              ),
            ),
    );
  }
}

/// Selo "125 dias sem fumar".
class CleanDaysBadge extends StatelessWidget {
  final int days;

  const CleanDaysBadge({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.teal50,
        borderRadius: AppRadius.pillShape,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.eco_outlined, size: 14, color: AppColors.teal700),
          const SizedBox(width: 4),
          Text(
            cleanDaysLabel(days),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.teal700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão de ação com ícone e contagem (curtir, comentar, compartilhar).
class ActionCountButton extends StatelessWidget {
  final IconData icon;
  final int? count;
  final Color color;
  final VoidCallback? onTap;
  final String tooltip;

  const ActionCountButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.count,
    this.color = AppColors.textSecondary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillShape,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              if (count != null) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Card de uma publicação, usado no feed e no topo da tela de detalhe.
class PostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback? onTap;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          decoration: BoxDecoration(
            borderRadius: AppRadius.large,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Autor ──
              Row(
                children: [
                  AuthorAvatar(
                    name: post.displayName,
                    anonymous: post.isAnonymous,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.isMine && !post.isAnonymous
                              ? '${post.displayName} (você)'
                              : post.displayName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          timeAgo(post.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    PopupMenuButton<String>(
                      tooltip: 'Opções',
                      icon: const Icon(Icons.more_horiz,
                          color: AppColors.textSecondary),
                      onSelected: (_) => onDelete!(),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Excluir publicação'),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              CleanDaysBadge(days: post.cleanDays),
              const SizedBox(height: AppSpacing.md),

              // ── Texto ──
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  post.text,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Ações ──
              Row(
                children: [
                  ActionCountButton(
                    icon: post.likedByMe
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: post.likedByMe
                        ? AppColors.like
                        : AppColors.textSecondary,
                    count: post.likes,
                    tooltip: post.likedByMe ? 'Descurtir' : 'Curtir',
                    onTap: onLike,
                  ),
                  ActionCountButton(
                    icon: Icons.chat_bubble_outline,
                    count: post.commentsCount,
                    tooltip: 'Comentar',
                    onTap: onComment,
                  ),
                  const Spacer(),
                  ActionCountButton(
                    icon: Icons.ios_share,
                    tooltip: 'Compartilhar',
                    onTap: onShare,
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

/// Copia o texto da publicação para compartilhar em outro app.
Future<void> sharePost(BuildContext context, CommunityPost post) async {
  final text = '${post.text}\n\n'
      '${cleanDaysLabel(post.cleanDays)} · compartilhado da comunidade O₂Eight';
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Texto copiado. Cole onde quiser compartilhar.'),
    ),
  );
}