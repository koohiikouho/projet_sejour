class ItineraryItem {
  final String time;
  final String title;
  final String location;
  final bool isPast;
  final bool isCurrent;
  final bool isCompleted;

  ItineraryItem({
    required this.time,
    required this.title,
    required this.location,
    this.isPast = false,
    this.isCurrent = false,
    this.isCompleted = false,
  });
}
