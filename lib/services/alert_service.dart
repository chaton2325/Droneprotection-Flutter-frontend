import '../models/alert.dart';
import 'api_client.dart';

class AlertService {
  final ApiClient _client;
  AlertService(this._client);

  Future<EmergencyAlert> create({
    double? latitude,
    double? longitude,
    double? accuracy,
    String? message,
  }) async {
    final data = await _client.post('/alerts', body: {
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (message != null) 'message': message,
    });
    return EmergencyAlert.fromJson(data['alert']);
  }

  Future<EmergencyAlert> sendLocation(
    int alertId, {
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    final data = await _client.post('/alerts/$alertId/location', body: {
      'latitude': latitude,
      'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
    });
    return EmergencyAlert.fromJson(data['alert']);
  }

  Future<EmergencyAlert> cancel(int alertId) async {
    final data = await _client.post('/alerts/$alertId/cancel');
    return EmergencyAlert.fromJson(data['alert']);
  }

  Future<EmergencyAlert> resolve(int alertId) async {
    final data = await _client.post('/alerts/$alertId/resolve');
    return EmergencyAlert.fromJson(data['alert']);
  }

  Future<List<EmergencyAlert>> listMine() async {
    final data = await _client.get('/alerts', query: {'scope': 'mine'});
    return (data['alerts'] as List)
        .map((json) => EmergencyAlert.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
