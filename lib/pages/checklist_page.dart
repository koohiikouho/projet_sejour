import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:projet_sejour/models/checklist_item.dart';
import 'package:projet_sejour/services/weather_service.dart';

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({super.key});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  final WeatherService _weatherService = WeatherService();
  WeatherData? _weatherData;
  bool _isLoading = true;
  String? _errorMessage;

  List<ChecklistItem> _checklist = [
    ChecklistItem(id: '1', title: 'Passport / ID Card'),
    ChecklistItem(id: '2', title: 'Pilgrim Credential'),
    ChecklistItem(id: '3', title: 'Comfortable Walking Shoes'),
    ChecklistItem(id: '4', title: 'Water Bottle'),
    ChecklistItem(id: '5', title: 'First Aid Kit'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchWeatherAndSyncChecklist();
  }

  Future<void> _fetchWeatherAndSyncChecklist() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 1. Get Location
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition();

      // 2. Get Weather
      final weather = await _weatherService.getWeatherData(
        position.latitude,
        position.longitude,
      );

      // 3. Update Checklist based on weather
      _updateChecklist(weather);

      setState(() {
        _weatherData = weather;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('ChecklistPage Error: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      
      // Fallback: sync with default null weather to show basic items
      _updateChecklist(null);
    }
  }

  void _updateChecklist(WeatherData? weather) {
    // Basic items that stay
    final filteredList = _checklist.where((item) => item.category == ChecklistCategory.always).toList();

    if (weather == null) {
      setState(() {
        _checklist = filteredList;
      });
      return;
    }

    // Add weather-dependent items if they don't already exist
    if (weather.condition == WeatherCondition.rain || 
        weather.condition == WeatherCondition.thunderstorm || 
        weather.condition == WeatherCondition.drizzle) {
      _addIfMissing(filteredList, 'Umbrella', ChecklistCategory.rain);
      _addIfMissing(filteredList, 'Waterproof Jacket', ChecklistCategory.rain);
    }

    if (weather.temperature > 25) {
      _addIfMissing(filteredList, 'Sunscreen', ChecklistCategory.hot);
      _addIfMissing(filteredList, 'Hat', ChecklistCategory.hot);
    } else if (weather.temperature < 10) {
      _addIfMissing(filteredList, 'Warm Gloves', ChecklistCategory.cold);
      _addIfMissing(filteredList, 'Scarf', ChecklistCategory.cold);
    }

    setState(() {
      _checklist = filteredList;
    });
  }

  void _addIfMissing(List<ChecklistItem> list, String title, ChecklistCategory cat) {
    if (!list.any((item) => item.title == title)) {
      list.add(ChecklistItem(
        id: DateTime.now().millisecondsSinceEpoch.toString() + title,
        title: title,
        category: cat,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Travel Checklist',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: colorScheme.primary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
                  slivers: [
                    // Error Warning Banner (Non-blocking)
                    if (_errorMessage != null)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: colorScheme.error),
                              const SizedBox(width: 12),
                               Expanded(
                                child: Text(
                                  'Note: Weather items hidden due to error (${_errorMessage!.split(':').last.trim()}).',
                                  style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 20),
                                onPressed: _fetchWeatherAndSyncChecklist,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Weather Header
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(16),
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
                                    _weatherData?.cityName ?? 'Unknown',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  Text(
                                    '${_weatherData?.temperature.toStringAsFixed(1)}°C',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    _getConditionText(_weatherData?.condition),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              _getConditionIcon(_weatherData?.condition),
                              size: 64,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Checklist items
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _checklist[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: item.isChecked 
                                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
                                : colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: item.isChecked 
                                  ? Colors.transparent 
                                  : colorScheme.outlineVariant,
                              ),
                            ),
                            child: CheckboxListTile(
                              value: item.isChecked,
                              onChanged: (val) {
                                setState(() {
                                  item.isChecked = val ?? false;
                                });
                              },
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  decoration: item.isChecked ? TextDecoration.lineThrough : null,
                                  fontWeight: item.isChecked ? FontWeight.normal : FontWeight.w600,
                                ),
                              ),
                              secondary: Icon(
                                _getCategoryIcon(item.category),
                                color: item.isChecked ? Colors.grey : colorScheme.primary,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          );
                        },
                        childCount: _checklist.length,
                      ),
                    ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
                  ],
                ),
    );
  }

  String _getConditionText(WeatherCondition? condition) {
    if (condition == null) return 'N/A';
    return condition.name[0].toUpperCase() + condition.name.substring(1);
  }

  IconData _getConditionIcon(WeatherCondition? condition) {
    switch (condition) {
      case WeatherCondition.clear: return Icons.wb_sunny;
      case WeatherCondition.clouds: return Icons.cloud;
      case WeatherCondition.rain:
      case WeatherCondition.drizzle: return Icons.beach_access;
      case WeatherCondition.thunderstorm: return Icons.thunderstorm;
      case WeatherCondition.snow: return Icons.ac_unit;
      default: return Icons.cloud_queue;
    }
  }

  IconData _getCategoryIcon(ChecklistCategory cat) {
    switch (cat) {
      case ChecklistCategory.rain: return Icons.umbrella;
      case ChecklistCategory.hot: return Icons.wb_sunny_outlined;
      case ChecklistCategory.cold: return Icons.ac_unit_outlined;
      default: return Icons.check_circle_outline;
    }
  }
}
