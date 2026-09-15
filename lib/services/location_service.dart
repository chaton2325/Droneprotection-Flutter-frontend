import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationServiceException implements Exception {
  final String message;
  const LocationServiceException(this.message);

  @override
  String toString() => message;
}

class LocationService {
  /// Verifie que le service de localisation est actif et que la permission
  /// est accordee, en la demandant a l'utilisateur si necessaire.
  Future<void> ensureReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceException(
        'La localisation est desactivee sur cet appareil. Activez-la pour declencher une alerte.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationServiceException(
          "L'autorisation de localisation est requise pour envoyer votre position.",
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        "L'autorisation de localisation est bloquee. Activez-la dans les reglages de l'appareil.",
      );
    }
  }

  Future<Position> getCurrentPosition() async {
    await ensureReady();
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Resout un nom de lieu lisible ("Akwa, Douala") a partir de lat/lng, pour
  /// affichage cote repondant. Best-effort : ne doit jamais lever (pas de
  /// reseau, geocodeur indisponible sur l'appareil...), retourne juste null.
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude)
          .timeout(const Duration(seconds: 8));
      if (placemarks.isEmpty) return null;

      final placemark = placemarks.first;
      final parts = [
        if ((placemark.locality ?? '').isNotEmpty) placemark.locality,
        if ((placemark.locality ?? '').isEmpty &&
            (placemark.subAdministrativeArea ?? '').isNotEmpty)
          placemark.subAdministrativeArea,
        if ((placemark.administrativeArea ?? '').isNotEmpty)
          placemark.administrativeArea,
      ];
      if (parts.isEmpty) return null;
      return parts.join(', ');
    } catch (_) {
      return null;
    }
  }
}
