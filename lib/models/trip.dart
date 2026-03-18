class Trip {
  final String tripId;
  final String tripName;
  final DateTime startDate;
  final DateTime endDate;
  final String status;

  Trip({
    required this.tripId,
    required this.tripName,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  Map<String, dynamic> toSqlite() => {
        'tripId': tripId,
        'tripName': tripName,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'status': status,
      };

  factory Trip.fromSqlite(Map<String, dynamic> map) {
    return Trip(
      tripId: map['tripId'] as String,
      tripName: map['tripName'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      status: map['status'] as String,
    );
  }
}
