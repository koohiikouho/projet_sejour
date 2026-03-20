import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ActivityGuide {
  final String id;
  final String title;
  final String location;
  final String category;
  final String content;
  final List<String> mediaUrls;
  final DateTime lastUpdated;

  ActivityGuide({
    required this.id,
    required this.title,
    required this.location,
    required this.category,
    required this.content,
    this.mediaUrls = const [],
    required this.lastUpdated,
  });

  factory ActivityGuide.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return ActivityGuide(
        id: doc.id,
        title: data['title'] ?? 'Untitled Guide',
        location: data['location'] ?? 'General',
        category: data['category'] ?? 'General',
        content: data['content'] ?? '',
        mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
        lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint("Error parsing ActivityGuide ${doc.id}: $e");
      return ActivityGuide(
        id: doc.id,
        title: 'Error Loading Guide',
        location: 'System',
        category: 'Error',
        content: 'Malformed data in Firestore. Please contact admin.',
        lastUpdated: DateTime.now(),
      );
    }
  }
}

class GuideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  GuideService();

  CollectionReference _getGuidesCollection() {
    return _firestore.collection('activity_guides');
  }

  // Stream all guides, automatically utilizing offline cache if disconnected
  Stream<List<ActivityGuide>> streamGuides({String? categoryFilter, String? locationFilter}) {
    Query query = _getGuidesCollection();

    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      query = query.where('category', isEqualTo: categoryFilter);
    }
    if (locationFilter != null && locationFilter.isNotEmpty) {
      query = query.where('location', isEqualTo: locationFilter);
    }

    return query
        .orderBy('title')
        .snapshots(includeMetadataChanges: true) // Important for seeing cache vs server changes
        .map((snapshot) => snapshot.docs.map((doc) => ActivityGuide.fromFirestore(doc)).toList());
  }

  // Generate seed data so the user can test the views immediately
  Future<void> seedInitialGuides() async {
    final collection = _getGuidesCollection();
    final snapshot = await collection.limit(1).get();
    
    // Only seed if empty
    if (snapshot.docs.isEmpty) {
      debugPrint("Seeding initial Activity Guides...");
      
      final guides = [
        {
          'title': 'How to Navigate the Paris Metro',
          'location': 'Paris, France',
          'category': 'Logistical',
          'content': 'A comprehensive guide to buying tickets, scanning through turnstiles, and identifying your correct line color and direction.',
          'mediaUrls': ['https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Paris_metro_ticket.jpg/800px-Paris_metro_ticket.jpg'],
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        {
          'title': 'History of Notre Dame',
          'location': 'Paris, France',
          'category': 'Historical',
          'content': 'Discover the gothic architecture and the recent restoration efforts after the 2019 fire.',
          // Sample free audio file indicating a lecture
          'mediaUrls': ['https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'],
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Basic French Phrases',
          'location': 'France',
          'category': 'Phrasebook',
          'content': '1. Bonjour - Hello\n2. Merci - Thank you\n3. S\'il vous plaît - Please',
          'mediaUrls': [],
          'lastUpdated': FieldValue.serverTimestamp(),
        }
      ];

      for (var guide in guides) {
        await collection.add(guide);
      }
    }
  }
}
