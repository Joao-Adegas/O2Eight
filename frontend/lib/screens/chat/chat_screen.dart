// lib/screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _authService = AuthService();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  String? _sessionId; // null = conversa nova (criada no primeiro envio)
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  static const _maxContentWidth = 720.0;
  static final _botText = AppColors.onDark.withValues(alpha: 0.92);
  static final _hintText = AppColors.onDark.withValues(alpha: 0.5);

  static const _suggestions = [
    'Estou com muita vontade de fumar',
    'Tomei café e bateu vontade',
    'Estou ansioso agora',
    'Quanto tempo a vontade dura?',
  ];

  bool _started = false;

  /// Se a tela foi aberta com um texto (atalho dos gatilhos na Home), começa
  /// uma conversa nova com o texto já no campo. Senão, continua a última.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final prefill = ModalRoute.of(context)?.settings.arguments;
    if (prefill is String && prefill.isNotEmpty) {
      _inputController.text = prefill;
      _isLoading = false;
    } else {
      _openLatestSession();
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ───────────────────────── Dados do usuário ─────────────────────────

  String get _firstName {
    final meta = _authService.currentUser?.userMetadata ?? const {};
    final fullName =
        (meta['full_name'] ?? meta['name'] ?? '').toString().trim();
    if (fullName.isNotEmpty) return fullName.split(RegExp(r'\s+')).first;

    final email = _authService.currentUser?.email ?? '';
    return email.contains('@') ? email.split('@').first : '';
  }

  String get _greeting {
    final name = _firstName;
    return name.isEmpty
        ? 'Como posso te ajudar?'
        : 'Como posso te ajudar, $name?';
  }

  // ───────────────────────── Lógica ─────────────────────────

  /// Ao abrir, continua a conversa mais recente (se existir).
  Future<void> _openLatestSession() async {
    try {
      final sessions = await _chatService.listSessions();
      if (!mounted) return;
      if (sessions.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }
      await _openSession(sessions.first.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Não foi possível carregar suas conversas. $e');
    }
  }

  Future<void> _openSession(String sessionId) async {
    setState(() => _isLoading = true);
    try {
      final messages = await _chatService.getMessages(sessionId);
      if (!mounted) return;
      setState(() {
        _sessionId = sessionId;
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Não foi possível abrir a conversa. $e');
    }
  }

  void _startNewConversation() {
    if (_isSending) return;
    setState(() {
      _sessionId = null;
      _messages = [];
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _inputController.text).trim();
    if (text.isEmpty || _isSending) return;

    // Mostra a mensagem do usuário na hora (antes da resposta chegar)
    final optimistic = ChatMessage(sender: 'usuario', content: text);
    setState(() {
      _messages = [..._messages, optimistic];
      _isSending = true;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      final sessionId = _sessionId ?? (await _chatService.createSession()).id;
      _sessionId = sessionId;

      final saved = await _chatService.sendMessage(sessionId, text);
      if (!mounted) return;
      setState(() {
        _messages = [
          ..._messages.where((m) => !identical(m, optimistic)),
          ...saved,
        ];
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      // Desfaz a mensagem otimista e devolve o texto para o campo
      setState(() {
        _messages = _messages.where((m) => !identical(m, optimistic)).toList();
      });
      if (preset == null) _inputController.text = text;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _showHistory() async {
    List<ChatSessionInfo> sessions;
    try {
      sessions = await _chatService.listSessions();
    } catch (e) {
      _showMessage('Não foi possível carregar o histórico. $e');
      return;
    }
    if (!mounted) return;

    final selectedId = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Conversas anteriores',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            if (sessions.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Text(
                  'Você ainda não tem conversas salvas.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final s = sessions[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.chat_bubble_outline,
                        color: AppColors.navy700,
                      ),
                      title: Text(
                        s.title ?? 'Conversa sem título',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.text),
                      ),
                      subtitle: s.createdAt == null
                          ? null
                          : Text(
                              _formatDate(s.createdAt!),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                      selected: s.id == _sessionId,
                      selectedTileColor: AppColors.navy50,
                      onTap: () => Navigator.of(context).pop(s.id),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );

    if (selectedId != null && selectedId != _sessionId) {
      await _openSession(selectedId);
    }
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} às ${two(d.hour)}:${two(d.minute)}';
  }

  // ───────────────────────── Visual ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (_isLoading) {
      content = const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(color: AppColors.teal500),
      );
    } else if (_messages.isEmpty) {
      content = KeyedSubtree(
        key: const ValueKey('welcome'),
        child: _buildWelcome(),
      );
    } else {
      content = KeyedSubtree(
        key: const ValueKey('conversation'),
        child: _buildConversation(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.navy900,
      appBar: AppBar(
        backgroundColor: AppColors.navy900,
        foregroundColor: AppColors.onDark,
        title: const Text(
          'Assistente O₂Eight',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.onDark,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Conversas anteriores',
            icon: const Icon(Icons.history),
            onPressed: _isSending ? null : _showHistory,
          ),
          IconButton(
            tooltip: 'Nova conversa',
            icon: const Icon(Icons.edit_square),
            onPressed: _isSending ? null : _startNewConversation,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _BreathingGlow()),
          SafeArea(
            top: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: content,
            ),
          ),
        ],
      ),
    );
  }

  /// Conversa vazia: saudação e campo de texto no centro da tela.
  Widget _buildWelcome() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _greeting,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                  color: AppColors.onDark,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Se bateu vontade, conte o que está sentindo. '
                'Eu conheço seus gatilhos e suas motivações.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.onDarkSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _buildInputPill(autofocus: true),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                children: _suggestions
                    .map(
                      (s) => _SuggestionPill(
                        label: s,
                        onTap: _isSending ? null : () => _send(s),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildDisclaimer(),
            ],
          ),
        ),
      ),
    );
  }

  /// Conversa em andamento: mensagens em cima, campo na base.
  Widget _buildConversation() {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = ((constraints.maxWidth - _maxContentWidth) / 2)
                  .clamp(AppSpacing.lg, double.infinity);
              return ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(side, AppSpacing.lg, side, 8),
                itemCount: _messages.length + (_isSending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) return _buildTyping();
                  final message = _messages[index];
                  return message.isUser
                      ? _buildUserMessage(message, constraints.maxWidth)
                      : _buildBotMessage(message);
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInputPill(),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDisclaimer(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserMessage(ChatMessage message, double availableWidth) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: (availableWidth * 0.8).clamp(0, 520),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xl),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.navy700,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: SelectableText(
            message.content,
            style: const TextStyle(
              fontSize: 15.5,
              height: 1.5,
              color: AppColors.onDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BotAvatar(),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SelectableText(
              message.content,
              style: TextStyle(fontSize: 15.5, height: 1.6, color: _botText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Row(
        children: [
          const _BotAvatar(),
          const SizedBox(width: AppSpacing.md),
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.teal500,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Pensando…',
            style: TextStyle(color: _hintText, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPill({bool autofocus = false}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 6, 4),
      decoration: BoxDecoration(
        color: AppColors.navy800,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.onDark.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              autofocus: autofocus,
              minLines: 1,
              maxLines: 5,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.send,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(3000)],
              onSubmitted: (_) => _send(),
              cursorColor: AppColors.teal500,
              style: const TextStyle(fontSize: 16, color: AppColors.onDark),
              decoration: InputDecoration(
                hintText: 'Escreva como você está se sentindo',
                hintStyle: TextStyle(color: _hintText),
                filled: false,
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Botão acende só quando há texto
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _inputController,
            builder: (context, value, _) {
              final canSend = value.text.trim().isNotEmpty && !_isSending;
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: IconButton.filled(
                  tooltip: 'Enviar',
                  onPressed: canSend ? () => _send() : null,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.teal500,
                    foregroundColor: AppColors.navy900,
                    disabledBackgroundColor:
                        AppColors.onDark.withValues(alpha: 0.10),
                    disabledForegroundColor:
                        AppColors.onDark.withValues(alpha: 0.35),
                  ),
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Text(
      'A assistente não substitui um profissional de saúde. '
      'Em crise, ligue 188 (CVV).',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: AppColors.onDark.withValues(alpha: 0.4),
      ),
    );
  }
}

/// Ícone da assistente ao lado das respostas.
class _BotAvatar extends StatelessWidget {
  const _BotAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.teal500.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.spa_outlined, size: 16, color: AppColors.teal500),
    );
  }
}

/// Sugestão de mensagem em formato de pílula.
class _SuggestionPill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _SuggestionPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillShape,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: AppRadius.pillShape,
            border: Border.all(color: AppColors.onDark.withValues(alpha: 0.18)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.onDarkSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Brilho turquesa que expande e contrai devagar (ciclo de 5 s),
/// funcionando como uma pista visual de respiração.
class _BreathingGlow extends StatefulWidget {
  const _BreathingGlow();

  @override
  State<_BreathingGlow> createState() => _BreathingGlowState();
}

class _BreathingGlowState extends State<_BreathingGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = reduceMotion
              ? 0.5
              : Curves.easeInOut.transform(_controller.value);
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, 0.2),
                radius: 0.85 + 0.15 * t,
                colors: [
                  AppColors.teal500.withValues(alpha: 0.10 + 0.06 * t),
                  AppColors.navy700.withValues(alpha: 0.35),
                  AppColors.navy900.withValues(alpha: 0),
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
          );
        },
      ),
    );
  }
}