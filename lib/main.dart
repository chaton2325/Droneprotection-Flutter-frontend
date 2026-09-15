import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/alert_service.dart';
import 'services/api_client.dart';
import 'services/audio_stream_service.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/friends_service.dart';
import 'services/location_service.dart';
import 'services/socket_service.dart';
import 'services/video_stream_service.dart';
import 'state/alert_provider.dart';
import 'state/auth_provider.dart';
import 'state/chat_provider.dart';
import 'state/friend_alerts_provider.dart';
import 'state/friends_provider.dart';

void main() {
  final apiClient = ApiClient();
  final socketService = SocketService();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<SocketService>.value(value: socketService),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            apiClient: apiClient,
            authService: AuthService(apiClient),
            socketService: socketService,
          )..restoreSession(),
        ),
        ChangeNotifierProvider<AlertProvider>(
          create: (_) => AlertProvider(
            alertService: AlertService(apiClient),
            locationService: LocationService(),
            socketService: socketService,
            audioStreamService: AudioStreamService(socketService),
            videoStreamService: VideoStreamService(socketService),
          ),
        ),
        ChangeNotifierProvider<ChatProvider>(
          create: (_) => ChatProvider(
            chatService: ChatService(apiClient),
            socketService: socketService,
          ),
        ),
        ChangeNotifierProvider<FriendsProvider>(
          create: (_) => FriendsProvider(friendsService: FriendsService(apiClient)),
        ),
        ChangeNotifierProvider<FriendAlertsProvider>(
          create: (_) => FriendAlertsProvider(socketService: socketService),
        ),
      ],
      child: const DronaidApp(),
    ),
  );
}
