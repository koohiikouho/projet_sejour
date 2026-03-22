import 'package:flutter/material.dart';
import 'package:projet_sejour/models/itinerary_day.dart';
import 'package:projet_sejour/data/mock_data.dart';
import 'package:projet_sejour/pages/announcements/all_announcements_page.dart';
import 'package:projet_sejour/widgets/announcement_card.dart';
import 'package:projet_sejour/widgets/timeline_item.dart';
import 'package:projet_sejour/data/local_repository.dart';
import 'package:projet_sejour/models/activity.dart';
import 'package:projet_sejour/models/itinerary_item.dart';
import 'package:projet_sejour/widgets/feedback/survey_dialog.dart';
import 'package:projet_sejour/services/feedback_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Activity> _todayActivities = [];
  ItineraryDay? _currentDay;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayActivities();
    _checkFeedbackSurvey();
  }

  Future<void> _checkFeedbackSurvey() async {
    try {
      final feedbackService = FeedbackService();
      final isDue = await feedbackService.checkIfSurveyDue();
      if (isDue && mounted) {
        final periods = await feedbackService.getSurveyPeriods();
        // find current period: not answered and start is before now
        final currentPeriod = periods.lastWhere(
          (p) => !p.isAnswered && (p.start.isBefore(DateTime.now()) || p.start.day == DateTime.now().day),
          orElse: () => periods.firstWhere((p) => !p.isAnswered, orElse: () => periods.last)
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !currentPeriod.isAnswered) {
             showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => SurveyDialog(period: currentPeriod),
            ).then((value) {
              if (value != true) {
                // If dismissed without submitting
                feedbackService.dismissSurvey();
              }
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error checking survey: $e');
    }
  }

  Future<void> _loadTodayActivities() async {
    try {
      final repository = LocalRepository();
      final trip = await repository.getFirstTrip();
      if (trip != null) {
        final days = await repository.getDaysForTrip(trip.tripId);
        if (days.isNotEmpty) {
          final currentDay = days.first;
          final activities = await repository.getActivitiesForDay(currentDay.dayId);
          if (mounted) {
            setState(() {
              _todayActivities = activities;
              _currentDay = currentDay;
              _isLoading = false;
            });
          }
          return;
        }
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error loading today activities: $e');
    }
  }

  DateTime _toTripTimezone(DateTime date) {
    return date.toUtc().add(const Duration(hours: 8));
  }

  String _formatTime(DateTime time) {
    final tzTime = _toTripTimezone(time);
    return '${tzTime.hour.toString().padLeft(2, '0')}:${tzTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final tzDate = _toTripTimezone(date);
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${monthNames[tzDate.month - 1]} ${tzDate.day}, ${tzDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadTodayActivities,
      child: ListView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 24),
        children: [
          // Announcements Section
          Text(
            'Announcements',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildAnnouncementsSection(context),
          const SizedBox(height: 32),

          // Itinerary Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Itinerary',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _currentDay != null ? _formatDate(_currentDay!.date) : _formatDate(DateTime.now()),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Timeline
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_todayActivities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No activities planned for today.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._todayActivities.map((activity) {
              // Simulated "Now" on May 10 2026, 10:30 AM (UTC+8) -> 2:30 AM UTC
              final mockDeviceNow = DateTime.utc(2026, 5, 10, 2, 30);
              final tzNow = _toTripTimezone(mockDeviceNow);
              
              final tzArrival = _toTripTimezone(activity.scheduledArrival);
              final tzDeparture = _toTripTimezone(activity.scheduledDeparture);
              final isPast = tzArrival.isBefore(tzNow);
              final isCurrent = tzArrival.isBefore(tzNow) && tzDeparture.isAfter(tzNow);

              return TimelineItem(
                item: ItineraryItem(
                  time: _formatTime(activity.scheduledArrival),
                  title: activity.siteName,
                  location: activity.location,
                  isPast: isPast,
                  isCurrent: isCurrent,
                  isCompleted: activity.isCompleted,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsSection(BuildContext context) {
    final pinned = mockAnnouncements.where((ann) => ann.isPinned).toList();
    final others = mockAnnouncements
        .where((ann) => !ann.isPinned)
        .take(2)
        .toList();
    final displayList = [...pinned, ...others];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...displayList.map((ann) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: AnnouncementCard(announcement: ann),
          );
        }),
        const SizedBox(height: 4),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllAnnouncementsPage(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'See All Announcements',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
