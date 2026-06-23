import 'dart:convert';
import 'package:http/http.dart' as http;

class GeolocationService {
  /// Пытается получить город через IP (работает без Google Play Services)
  Future<String?> getCurrentCity() async {
    try {
      // Используем бесплатный сервис ip-api.com (не требует ключа)
      final response = await http.get(
        Uri.parse('http://ip-api.com/json?fields=city&lang=ru'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final city = data['city'] as String?;
        if (city != null && city.isNotEmpty) {
          return city;
        }
      }
    } catch (e) {
      // Если IP-сервис недоступен — возвращаем null
    }
    return null;
  }

  Future<bool> isLocationEnabled() async {
    // Всегда true — IP-геолокация не требует GPS
    return true;
  }
}
