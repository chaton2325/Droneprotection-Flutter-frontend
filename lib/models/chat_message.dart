class ChatMessage {
  final int id;
  final int alertId;
  final int senderId;
  final String body;
  final String createdAt;

  const ChatMessage({
    required this.id,
    required this.alertId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      alertId: json['alert_id'] as int,
      senderId: json['sender_id'] as int,
      body: json['body'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}
