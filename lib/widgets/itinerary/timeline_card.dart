import 'package:flutter/material.dart';

class TimelineCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;

  const TimelineCard({
    super.key,
    required this.item,
    required this.index,
  });

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'spiritual':
        return Icons.church_rounded;
      case 'transport':
        return Icons.directions_bus_rounded;
      case 'tour':
        return Icons.tour_rounded;
      case 'meal':
        return Icons.restaurant_rounded;
      case 'cultural':
        return Icons.museum_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCurrent = item['isCurrent'] as bool;
    final isPast = item['isPast'] as bool;
    final categoryIcon = _getCategoryIcon(item['category'] ?? '');

    return Card(
      elevation: isCurrent ? 4 : 2,
      shadowColor: isCurrent ? colorScheme.primary.withValues(alpha: 0.3) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isCurrent
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time and Icon Column
            Column(
              children: [
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? colorScheme.primary
                        : isPast
                        ? Colors.grey.withValues(alpha: 0.1)
                        : colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item['time'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCurrent
                          ? Colors.white
                          : isPast
                          ? Colors.grey
                          : colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPast
                        ? Colors.grey.withValues(alpha: 0.1)
                        : colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    categoryIcon,
                    size: 20,
                    color: isPast
                        ? Colors.grey
                        : colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['title'],
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                            fontSize: 16,
                            decoration: isPast ? TextDecoration.lineThrough : null,
                            decorationColor: Colors.grey,
                            color: isPast ? Colors.grey : null,
                          ),
                        ),
                      ),
                      if (item['duration'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item['duration'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: isPast ? Colors.grey : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item['location'],
                          style: TextStyle(
                            fontSize: 13,
                            color: isPast ? Colors.grey : Colors.grey[700],
                            decoration: isPast ? TextDecoration.lineThrough : null,
                            decorationColor: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['description'],
                    style: TextStyle(
                      fontSize: 13,
                      color: isPast ? Colors.grey : Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item['guide'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 10,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Guide: ${item['guide']}',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
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