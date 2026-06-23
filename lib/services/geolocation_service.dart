import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class GeolocationService {
  Future<String?> getCurrentCity() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return placemark.locality ?? placemark.subAdministrativeArea ?? placemark.administrativeArea;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
}
