import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:projet_sejour/models/journal_message.dart';

class JournalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return FirebaseAuth.instance.currentUser?.uid ?? prefs.getString('auth_token') ?? 'anonymous';
  }

  CollectionReference _getMessagesCollection(String userId) {
    return _firestore.collection('journals').doc(userId).collection('messages');
  }

  // Helper to generate search tokens from text and location
  List<String> _generateTokens(String content, String? location) {
    final Set<String> tokens = {};
    
    // Add words from content
    final contentWords = content.toLowerCase().split(RegExp(r'\s+'));
    tokens.addAll(contentWords.where((w) => w.isNotEmpty));
    
    // Add words from location
    if (location != null) {
      final locWords = location.toLowerCase().split(RegExp(r'\s+'));
      tokens.addAll(locWords.where((w) => w.isNotEmpty));
    }
    
    return tokens.toList();
  }

  // Attempt to get a basic location string from Geolocator (just lat/long for now if no geocoder)
  Future<String?> _getCurrentLocationString() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      
      if (permission == LocationPermission.deniedForever) return null;

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
      
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, 
          position.longitude
        ).timeout(const Duration(seconds: 3));
        
        if (placemarks.isNotEmpty) {
          final place = placemarks[0];
          final city = place.locality ?? place.subAdministrativeArea ?? 'Unknown';
          return "in $city";
        }
      } catch (e) {
        debugPrint("Geocoding failed: $e");
      }

      // Fallback to coordinates
      return "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
    } catch (_) {
      return null;
    }
  }

  // Sends a text message
  Future<void> sendTextMessage(String text, String dateStr) async {
    if (text.trim().isEmpty) return;
    final userId = await _getUserId();
    final location = await _getCurrentLocationString();
    
    await _getMessagesCollection(userId).add({
      'dateStr': dateStr,
      'timestamp': Timestamp.now(),
      'type': MessageType.text.toString().split('.').last,
      'content': text.trim(),
      'locationName': location,
      'searchTokens': _generateTokens(text, location),
    });
  }

  // Uploads a media file (image/audio) and saves as a message
  Future<void> sendMediaMessage(File file, MessageType type, String dateStr) async {
    final originalUserId = await _getUserId();
    final userId = originalUserId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final sanitizedDate = dateStr.replaceAll(RegExp(r'[^0-9\-]'), '');
    final location = await _getCurrentLocationString();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final typeStr = type.toString().split('.').last;
    final ext = file.path.split('.').last;
    
    // Upload to Firebase Storage
    final path = 'journals/$userId/$sanitizedDate/${timestamp}_$typeStr.$ext';
    final ref = _storage.ref().child(path);
    debugPrint('Uploading to: ${ref.fullPath}');
    
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    
    if (downloadUrl == null) throw Exception("Failed to retrieve download URL.");
    
    final tokens = _generateTokens(typeStr, location);

    await _getMessagesCollection(originalUserId).add({
      'dateStr': dateStr,
      'timestamp': Timestamp.now(),
      'type': typeStr,
      'content': downloadUrl,
      'locationName': location,
      'searchTokens': tokens,
    });
  }

  // Fetch unique dates (chats) that have messages
  Future<List<String>> getActiveChatDates() async {
    final userId = await _getUserId();
    final snapshot = await _getMessagesCollection(userId).orderBy('dateStr', descending: true).get();
    
    final Set<String> uniqueDates = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      final dateStr = data?['dateStr'] as String?;
      if (dateStr != null) uniqueDates.add(dateStr);
    }
    return uniqueDates.toList();
  }

  // Stream messages for a specific day
  Stream<List<JournalMessage>> getMessagesForDate(String dateStr) async* {
    final userId = await _getUserId();
    yield* _getMessagesCollection(userId)
        .where('dateStr', isEqualTo: dateStr)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs.map((doc) => JournalMessage.fromFirestore(doc)).toList();
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messages;
        });
  }

  // Search messages across all dates
  Future<List<JournalMessage>> searchMessages(String query) async {
    final userId = await _getUserId();
    if (query.trim().isEmpty) return [];

    final queryLower = query.toLowerCase().trim();
    // A simplified array-contains search (works for single terms well)
    // For more complex querying, we would filter client-side or use Algolia
    
    // First try 'array-contains'
    var snapshot = await _getMessagesCollection(userId)
        .where('searchTokens', arrayContains: queryLower)
        .limit(50)
        .get();
        
    List<JournalMessage> results = snapshot.docs.map((doc) => JournalMessage.fromFirestore(doc)).toList();

    // If we want a simple client-side filter fallback that matches substrings
    if (results.isEmpty) {
      final allSnapshot = await _getMessagesCollection(userId).get();
      results = allSnapshot.docs.map((d) => JournalMessage.fromFirestore(d)).where((msg) {
        return msg.content.toLowerCase().contains(queryLower) || 
               (msg.locationName != null && msg.locationName!.toLowerCase().contains(queryLower)) ||
               msg.dateStr.contains(queryLower);
      }).toList();
    }

    // Sort all results by timestamp descending
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return results;
  }
}
