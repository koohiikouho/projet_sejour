import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum WeatherCondition {
  clear,
  clouds,
  rain,
  snow,
  thunderstorm,
  drizzle,
  mist,
  other
}

class WeatherData {
  final double temperature;
  final WeatherCondition condition;
  final String cityName;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.cityName,
  });
}

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<WeatherData> getWeatherData(double lat, double lon) async {
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'];

    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_OPENWEATHER_API_KEY') {
      // Mock data if no API key is provided
      print('Using mock weather data (no API key found)');
      return WeatherData(
        temperature: 18.0,
        condition: WeatherCondition.rain,
        cityName: "Mock Location",
      );
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherData(
          temperature: (data['main']['temp'] as num).toDouble(),
          condition: _mapCondition(data['weather'][0]['main']),
          cityName: data['name'],
        );
      } else if (response.statusCode == 401) {
        print('Weather Service: 401 Unauthorized. Using mock data.');
        return WeatherData(
          temperature: 20.0,
          condition: WeatherCondition.clear,
          cityName: "Mock (Invalid API Key)",
        );
      } else {
        final errorData = jsonDecode(response.body);
        print('Weather Registry Error (${response.statusCode}): ${errorData['message']}');
        throw Exception('API Error: ${errorData['message']}');
      }
    } catch (e) {
      print('Weather Service Exception: $e');
      // If we are here, something went wrong with the network or API
      return WeatherData(
        temperature: 0.0,
        condition: WeatherCondition.other,
        cityName: "Error: ${e.toString().split(':').last.trim()}",
      );
    }
  }

  WeatherCondition _mapCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return WeatherCondition.clear;
      case 'clouds':
        return WeatherCondition.clouds;
      case 'rain':
        return WeatherCondition.rain;
      case 'snow':
        return WeatherCondition.snow;
      case 'thunderstorm':
        return WeatherCondition.thunderstorm;
      case 'drizzle':
        return WeatherCondition.drizzle;
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return WeatherCondition.mist;
      default:
        return WeatherCondition.other;
    }
  }
}
