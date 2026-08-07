// core/utils/location_helper.dart
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationHelper {
  /// Fetches exact coordinates and translates them to a readable place name.
  static Future<Map<String, dynamic>?> fetchCurrentLocation() async {
    // 1. Check if the physical GPS service is enabled first
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Routes the user to device location settings to switch it on
      await Geolocator.openLocationSettings();
      throw Exception(
        'Location services are disabled. Please turn on GPS and try again.',
      );
    }

    // 2. Check the current permission status
    LocationPermission permission = await Geolocator.checkPermission();

    // 3. If denied (e.g., accidentally denied once), request it again.
    // This WILL show the OS pop-up again.
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    // 4. If permanently denied (e.g., "Don't ask again" was selected), route to App Settings
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw Exception(
        'Location permissions are permanently denied. Please enable them in settings.',
      );
    }

    // 5. Fetch the position safely now that all checks have passed
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      String name = [
        place.subLocality,
        place.locality,
        place.administrativeArea,
      ].where((e) => e != null && e.isNotEmpty).join(', ');

      return {
        'name': name.isEmpty ? 'Unknown Location' : name,
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    }
    return null;
  }

  /// Safely redirects to Google Maps using the exact coordinates.
  static Future<void> openMap(double lat, double lng) async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    try {
      // Bypass canLaunchUrl checks and force external application mode first
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback to internal web view if external Maps app fails
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      throw Exception('Could not launch map: $e');
    }
  }
}
