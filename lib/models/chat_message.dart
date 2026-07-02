enum MessageStatus { sending, sent, error }

class ChatMessage {
  final String id;
  final String content;
  final String role;
  final DateTime timestamp;
  final MessageStatus status;
  final String? imageBase64;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.imageBase64,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    String? role,
    DateTime? timestamp,
    MessageStatus? status,
    String? imageBase64,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'role': role,
    'timestamp': timestamp.toIso8601String(),
    'status': status.index,
    if (imageBase64 != null) 'imageBase64': imageBase64,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    content: json['content'] as String,
    role: json['role'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    status: MessageStatus.values[json['status'] as int],
    imageBase64: json['imageBase64'] as String?,
  );
}
