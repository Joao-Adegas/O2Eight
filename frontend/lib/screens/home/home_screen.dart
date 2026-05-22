import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../components/gradient_button.dart';
import '../../components/section_card.dart';
import '../../core/theme/app_theme.dart';
import '../../models/chat_message.dart';
import '../../models/community_post.dart';
import '../../models/metrics.dart';
import '../../services/mock_data_service.dart';

enum HomeTab { dashboard, patterns, chat, community, insights }

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeTab _tab = HomeTab.dashboard;
  late Timer _timer;
  int _elapsed = 37 * 86400 + 14 * 3600 + 22 * 60;

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  List<ChatMessage> _messages = [
    ChatMessage(
      role: 'ai',
      text: 'Ola, Lucas! Estou aqui. Como voce esta agora?',
      ts: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];

  bool _emergencyUsed = false;
  String? _selectedTrigger;
  int? _intensity;
  bool _logDone = false;
  final Set<int> _likedPosts = {};

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += 1);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  String _formatTime(int sec) {
    final d = sec ~/ 86400;
    final h = (sec % 86400) ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    if (d > 0) return '${d}d ${h}h';
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  void _sendMessage([String? value]) {
    final msg = (value ?? _chatController.text).trim();
    if (msg.isEmpty) return;

    setState(() {
      _messages = [
        ..._messages,
        ChatMessage(role: 'user', text: msg, ts: DateTime.now()),
      ];
      _chatController.clear();
    });

    final lower = msg.toLowerCase();
    String response = MockDataService.aiResponses['default']!;
    if (lower.contains('cafe')) {
      response = MockDataService.aiResponses['cafe']!;
    } else if (lower.contains('estress')) {
      response = MockDataService.aiResponses['estresse']!;
    } else if (lower.contains('tedio')) {
      response = MockDataService.aiResponses['tedio']!;
    }

    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _messages = [
          ..._messages,
          ChatMessage(role: 'ai', text: response, ts: DateTime.now()),
        ];
      });
      _scrollChatToBottom();
    });
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScrollController.hasClients) return;
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(isDark, textMuted),
            _buildHeader(textMuted),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildCurrentTab(),
              ),
            ),
            _buildBottomNavigation(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Row(
        children: [
          Text(
            '09:41',
            style: TextStyle(
              color: textMuted,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
          const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: widget.onToggleTheme,
            icon: Icon(
              isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
              color: AppTheme.accentStart,
              size: 18,
            ),
          ),
          const Icon(Icons.bluetooth, color: AppTheme.accentStart, size: 14),
          const SizedBox(width: 8),
          Row(
            children: List.generate(
              4,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                width: 3,
                height: 4 + (i * 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: i < 3
                      ? AppTheme.accentStart
                      : (isDark ? const Color(0x664A6A8A) : const Color(0x66143B74)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textMuted) {
    final subtitle = _tab == HomeTab.dashboard ? '37 dias de progresso' : null;
    final title = switch (_tab) {
      HomeTab.dashboard => 'Ola, Lucas',
      HomeTab.patterns => 'Seus padroes',
      HomeTab.chat => 'IA Coach',
      HomeTab.community => 'Comunidade',
      HomeTab.insights => 'Dados e Ciencia',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [AppTheme.accentStart, AppTheme.accentEnd],
                  ).createShader(rect),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(color: textMuted, fontSize: 12),
                  ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accentStart, width: 2),
              gradient: const LinearGradient(
                colors: [Color(0xFF143B74), Color(0xFF0780AE)],
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              'L',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    return switch (_tab) {
      HomeTab.dashboard => _buildDashboardTab(),
      HomeTab.patterns => _buildPatternsTab(),
      HomeTab.chat => _buildChatTab(),
      HomeTab.community => _buildCommunityTab(),
      HomeTab.insights => _buildInsightsTab(),
    };
  }

  Widget _buildDashboardTab() {
    final saved = ((_elapsed / 86400) * 20 * 12.5).toStringAsFixed(2);
    const puffsDone = 163;
    final toxinsAvoided = (puffsDone * 4000).toString();

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF143B74), Color(0xFF0780AE)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bluetooth, size: 14, color: AppTheme.accentStart),
                  SizedBox(width: 6),
                  Text(
                    'DISPOSITIVO CONECTADO',
                    style: TextStyle(
                      color: AppTheme.accentStart,
                      letterSpacing: 1.3,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Tempo sem fumar', style: TextStyle(fontSize: 12, color: Color(0xFFC8D9EE))),
              Text(
                _formatTime(_elapsed),
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _heroInfo(Icons.attach_money, 'Economizado', 'R\$ $saved')),
                  const SizedBox(width: 8),
                  Expanded(child: _heroInfo(Icons.air, 'Tragadas', '$puffsDone')),
                  const SizedBox(width: 8),
                  Expanded(child: _heroInfo(Icons.shield_outlined, 'Toxinas evitadas', toxinsAvoided)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Economia acumulada', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SizedBox(height: 140, child: _savingsChart()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.favorite, size: 16, color: AppTheme.accentStart),
                  SizedBox(width: 6),
                  Text('Recuperacao biologica', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              ...MockDataService.milestones.map(_milestoneItem),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x4D0780AE)),
            color: const Color(0x1F0780AE),
          ),
          child: const Row(
            children: [
              Icon(Icons.schedule, color: Color(0xFF0780AE)),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Proxima janela de risco', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('Terca 16h - gatilho de estresse pos-reuniao', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Text('em 2h 14m', style: TextStyle(color: AppTheme.accentStart, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroInfo(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppTheme.accentStart),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFFC8D9EE))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _milestoneItem(Milestone m) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: m.done
                  ? const LinearGradient(colors: [AppTheme.accentStart, AppTheme.accentEnd])
                  : null,
              color: m.done ? null : muted.withValues(alpha: 0.18),
            ),
            alignment: Alignment.center,
            child: Text(
              m.done ? 'x' : '',
              style: const TextStyle(
                color: Color(0xFF0B1F3A),
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              m.label,
              style: TextStyle(
                fontSize: 13,
                color: m.done ? null : muted,
              ),
            ),
          ),
          Text(m.time, style: TextStyle(fontSize: 11, color: muted)),
        ],
      ),
    );
  }

  Widget _buildPatternsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tragadas por dia', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SizedBox(height: 140, child: _puffChart()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Principais gatilhos', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ...MockDataService.triggers.map((t) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(t.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text('${t.count}x', style: TextStyle(fontSize: 12, color: muted)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: t.pct / 100,
                          minHeight: 7,
                          backgroundColor: muted.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentStart),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Horarios criticos (IA)', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              SizedBox(
                height: 82,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: MockDataService.criticalHours.map((h) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: (h.risk / 100) * 58,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: h.risk >= 70 ? const Color(0xFFD64545) : AppTheme.accentStart,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(h.hour, style: TextStyle(fontSize: 10, color: muted)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Text('Vermelho indica risco alto.', style: TextStyle(fontSize: 12, color: muted)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(child: _buildTriggerLog()),
      ],
    );
  }

  Widget _buildTriggerLog() {
    final options = ['Cafe', 'Estresse', 'Tedio', 'Social', 'Alcool', 'Outro'];

    if (_logDone) {
      return Column(
        children: [
          const Text('Registrado!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() {
              _logDone = false;
              _selectedTrigger = null;
              _intensity = null;
            }),
            child: const Text('Registrar outro'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Registrar vontade agora', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((o) {
            final selected = _selectedTrigger == o;
            return ChoiceChip(
              selected: selected,
              label: Text(o),
              onSelected: (_) => setState(() => _selectedTrigger = o),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        const Text('Intensidade (1 a 5)'),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (i) {
            final val = i + 1;
            final selected = _intensity == val;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: selected ? AppTheme.accentStart : null,
                    foregroundColor: selected ? const Color(0xFF0B1F3A) : null,
                  ),
                  onPressed: () => setState(() => _intensity = val),
                  child: Text('$val'),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        GradientButton(
          text: 'Salvar registro',
          onPressed: (_selectedTrigger != null && _intensity != null)
              ? () => setState(() => _logDone = true)
              : null,
        ),
      ],
    );
  }

  Widget _buildChatTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        if (!_emergencyUsed)
          InkWell(
            onTap: () {
              setState(() => _emergencyUsed = true);
              _sendMessage('To quase fumando, preciso de ajuda agora!');
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x66D64545), width: 1.7),
                color: const Color(0x22D64545),
              ),
              child: const Row(
                children: [
                  Icon(Icons.flash_on, color: Color(0xFFD64545)),
                  SizedBox(width: 8),
                  Expanded(child: Text('To quase fumando - suporte de emergencia')),
                ],
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            itemCount: _messages.length,
            itemBuilder: (_, index) {
              final m = _messages[index];
              final isUser = m.role == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 290),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: isUser
                        ? const LinearGradient(colors: [AppTheme.accentStart, AppTheme.accentEnd])
                        : null,
                    color: isUser ? null : (isDark ? const Color(0xFF1A2F55) : const Color(0xFFE9F0F7)),
                  ),
                  child: Text(
                    m.text,
                    style: TextStyle(
                      color: isUser ? const Color(0xFF0B1F3A) : null,
                      fontWeight: isUser ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              'To com vontade de fumar',
              'Gatilho do cafe',
              'Muito estresse hoje',
              'Quanto economizei?',
            ].map((q) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(q, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _sendMessage(q),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Como voce esta se sentindo?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(colors: [AppTheme.accentStart, AppTheme.accentEnd]),
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send, color: Color(0xFF0B1F3A)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildCommunityTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x443CCCB4)),
            color: const Color(0x1A3CCCB4),
          ),
          child: const Row(
            children: [
              Icon(Icons.groups, color: AppTheme.accentStart),
              SizedBox(width: 8),
              Expanded(child: Text('12.847 membros ativos')),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const GradientButton(text: '+ Compartilhar meu progresso'),
        const SizedBox(height: 10),
        ...MockDataService.posts.map((post) => _buildPostCard(post, muted)),
      ],
    );
  }

  Widget _buildPostCard(CommunityPost post, Color muted) {
    final liked = _likedPosts.contains(post.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(19),
                    gradient: const LinearGradient(colors: [Color(0xFF143B74), Color(0xFF0780AE)]),
                  ),
                  alignment: Alignment.center,
                  child: Text(post.avatar, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.author, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${post.daysClean} dias limpo - ${post.timeAgo}', style: TextStyle(fontSize: 12, color: muted)),
                    ],
                  ),
                ),
                if (post.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x263CCCB4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(post.badge!, style: const TextStyle(fontSize: 10, color: AppTheme.accentStart)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(post.text),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => setState(() {
                    if (liked) {
                      _likedPosts.remove(post.id);
                    } else {
                      _likedPosts.add(post.id);
                    }
                  }),
                  icon: Icon(Icons.thumb_up_alt_outlined, size: 16, color: liked ? AppTheme.accentStart : muted),
                  label: Text('${post.likes + (liked ? 1 : 0)}', style: TextStyle(color: liked ? AppTheme.accentStart : muted)),
                ),
                TextButton.icon(
                  onPressed: null,
                  icon: Icon(Icons.chat_bubble_outline, size: 16, color: muted),
                  label: Text('${post.comments}', style: TextStyle(color: muted)),
                ),
                const Spacer(),
                IconButton(onPressed: null, icon: Icon(Icons.share_outlined, size: 18, color: muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x333CCCB4)),
            color: const Color(0x113CCCB4),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppTheme.accentStart),
              SizedBox(width: 8),
              Expanded(child: Text('Dados anonimizados e protegidos')),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.5,
          children: const [
            _StatTile(icon: Icons.query_stats, label: 'Usuarios ativos', value: '12.847'),
            _StatTile(icon: Icons.psychology_alt_outlined, label: 'Taxa de sucesso IA', value: '74%'),
            _StatTile(icon: Icons.air, label: 'Tragadas bloqueadas', value: '2.1M'),
            _StatTile(icon: Icons.attach_money, label: 'Economia coletiva', value: 'R\$ 890K'),
          ],
        ),
        const SizedBox(height: 10),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Clusterizacao de perfis', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...MockDataService.clusterData.map((c) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(width: 88, child: Text(c.name, style: TextStyle(fontSize: 11, color: muted))),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                            value: c.success / 100,
                            minHeight: 22,
                            backgroundColor: muted.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentStart),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${c.usersK}K', style: TextStyle(fontSize: 11, color: muted)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x333CCCB4)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF143B74), Color(0xFF0B1F3A)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Contribua com a ciencia', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
              SizedBox(height: 8),
              Text(
                'Seus dados anonimizados ajudam pesquisadores a entender padroes de cessacao em escala.',
                style: TextStyle(fontSize: 12, color: Color(0xFFBCD4ED)),
              ),
              SizedBox(height: 10),
              GradientButton(text: 'Participar da pesquisa'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final inactive = isDark ? const Color(0xFF4A6A8A) : AppTheme.lightMuted;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _tabButton(HomeTab.dashboard, Icons.dashboard_outlined, 'Inicio', inactive),
          _tabButton(HomeTab.patterns, Icons.psychology_alt_outlined, 'Padroes', inactive),
          _tabButton(HomeTab.chat, Icons.mark_chat_unread_outlined, 'IA Coach', inactive),
          _tabButton(HomeTab.community, Icons.groups_2_outlined, 'Comunidade', inactive),
          _tabButton(HomeTab.insights, Icons.bar_chart_outlined, 'Pesquisa', inactive),
        ],
      ),
    );
  }

  Widget _tabButton(HomeTab tab, IconData icon, String label, Color inactive) {
    final active = _tab == tab;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _tab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: active ? const Color(0x1A3CCCB4) : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: active ? AppTheme.accentStart : inactive),
            Text(label, style: TextStyle(fontSize: 10, color: active ? AppTheme.accentStart : inactive)),
          ],
        ),
      ),
    );
  }

  Widget _savingsChart() {
    final list = MockDataService.savingsData;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= list.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(list[i].label, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < list.length; i++) FlSpot(i.toDouble(), list[i].value),
            ],
            isCurved: true,
            color: AppTheme.accentStart,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x663CCCB4), Color(0x003CCCB4)],
              ),
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _puffChart() {
    final list = MockDataService.puffHistory;

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= list.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(list[i].label, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < list.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: list[i].value,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.accentStart, AppTheme.accentEnd],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppTheme.accentStart),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: muted)),
          ],
        ),
      ),
    );
  }
}
