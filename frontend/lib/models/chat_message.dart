class ChatMessage {
  final String role;
  final String text;
  final DateTime ts;

  const ChatMessage({
    required this.role,
    required this.text,
    required this.ts,
  });
}
