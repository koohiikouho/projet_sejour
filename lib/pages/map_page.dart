import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:projet_sejour/widgets/team_bottom_sheet.dart';
import 'package:projet_sejour/models/team_member_model.dart';
import 'package:projet_sejour/services/location_sync_service.dart';

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
  late Stream<List<TeamMember>> _teamStream;
  StreamSubscription<List<TeamMember>>? _teamSubscription;
  PointAnnotationManager? _pointAnnotationManager;

  @override
  void initState() {
    super.initState();
    _teamStream = _syncService.getTeamLocations();
    _determinePosition();
  }

  @override
  void dispose() {
    _teamSubscription?.cancel();
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
      currentPosition = await geo.Geolocator.getCurrentPosition();
      
      // Send our position to Firestore so others can see us
      if (currentPosition != null) {
        // TODO: In a real app, 'userId', 'name', and 'role' 
        // would come from an Authentication Service.
        _syncService.updateMyLocation(
          userId: 'user_123',
          name: 'Hiro Hamada',
          role: 'Pilgrim / You',
          position: currentPosition!,
          isOnline: true,
        );
      }

      if (!mounted) return;
      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Error determining position: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    // Configure location puck to show user location
    mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        showAccuracyRing: true,
        puckBearingEnabled: true,
        puckBearing: PuckBearing.HEADING,
      ),
    );

    // Setup Point Annotations for Team Members
    _pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    
    _teamSubscription = _teamStream.listen((members) {
      _updateMapMarkers(members);
    });
  }

  void _updateMapMarkers(List<TeamMember> members) async {
    if (_pointAnnotationManager == null) return;
    
    // Clear old markers completely and redraw
    await _pointAnnotationManager!.deleteAll();
    
    final List<PointAnnotationOptions> newAnnotations = members.where((m) => m.isOnline).map((member) {
      // Create a mapbox marker for every online member
      return PointAnnotationOptions(
        geometry: Point(coordinates: Position(member.longitude, member.latitude)),
        iconSize: 2.0, // Scale
        iconImage: 'marker-15', // Temporary built-in icon until we render avatars
        textField: member.name,
        textOffset: [0.0, 1.5],
        textColor: Colors.black.value,
        textHaloColor: Colors.white.value,
        textHaloWidth: 1.0,
      );
    }).toList();

    if (newAnnotations.isNotEmpty) {
      await _pointAnnotationManager!.createMulti(newAnnotations);
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
            TeamBottomSheet(teamStream: _teamStream),
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
