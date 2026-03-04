import 'package:flutter/material.dart';
import 'package:projet_sejour/models/itinerary_item.dart';

class TimelineItem extends StatelessWidget {
  final ItineraryItem item;

  const TimelineItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final Color lineColor = item.isPast
        ? Theme.of(context).colorScheme.primary
        : Colors.grey.withValues(alpha: 0.3);
    final Color dotColor = item.isCurrent
        ? Theme.of(context).colorScheme.secondary
        : lineColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time Column
          SizedBox(
            width: 50,
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  item.time,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: item.isCurrent
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: item.isCurrent
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Line & Dot Column
          SizedBox(
            width: 12,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 18,
                  bottom: 0,
                  width: 2,
                  child: Container(color: lineColor),
                ),
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: item.isCurrent
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: item.isCurrent
                          ? Theme.of(context).colorScheme.primary
                          : dotColor,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Content Column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: item.isCurrent
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 16,
                      color: item.isPast
                          ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.location,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
