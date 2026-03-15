import 'package:cloud_firestore/cloud_firestore.dart';

class TeamInfo {
  final String id;
  final String name;
  final String teamCode;
  final int memberCount;
  final String createdBy;
  final DateTime createdAt;

  TeamInfo({
    required this.id,
    required this.name,
    required this.teamCode,
    required this.memberCount,
    required this.createdBy,
    required this.createdAt,
  });

  factory TeamInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamInfo(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Team',
      teamCode: data['teamCode'] ?? '',
      memberCount: data['memberCount'] ?? 0,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
