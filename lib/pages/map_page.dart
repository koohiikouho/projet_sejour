import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:projet_sejour/widgets/team_bottom_sheet.dart';
import 'package:projet_sejour/models/team_member_model.dart';
import 'package:projet_sejour/services/location_sync_service.dart';
import 'package:projet_sejour/services/background_location_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projet_sejour/data/local_repository.dart';
import 'package:geocoding/geocoding.dart' as geocoder;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  MapboxMap? mapboxMap;
  geo.Position? currentPosition;
  bool isLoading = true;

  bool is3DMode = false;

  final LocationSyncService _syncService = LocationSyncService();
  StreamSubscription<List<TeamMember>>? _teamSubscription;
  StreamSubscription<Map<String, dynamic>?>? _userTeamSubscription;
  String? _currentTeamId;

  PolylineAnnotationManager? _polylineAnnotationManager;


  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _teamSubscription?.cancel();
    _userTeamSubscription?.cancel();
    _syncService.stopTrackingLocation(); // Keep for safety if any foreground streams were left
    BackgroundLocationService.stop();
    super.dispose();
  }

  void _toggleMapMode() {
    if (mapboxMap == null) return;

    setState(() {
      is3DMode = !is3DMode;
    });

    mapboxMap?.easeTo(
      CameraOptions(pitch: is3DMode ? 60.0 : 0.0),
      MapAnimationOptions(duration: 1000),
    );
  }

  Future<void> _determinePosition() async {
    try {
      // If running under `flutter test`, provide a mock coordinate to avoid
      // Geolocator MethodChannel crash.
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        if (!mounted) return;
        setState(() {
          currentPosition = geo.Position(
            longitude: 2.2945,
            latitude: 48.8584,
            timestamp: DateTime.now(),
            accuracy: 0.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          );
          isLoading = false;
        });
        return;
      }

      bool serviceEnabled;
      geo.LocationPermission permission;

      // Test if location services are enabled.
      serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => isLoading = false);
        return;
      }

      permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          if (!mounted) return;
          setState(() => isLoading = false);
          return;
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => isLoading = false);
        return;
      }

      // When we reach here, permissions are granted and we can
      // continue accessing the position of the device.
      // We add a timeout to prevent the app from freezing if the GPS hardware is stuck.
      currentPosition = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          timeLimit: Duration(seconds: 5),
        ),
      ).catchError((e) {
        // Fallback to last known position if active GPS timeout
        return geo.Geolocator.getLastKnownPosition().then((pos) {
          if (pos == null) throw Exception("Location timeout and no last known position");
          return pos;
        });
      });
      
      // Start continuously streaming our position to Firestore so others can see us move live
      if (currentPosition != null) {
        // Start the background isolate tracking
        BackgroundLocationService.start();
      }

      if (!mounted) return;
      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Error determining position: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  CircleAnnotationManager? _circleAnnotationManager;
  CircleAnnotationManager? _itineraryAnnotationManager;

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    // Configure location puck to show user location
    mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        puckBearingEnabled: true,
        puckBearing: PuckBearing.HEADING,
      ),
    );

    // Setup Circle Annotations as a reliable fallback for Team Members
    _circleAnnotationManager = await mapboxMap.annotations.createCircleAnnotationManager();
    _itineraryAnnotationManager = await mapboxMap.annotations.createCircleAnnotationManager();
    _polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();
    
    _startListeningToTeamUpdates();
    _loadTodayItinerary();
    _fetchAndDrawRouteToNextActivity();
  }

  Future<void> _fetchAndDrawRouteToNextActivity() async {
    if (currentPosition == null) return;
    final token = dotenv.env['MAPBOX_API_KEY'];
    if (token == null) return;

    final repo = LocalRepository();
    final trip = await repo.getFirstTrip();
    if (trip == null) return;

    final days = await repo.getDaysForTrip(trip.tripId);
    if (days.isEmpty) return;
    
    // For prototyping, we check the first day, but ideally this checks today's date
    final today = days.first; 
    final activities = await repo.getActivitiesForDay(today.dayId);
    
    if (activities.isEmpty) return;

    // Find the next incomplete activity
    final nextActivity = activities.firstWhere(
      (act) => !act.isCompleted, 
      orElse: () => activities.first
    );

    // Use explicit coordinates if provided, fallback to geocoding the location string
    double? targetLat = nextActivity.latitude;
    double? targetLng = nextActivity.longitude;

    if (targetLat == null || targetLng == null) {
      if (nextActivity.location.isEmpty) return;
      try {
        List<geocoder.Location> locations = await geocoder.locationFromAddress(nextActivity.location);
        if (locations.isNotEmpty) {
          targetLat = locations.first.latitude;
          targetLng = locations.first.longitude;
        }
      } catch (e) {
        debugPrint("Geocoding failed for navigation to ${nextActivity.location}: $e");
        return;
      }
    }

    if (targetLat == null || targetLng == null) return;

    final url = Uri.parse(
        'https://api.mapbox.com/directions/v5/mapbox/driving/${currentPosition!.longitude},${currentPosition!.latitude};$targetLng,$targetLat?geometries=geojson&access_token=$token');

    try {
      final response = await http.get(url);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final geometry = routes[0]['geometry'];
          final coordinates = geometry['coordinates'] as List;

          List<Position> points = coordinates.map((coord) {
            return Position(coord[0].toDouble(), coord[1].toDouble());
          }).toList();

          if (_polylineAnnotationManager != null) {
            await _polylineAnnotationManager!.deleteAll();
            if (!mounted) return;
            await _polylineAnnotationManager!.create(
              PolylineAnnotationOptions(
                geometry: LineString(coordinates: points),
                lineColor: Colors.blue.toARGB32(),
                lineWidth: 5.0,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error fetching route to next activity: $e');
      }
    }
  }

  void _startListeningToTeamUpdates() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'test_user';
    _userTeamSubscription = _syncService.streamUserTeamData(userId).listen((userData) {
      final teamId = userData?['teamId'] as String?;
      
      // If team assignment changed
      if (teamId != _currentTeamId) {
        _currentTeamId = teamId;
        _teamSubscription?.cancel();
        
        if (teamId == null) {
          // Left team, sweep the board
          _circleAnnotationManager?.deleteAll();
          _syncService.stopTrackingLocation();
        } else {
          // Joined team, rebuild streams
          _teamSubscription = _syncService.getTeamLocations(teamId).listen((members) {
            _updateMapMarkers(members, userId);
          });
          final name = FirebaseAuth.instance.currentUser?.displayName ?? 'Traveler';
          final isLeader = userData?['isTeamLeader'] as bool? ?? false;
          _syncService.startTrackingLocation(userId: userId, teamId: teamId, name: name, role: isLeader ? 'Leader' : 'Member');
        }
      }
    });
  }

  void _updateMapMarkers(List<TeamMember> members, String currentUserId) async {
    if (_circleAnnotationManager == null) return;
    
    // Clear old markers completely and redraw
    await _circleAnnotationManager!.deleteAll();
    
    // Filter out offline members AND filter out our own user ID
    // so we don't draw a red circle under our own blue location puck
    final List<CircleAnnotationOptions> newAnnotations = members
        .where((m) => m.isOnline && m.id != currentUserId)
        .map((member) {
      // Create a solid red circle marker for every online member
      return CircleAnnotationOptions(
        geometry: Point(coordinates: Position(member.longitude, member.latitude)),
        circleColor: Colors.red.toARGB32(),
        circleRadius: 8.0,
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeWidth: 2.0,
      );
    }).toList();

    if (newAnnotations.isNotEmpty) {
      await _circleAnnotationManager!.createMulti(newAnnotations);
    }
  }

  Future<void> _loadTodayItinerary() async {
    final repo = LocalRepository();
    final trip = await repo.getFirstTrip();
    if (trip == null) return;
    
    final days = await repo.getDaysForTrip(trip.tripId);
    if (days.isEmpty) return;
    
    final today = days.first; // For prototyping, always plot 'Day 1'
    final activities = await repo.getActivitiesForDay(today.dayId);
    
    List<CircleAnnotationOptions> markers = [];
    
    for (var act in activities) {
      if (act.location.isNotEmpty) {
        try {
          // Attempt Geocoding
          List<geocoder.Location> locations = await geocoder.locationFromAddress(act.location);
          if (locations.isNotEmpty) {
            markers.add(CircleAnnotationOptions(
              geometry: Point(coordinates: Position(locations.first.longitude, locations.first.latitude)),
              circleColor: Colors.purple.toARGB32(), // Purple for Itinerary
              circleRadius: 10.0,
              circleStrokeColor: Colors.white.toARGB32(),
              circleStrokeWidth: 3.0,
            ));
          }
        } catch (e) {
          debugPrint("Geocoding failed for ${act.location}: $e");
        }
      }
    }
    
    if (markers.isNotEmpty && _itineraryAnnotationManager != null) {
      await _itineraryAnnotationManager!.createMulti(markers);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Acquiring Satellite Uplink...'),
            ],
          ),
        ),
      );
    }

    if (currentPosition == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Unable to determine location. Please check your settings.',
          ),
        ),
      );
    }

    if (!Platform.isAndroid &&
        !Platform.isIOS &&
        !Platform.environment.containsKey('FLUTTER_TEST')) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Mapbox is only supported on Android and iOS. Please run the app on an emulator or a physical mobile device.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey("mapWidget"),
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(
                  currentPosition!.longitude,
                  currentPosition!.latitude,
                ),
              ),
              zoom: 14.0,
              pitch: is3DMode ? 60.0 : 0.0,
            ),
            onMapCreated: _onMapCreated,
          ),
          // Map View Toggles
            Positioned(
              top: 60,
              right: 16,
              child: Column(
                children: [
                  _buildMapActionButton(
                    icon: is3DMode
                        ? Icons.grid_view_rounded
                        : Icons.layers_outlined,
                    onTap: _toggleMapMode,
                    label: is3DMode ? '2D' : '3D',
                  ),
                ],
              ),
            ),
            // Draggable Team Members Bottom Sheet
            const TeamBottomSheet(),
          ],
      ),
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
