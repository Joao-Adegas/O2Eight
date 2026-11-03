import 'package:flutter/material.dart';

enum AppTab { dashboard, patterns, chat, community }

class _NavItem {
  final AppTab tab;
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const _NavItem({
    required this.tab,
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

class NavBottomBar extends StatelessWidget {
  final AppTab currentTab;
  final ValueChanged<AppTab> onTabSelected;

  const NavBottomBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  static const List<_NavItem> _items = [
    _NavItem(
      tab: AppTab.dashboard,
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: "Início",
    ),
    _NavItem(
      tab: AppTab.patterns,
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
      label: "Padrões",
    ),
    _NavItem(
      tab: AppTab.chat,
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: "Chat",
    ),
    _NavItem(
      tab: AppTab.community,
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: "Comunidade",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _items.map((item) {
            final isSelected = item.tab == currentTab;
            return _NavBarButton(
              icon: isSelected ? (item.activeIcon ?? item.icon) : item.icon,
              label: item.label,
              isSelected: isSelected,
              onTap: () => onTabSelected(item.tab),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  static const _activeColor = Color(0xFF0D4F7C);
  static const _inactiveColor = Color(0xFFAFC2CC);

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? _activeColor : _inactiveColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}