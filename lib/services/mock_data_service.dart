import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projet_sejour/services/sync_service.dart';
import 'package:projet_sejour/data/local_repository.dart';
import 'package:geocoding/geocoding.dart' as geocoder;

class MockDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> generateDummyItinerary(String userId) async {
    final tripId = 'dummy_trip_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Create a Trip
    await _firestore.collection('trips').doc(tripId).set({
      'tripName': 'European Adventure',
      'startDate': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'endDate': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
      'status': 'active',
      'ownerId': userId,
    });

    final tripRef = _firestore.collection('trips').doc(tripId);

    // 2. Create today's Itinerary Day
    final dayId = 'day_1_${DateTime.now().millisecondsSinceEpoch}';
    await tripRef.collection('itineraryDays').doc(dayId).set({
      'dayNumber': 1,
      'date': DateTime.now().toIso8601String(),
    });

    final dayRef = tripRef.collection('itineraryDays').doc(dayId);

    // 3. Create Activities for Today
    final activities = [
      {
        'siteName': 'Eiffel Tower Visit',
        'description': 'Enjoy a guided tour of the iconic Eiffel Tower.',
        'photoUrl': 'https://images.unsplash.com/photo-1511739001486-6bfe10ce785f?auto=format&fit=crop&q=80&w=1000',
        'category': 'destination',
        'mobilityRating': 'Moderate',
        'latitude': 48.8584,
        'longitude': 2.2945,
        'scheduledArrival': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        'scheduledDeparture': DateTime.now().add(const Duration(hours: 3)).toIso8601String(),
        'whatToBring': [
          {'title': 'Camera', 'isChecked': false},
          {'title': 'Comfortable shoes', 'isChecked': false},
          {'title': 'Water bottle', 'isChecked': false},
        ],
        'lastUpdatedAt': DateTime.now().toIso8601String(),
        'isCompleted': false,
      },
      {
        'siteName': 'Louvre Museum',
        'description': 'Explore the world\'s largest art museum.',
        'photoUrl': 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?auto=format&fit=crop&q=80&w=1000',
        'category': 'destination',
        'mobilityRating': 'High walking',
        'latitude': 48.8606,
        'longitude': 2.3376,
        'scheduledArrival': DateTime.now().add(const Duration(hours: 4)).toIso8601String(),
        'scheduledDeparture': DateTime.now().add(const Duration(hours: 7)).toIso8601String(),
        'whatToBring': [
          {'title': 'Museum Pass', 'isChecked': false},
        ],
        'lastUpdatedAt': DateTime.now().toIso8601String(),
        'isCompleted': false,
      },
    ];

    for (var i = 0; i < activities.length; i++) {
      var act = Map<String, dynamic>.from(activities[i]);
      
      try {
        double lat = act['latitude'] as double;
        double lng = act['longitude'] as double;
        List<geocoder.Placemark> placemarks = await geocoder.placemarkFromCoordinates(lat, lng);
        
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final name = p.name ?? '';
          final city = p.locality ?? p.subAdministrativeArea ?? '';
          final country = p.country ?? '';
          
          List<String> parts = [];
          // Avoid duplicating name if it matches city exactly
          if (name.isNotEmpty && name.toLowerCase() != city.toLowerCase()) parts.add(name);
          if (city.isNotEmpty) parts.add(city);
          if (country.isNotEmpty) parts.add(country);
          
          act['location'] = parts.join(', ');
        } else {
          act['location'] = 'Unknown Location ($lat, $lng)';
        }
      } catch (e) {
        act['location'] = 'Location Error';
      }
      
      await dayRef.collection('activities').doc('activity_$i').set(act);
    }

    // After creating dummy data, force a sync to load it locally so it shows up instantly
    final localRepo = LocalRepository();
    final syncService = SyncService(localRepo);
    await syncService.syncAllData();
  }
}
