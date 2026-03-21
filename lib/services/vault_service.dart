import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class VaultDocument {
  final String id;
  final String userId;
  final String title;
  final String category;
  final String fileUrl;
  final DateTime uploadDate;
  final bool isVerified;

  VaultDocument({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.fileUrl,
    required this.uploadDate,
    this.isVerified = false,
  });

  factory VaultDocument.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return VaultDocument(
        id: doc.id,
        userId: data['userId'] ?? '',
        title: data['title'] ?? 'Untitled',
        category: data['category'] ?? 'Uncategorized',
        fileUrl: data['fileUrl'] ?? '',
        uploadDate: (data['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isVerified: data['isVerified'] ?? false,
      );
    } catch (e) {
      debugPrint("Error parsing VaultDocument ${doc.id}: $e");
      return VaultDocument(
        id: doc.id,
        userId: '',
        title: 'Error Loading Document',
        category: 'Error',
        fileUrl: '',
        uploadDate: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'category': category,
      'fileUrl': fileUrl,
      'uploadDate': Timestamp.fromDate(uploadDate),
      'isVerified': isVerified,
    };
  }
}

class VaultService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return FirebaseAuth.instance.currentUser?.uid ?? prefs.getString('auth_token') ?? 'anonymous';
  }

  CollectionReference _getVaultCollection() {
    return _firestore.collection('vault_documents');
  }

  // Stream user's personal documents
  Stream<List<VaultDocument>> streamMyDocuments() async* {
    final userId = await _getUserId();
    yield* _getVaultCollection()
        .where('userId', isEqualTo: userId)
        .orderBy('uploadDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => VaultDocument.fromFirestore(doc)).toList());
  }

  // Stream global/shared program documents
  Stream<List<VaultDocument>> streamSharedDocuments() {
    return _getVaultCollection()
        .where('userId', isEqualTo: 'global')
        .orderBy('uploadDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => VaultDocument.fromFirestore(doc)).toList());
  }

  // Upload a new document
  Future<void> uploadDocument(File file, String title, String category, {bool isGlobal = false}) async {
    final userId = isGlobal ? 'global' : await _getUserId();
    final sanitizedUserId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = file.path.split('.').last;
    
    final path = 'vault/documents/$sanitizedUserId/${timestamp}_$title.$ext';
    final ref = _storage.ref().child(path);
    
    debugPrint('Uploading Vault Document to: ${ref.fullPath}');
    
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    
    if (snapshot.state != TaskState.success) {
      throw Exception('Document upload failed. TaskState: ${snapshot.state}');
    }
    
    final downloadUrl = await snapshot.ref.getDownloadURL();
    
    await _getVaultCollection().add({
      'userId': userId,
      'title': title,
      'category': category,
      'fileUrl': downloadUrl,
      'uploadDate': Timestamp.now(),
      'isVerified': false, // Requires admin verification later
    });
  }

  // Delete a document
  Future<void> deleteDocument(VaultDocument doc) async {
    final currentUserId = await _getUserId();
    // Basic security check: only owner can delete, unless they are admin (skipped for brevity)
    if (doc.userId != currentUserId && doc.userId != 'global') {
      throw Exception('Unauthorized to delete this document.');
    }
    
    // Delete from Firestore
    await _getVaultCollection().doc(doc.id).delete();
    
    // Attempt to delete from Storage
    try {
      final ref = _storage.refFromURL(doc.fileUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Failed to delete file from storage (might already be deleted): $e');
    }
  }
}
