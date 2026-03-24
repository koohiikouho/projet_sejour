import 'package:flutter/material.dart';
import 'package:projet_sejour/models/activity.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:projet_sejour/services/weather_service.dart';
import 'package:projet_sejour/data/local_repository.dart';

class ActivityDetailsPage extends StatefulWidget {
  final Activity activity;

  const ActivityDetailsPage({super.key, required this.activity});

  @override
  State<ActivityDetailsPage> createState() => _ActivityDetailsPageState();
}

class _ActivityDetailsPageState extends State<ActivityDetailsPage> {
  final WeatherService _weatherService = WeatherService();
  WeatherData? _weatherData;
  bool _isLoadingWeather = true;
  late Activity _currentActivity;

  @override
  void initState() {
    super.initState();
    _currentActivity = widget.activity;
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    if (_currentActivity.location.isEmpty) {
      setState(() => _isLoadingWeather = false);
      return;
    }

    try {
      WeatherData weather;
      if (_currentActivity.latitude != null && _currentActivity.longitude != null) {
        weather = await _weatherService.getWeatherData(
          _currentActivity.latitude!,
          _currentActivity.longitude!,
        );
      } else {
        weather = await _weatherService.getWeatherDataByCity(_currentActivity.location);
      }
      if (mounted) {
        setState(() {
          _weatherData = weather;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching weather: $e');
      if (mounted) {
        setState(() => _isLoadingWeather = false);
      }
    }
  }

  Future<void> _toggleTodoItem(int index, bool? value) async {
    if (value == null) return;

    setState(() {
      _currentActivity.whatToBring[index].isChecked = value;
    });

    final repo = LocalRepository();
    await repo.insertOrUpdateActivity(_currentActivity);
  }

  DateTime _toTripTimezone(DateTime date) {
    return date.toUtc().add(const Duration(hours: 8));
  }

  String _formatTime(DateTime time) {
    final tzTime = _toTripTimezone(time);
    return '${tzTime.hour.toString().padLeft(2, '0')}:${tzTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final tzDate = _toTripTimezone(date);
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${monthNames[tzDate.month - 1]} ${tzDate.day}, ${tzDate.year}';
  }

  IconData _getConditionIcon(WeatherCondition? condition) {
    switch (condition) {
      case WeatherCondition.clear:
        return Icons.wb_sunny_rounded;
      case WeatherCondition.clouds:
        return Icons.cloud_rounded;
      case WeatherCondition.rain:
      case WeatherCondition.drizzle:
        return Icons.water_drop_rounded;
      case WeatherCondition.snow:
        return Icons.ac_unit_rounded;
      case WeatherCondition.thunderstorm:
        return Icons.flash_on_rounded;
      case WeatherCondition.mist:
        return Icons.waves_rounded;
      default:
        return Icons.wb_cloudy_rounded;
    }
  }

  String _getConditionText(WeatherCondition? condition) {
    if (condition == null) return '--';
    String name = condition.name;
    return name[0].toUpperCase() + name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentActivity.siteName),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_currentActivity.photoUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: _currentActivity.photoUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                maxWidthDiskCache: 800,
                memCacheWidth: 800,
                placeholder: (context, url) => Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  ),
                ),
              ),
            
            // Weather Header
            if (_isLoadingWeather)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_weatherData != null)
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _weatherData!.cityName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            '${_weatherData!.temperature.toStringAsFixed(1)}°C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            _getConditionText(_weatherData!.condition),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _getConditionIcon(_weatherData!.condition),
                      size: 64,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _currentActivity.siteName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _currentActivity.categoryIcon,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Time and Date
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${_formatTime(_currentActivity.scheduledArrival)} - ${_formatTime(_currentActivity.scheduledDeparture)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDate(_currentActivity.scheduledArrival),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentActivity.location,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentActivity.description,
                    style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // What to bring
                  if (_currentActivity.whatToBring.isNotEmpty) ...[
                    const Text(
                      'What to Bring',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._currentActivity.whatToBring.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: item.isChecked 
                            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
                            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: item.isChecked 
                              ? colorScheme.primary.withValues(alpha: 0.5)
                              : Colors.transparent,
                          ),
                        ),
                        child: CheckboxListTile(
                          value: item.isChecked,
                          onChanged: (val) => _toggleTodoItem(index, val),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 15,
                              decoration: item.isChecked ? TextDecoration.lineThrough : null,
                              color: item.isChecked ? Colors.grey[600] : colorScheme.onSurface,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: colorScheme.primary,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // Mobility Rating
                  if (_currentActivity.mobilityRating.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mobility Rating: ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Text(
                            _currentActivity.mobilityRating,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
