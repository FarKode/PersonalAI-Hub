enum ChatRole { user, ai }

class ChatMessage {
  final String id;
  final String text;
  final ChatRole role;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.timestamp,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    ChatRole? role,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
