import '../models/chat_message.dart';
import 'api_client.dart';

class ChatService {
  final ApiClient _client;
  ChatService(this._client);

  Future<List<ChatMessage>> list(int alertId) async {
    final data = await _client.get('/alerts/$alertId/messages');
    return (data['messages'] as List)
        .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> send(int alertId, String body) async {
    final data = await _client.post(
      '/alerts/$alertId/messages',
      body: {'body': body},
    );
    return ChatMessage.fromJson(data['message']);
  }
}
