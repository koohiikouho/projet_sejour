import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, audio }

class JournalMessage {
  final String id;
  final String dateStr;
  final DateTime timestamp;
  final MessageType type;
  final String content;
  final String? locationName;
  final List<String> searchTokens;

  JournalMessage({
    required this.id,
    required this.dateStr,
    required this.timestamp,
    required this.type,
    required this.content,
    this.locationName,
    required this.searchTokens,
  });

  factory JournalMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JournalMessage(
      id: doc.id,
      dateStr: data['dateStr'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${data['type']}',
        orElse: () => MessageType.text,
      ),
      content: data['content'] ?? '',
      locationName: data['locationName'],
      searchTokens: List<String>.from(data['searchTokens'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateStr': dateStr,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.toString().split('.').last,
      'content': content,
      'locationName': locationName,
      'searchTokens': searchTokens,
    };
  }
}
