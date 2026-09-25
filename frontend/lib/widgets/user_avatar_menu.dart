// lib/widgets/user_avatar_menu.dart
import 'package:flutter/material.dart';
import 'package:flutter_version/app/routes.dart';
import 'package:flutter_version/services/auth_service.dart';

enum _UserMenuAction { logout }

/// Foto do usuário (vinda do Google) com menu para sair da conta.
/// Se a foto não carregar, mostra as iniciais do nome.
class UserAvatarMenu extends StatelessWidget {
  final String userName;
  final AuthService authService;

  const UserAvatarMenu({
    super.key,
    required this.userName,
    required this.authService,
  });

  static const _navy = Color(0xFF0D4F7C);

  String get _initials {
    final parts = userName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await authService.signOut();
      navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Não foi possível sair da conta: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = authService.avatarUrl;
    final email = authService.currentUser?.email;

    return PopupMenuButton<_UserMenuAction>(
      tooltip: 'Minha conta',
      offset: const Offset(0, 52),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (action) {
        if (action == _UserMenuAction.logout) _logout(context);
      },
      itemBuilder: (context) => [
        PopupMenuItem<_UserMenuAction>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _navy,
                ),
              ),
              if (email != null)
                Text(
                  email,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<_UserMenuAction>(
          value: _UserMenuAction.logout,
          child: Row(
            children: [
              Icon(Icons.logout, size: 20, color: _navy),
              SizedBox(width: 10),
              Text('Sair da conta', style: TextStyle(color: _navy)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: _navy,
          foregroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          onForegroundImageError: avatarUrl != null ? (_, __) {} : null,
          child: Text(
            _initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}