class ItineraryDay {
  final String dayId;
  final String tripId; // Foreign Key for SQLite
  final int dayNumber;
  final DateTime date;

  ItineraryDay({
    required this.dayId,
    required this.tripId,
    required this.dayNumber,
    required this.date,
  });

  Map<String, dynamic> toSqlite() => {
        'dayId': dayId,
        'tripId': tripId,
        'dayNumber': dayNumber,
        'date': date.toIso8601String(),
      };

  factory ItineraryDay.fromSqlite(Map<String, dynamic> map) {
    return ItineraryDay(
      dayId: map['dayId'] as String,
      tripId: map['tripId'] as String,
      dayNumber: map['dayNumber'] as int,
      date: DateTime.parse(map['date'] as String),
    );
  }
}
