enum MessageRole { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.role,
    required this.createdAt,
  });

  final String text;
  final MessageRole role;
  final DateTime createdAt;
}
