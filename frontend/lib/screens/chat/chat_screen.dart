// lib/screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  String? _sessionId; // null = conversa nova (criada no primeiro envio)
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  static const _navy = Color(0xFF143B74);
  static const _textDark = Color(0xFF1A2A3A);
  static const _textMuted = Color(0xFF6B7785);
  static const _botBubble = Color(0xFFFFFFFF);
  static const _background = Color(0xFFF3F7F9);

  static const _suggestions = [
    'Estou com muita vontade de fumar agora',
    'Tomei café e bateu vontade',
    'Estou ansioso e não sei o que fazer',
    'Como a vontade costuma passar?',
  ];

  @override
  void initState() {
    super.initState();
    _openLatestSession();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
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
      final sessionId =
          _sessionId ?? (await _chatService.createSession()).id;
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
                  color: _textDark,
                ),
              ),
            ),
            if (sessions.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Text(
                  'Você ainda não tem conversas salvas.',
                  style: TextStyle(color: _textMuted),
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
                      leading: const Icon(Icons.chat_bubble_outline,
                          color: _navy),
                      title: Text(
                        s.title ?? 'Conversa sem título',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _textDark),
                      ),
                      subtitle: s.createdAt == null
                          ? null
                          : Text(
                              _formatDate(s.createdAt!),
                              style: const TextStyle(color: _textMuted),
                            ),
                      selected: s.id == _sessionId,
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
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2ECFCF), Color(0xFF1A7FA8), Color(0xFF0D4F7C)],
            ),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assistente O₂Eight',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'Converse nos momentos de vontade',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Conversas anteriores',
            icon: const Icon(Icons.history),
            onPressed: _isSending ? null : _showHistory,
          ),
          IconButton(
            tooltip: 'Nova conversa',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: _isSending ? null : _startNewConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) return _buildTypingBubble();
        return _buildBubble(_messages[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.spa_outlined, size: 48, color: Color(0xFF1A7FA8)),
              const SizedBox(height: 12),
              const Text(
                'Bateu vontade? Conte o que está sentindo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'A assistente conhece seus gatilhos e motivações e ajuda você a atravessar os próximos minutos.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _textMuted),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _suggestions
                    .map(
                      (s) => ActionChip(
                        label: Text(
                          s,
                          style: const TextStyle(color: _navy, fontSize: 13),
                        ),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFCFE3EC)),
                        onPressed: _isSending ? null : () => _send(s),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessage message) {
    final isUser = message.isUser;
    final maxWidth = MediaQuery.of(context).size.width * 0.78;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth.clamp(0, 520)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUser ? _navy : _botBubble,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            boxShadow: isUser
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: SelectableText(
            message.content,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: isUser ? Colors.white : _textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _botBubble,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text(
              'Escrevendo…',
              style: TextStyle(color: _textMuted, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  minLines: 1,
                  maxLines: 4,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.send,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [LengthLimitingTextInputFormatter(3000)],
                  onSubmitted: (_) => _send(),
                  style: const TextStyle(color: _textDark, fontSize: 15),
                  cursorColor: _navy,
                  decoration: InputDecoration(
                    hintText: 'Escreva como você está se sentindo…',
                    hintStyle: const TextStyle(color: _textMuted),
                    filled: true,
                    fillColor: _background,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                tooltip: 'Enviar',
                onPressed: _isSending ? null : () => _send(),
                style: IconButton.styleFrom(
                  backgroundColor: _navy,
                  disabledBackgroundColor: _navy.withValues(alpha: 0.4),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}