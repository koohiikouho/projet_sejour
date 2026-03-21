import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String username;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final int? age;
  final String? department;
  final List<String>? languages;
  final String? role;
  final DateTime? createdAt;

  UserProfile({
    required this.uid,
    required this.username,
    this.email,
    this.avatarUrl,
    this.bio,
    this.age,
    this.department,
    this.languages,
    this.role,
    this.createdAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      username: data['username'] ?? 'Anonymous',
      email: data['email'],
      avatarUrl: data['avatarUrl'],
      bio: data['bio'],
      age: data['age'],
      department: data['department'],
      languages: (data['languages'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      role: data['role'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'age': age,
      'department': department,
      'languages': languages,
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserProfile copyWith({
    String? username,
    String? avatarUrl,
    String? bio,
    int? age,
    String? department,
    List<String>? languages,
  }) {
    return UserProfile(
      uid: uid,
      username: username ?? this.username,
      email: email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      age: age ?? this.age,
      department: department ?? this.department,
      languages: languages ?? this.languages,
      role: role,
      createdAt: createdAt,
    );
  }
}
