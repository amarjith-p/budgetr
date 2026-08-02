import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationHelper {
  /// Fetches exact coordinates and translates them to a readable place name.
  static Future<Map<String, dynamic>?> fetchCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      String name = [place.subLocality, place.locality, place.administrativeArea]
          .where((e) => e != null && e.isNotEmpty)
          .join(', ');
      
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
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    
    try {
      // Bypass canLaunchUrl checks and force external application mode first
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        // Fallback to internal web view if external Maps app fails
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      throw Exception('Could not launch map: $e');
    }
  }
}