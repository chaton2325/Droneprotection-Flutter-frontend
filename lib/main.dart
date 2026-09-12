import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/alert_service.dart';
import 'services/api_client.dart';
import 'services/audio_stream_service.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/socket_service.dart';
import 'state/alert_provider.dart';
import 'state/auth_provider.dart';

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
          ),
        ),
      ],
      child: const DronaidApp(),
    ),
  );
}
