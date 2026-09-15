import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/socket_service.dart';

/// Messagerie texte entre la victime et le repondant assigne a l'alerte en
/// cours. Volontairement separe d'AlertProvider (comme AudioStreamService /
/// VideoStreamService le sont deja) : une conversation n'a de sens que
/// lorsque l'ecran de chat est ouvert.
class ChatProvider extends ChangeNotifier {
  final ChatService chatService;
  final SocketService socketService;

  ChatProvider({required this.chatService, required this.socketService});

  int? _alertId;
  List<ChatMessage> messages = [];
  bool loading = false;
  bool sending = false;
  String? errorMessage;

  void _onMessage(dynamic data) {
    if (data is! Map) return;
    final message = ChatMessage.fromJson(Map<String, dynamic>.from(data));
    if (message.alertId != _alertId) return;
    if (messages.any((m) => m.id == message.id)) return;
    messages = [...messages, message];
    notifyListeners();
  }

  Future<void> open(int alertId) async {
    if (_alertId != alertId) {
      socketService.off('alert:message');
      messages = [];
    }
    _alertId = alertId;
    socketService.on('alert:message', _onMessage);

    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      messages = await chatService.list(alertId);
    } catch (err) {
      errorMessage = err.toString().replaceFirst('ApiException: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> send(String body) async {
    final alertId = _alertId;
    if (alertId == null || body.trim().isEmpty) return;

    sending = true;
    notifyListeners();
    try {
      final message = await chatService.send(alertId, body.trim());
      if (!messages.any((m) => m.id == message.id)) {
        messages = [...messages, message];
      }
    } catch (err) {
      errorMessage = err.toString().replaceFirst('ApiException: ', '');
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  void close() {
    socketService.off('alert:message');
    _alertId = null;
    messages = [];
  }
}
