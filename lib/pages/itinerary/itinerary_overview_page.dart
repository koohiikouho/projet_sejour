import 'package:flutter/material.dart';
import 'package:projet_sejour/data/local_repository.dart';
import 'package:projet_sejour/models/activity.dart';
import 'package:projet_sejour/models/trip.dart';
import 'package:projet_sejour/models/itinerary_day.dart';
import 'package:projet_sejour/widgets/itinerary/timeline_card.dart';
import 'package:projet_sejour/services/sync_service.dart';
import 'package:projet_sejour/pages/itinerary/activity_details_page.dart';

class ItineraryOverviewPage extends StatefulWidget {
  const ItineraryOverviewPage({super.key});

  @override
  State<ItineraryOverviewPage> createState() => _ItineraryOverviewPageState();
}

class _ItineraryOverviewPageState extends State<ItineraryOverviewPage> {
  List<Activity> _activities = [];
  Trip? _currentTrip;
  ItineraryDay? _currentDay;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Start by loading local cache, then sync in background
    _loadActivities().then((_) => _refreshData());
  }

  Future<void> _loadActivities() async {
    try {
      final repository = LocalRepository();

      final trip = await repository.getFirstTrip();
      if (trip != null) {
        final days = await repository.getDaysForTrip(trip.tripId);
        if (days.isNotEmpty) {
          final currentDay = days.first;
          final activities = await repository.getActivitiesForDay(
            currentDay.dayId,
          );
          if (mounted) {
            setState(() {
              _currentTrip = trip;
              _currentDay = currentDay;
              _activities = activities;
              _isLoading = false;
            });
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          _activities = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error loading activities: $e');
    }
  }

  Future<void> _refreshData() async {
    try {
      final syncService = SyncService(LocalRepository());
      await syncService.syncAllData();
      await _loadActivities();
    } catch (e) {
      debugPrint('Error syncing data: $e');
    }
  }

  DateTime _toTripTimezone(DateTime date) {
    // The user's trip is in UTC+8. This forces the display to always align with UTC+8
    // regardless of the emulator's or device's current timezone setting.
    return date.toUtc().add(const Duration(hours: 8));
  }

  String _formatDate(DateTime date) {
    final tzDate = _toTripTimezone(date);
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${monthNames[tzDate.month - 1]} ${tzDate.day}, ${tzDate.year}';
  }

  String _formatTime(DateTime time) {
    final tzTime = _toTripTimezone(time);
    return '${tzTime.hour.toString().padLeft(2, '0')}:${tzTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes.abs();
    if (minutes == 0) return '0 min';
    if (minutes >= 60) {
      final int hours = minutes ~/ 60;
      final int remainingMins = minutes % 60;
      if (remainingMins == 0) {
        return '$hours hr${hours > 1 ? 's' : ''}';
      }
      return '$hours hr${hours > 1 ? 's' : ''} $remainingMins min';
    }
    return '$minutes min';
  }

  Map<String, dynamic> _mapActivityToCardData(Activity activity) {
    final tzNow = _toTripTimezone(DateTime.now());
    final tzArrival = _toTripTimezone(activity.scheduledArrival);
    final tzDeparture = _toTripTimezone(activity.scheduledDeparture);

    return {
      'id': activity.activityId,
      'time': _formatTime(activity.scheduledArrival),
      'title': activity.siteName,
      'location': activity.location,
      'description': activity.description,
      'duration': _formatDuration(activity.duration),
      'image': activity.photoUrl,
      'isPast': tzArrival.isBefore(tzNow),
      'isCurrent': tzArrival.isBefore(tzNow) && tzDeparture.isAfter(tzNow),
      'isCompleted': activity.isCompleted,
      'category': activity.category,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final int remainingCount = _activities
        .where((a) => !a.isCompleted)
        .length;
    final int totalCount = _activities.length;
    final double progress = totalCount == 0
        ? 0.0
        : (totalCount - remainingCount) / totalCount;
    final String percentage = '${(progress * 100).toInt()}%';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: colorScheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentTrip?.tripName ?? 'Your Journey',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _currentDay != null
                          ? 'Day ${_currentDay!.dayNumber} • ${_formatDate(_currentDay!.date)}'
                          : 'No active days',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Progress Indicator
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                color: colorScheme.primary.withValues(alpha: 0.05),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.circle,
                        color: colorScheme.primary,
                        size: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$remainingCount items remaining today',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        percentage,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Timeline Cards
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_activities.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No activities found for today. Swipe to refresh or check sync status.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final isLast = index == _activities.length - 1;
                    final cardData = _mapActivityToCardData(_activities[index]);
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ActivityDetailsPage(
                                  activity: _activities[index],
                                ),
                              ),
                            );
                          },
                          child: TimelineCard(item: cardData, index: index),
                        ),
                        if (!isLast) const SizedBox(height: 12),
                      ],
                    );
                  }, childCount: _activities.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
