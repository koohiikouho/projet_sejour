import 'package:flutter/material.dart';
import 'package:projet_sejour/models/activity.dart';

class ActivityDetailsPage extends StatelessWidget {
  final Activity activity;

  const ActivityDetailsPage({super.key, required this.activity});

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(activity.siteName),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (activity.photoUrl.isNotEmpty)
              Image.network(
                activity.photoUrl,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          activity.siteName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          activity.categoryIcon,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Time and Date
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatTime(activity.scheduledArrival)} - ${_formatTime(activity.scheduledDeparture)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(activity.scheduledArrival),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          activity.location,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity.description,
                    style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // What to bring
                  if (activity.whatToBring.isNotEmpty) ...[
                    const Text(
                      'What to Bring',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...activity.whatToBring.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: colorScheme.primary, size: 18),
                          const SizedBox(width: 8),
                          Text(item, style: const TextStyle(fontSize: 15)),
                        ],
                      ),
                    )),
                    const SizedBox(height: 24),
                  ],

                  // Mobility Rating
                  if (activity.mobilityRating.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mobility Rating: ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Text(
                            activity.mobilityRating,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
