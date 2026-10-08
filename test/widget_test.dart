// Smoke test : verifie que l'ecran de connexion s'affiche pour un utilisateur
// non authentifie, sans dependre du reseau (AuthProvider reste en statut
// "unauthenticated" tant que restoreSession() n'a pas ete appelee).
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:drone_protection/app.dart';
import 'package:drone_protection/services/alert_service.dart';
import 'package:drone_protection/services/api_client.dart';
import 'package:drone_protection/services/audio_stream_service.dart';
import 'package:drone_protection/services/auth_service.dart';
import 'package:drone_protection/services/location_service.dart';
import 'package:drone_protection/services/socket_service.dart';
import 'package:drone_protection/services/video_stream_service.dart';
import 'package:drone_protection/state/alert_provider.dart';
import 'package:drone_protection/state/auth_provider.dart';

void main() {
  testWidgets('affiche le formulaire de connexion par defaut', (
    WidgetTester tester,
  ) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // Autorisations considerees comme accordees (1 = PermissionStatus.granted).
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (call) async => call.method == 'checkPermissionStatus' ? 1 : null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/geolocator'),
      (call) async => call.method == 'isLocationServiceEnabled' ? true : null,
    );

    final apiClient = ApiClient();
    final socketService = SocketService();
    final authProvider = AuthProvider(
      apiClient: apiClient,
      authService: AuthService(apiClient),
      socketService: socketService,
    )..status = AuthStatus.unauthenticated;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<AlertProvider>(
            create: (_) => AlertProvider(
              alertService: AlertService(apiClient),
              locationService: LocationService(),
              socketService: socketService,
              audioStreamService: AudioStreamService(socketService),
              videoStreamService: VideoStreamService(socketService),
            ),
          ),
        ],
        child: const DronaidApp(),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Se connecter'), findsOneWidget);
  });
}
