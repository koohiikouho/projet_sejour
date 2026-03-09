import 'package:flutter/material.dart';
import 'package:projet_sejour/data/mock_itinerary_data.dart';
import 'package:projet_sejour/widgets/itinerary/timeline_card.dart';

class ItineraryOverviewPage extends StatefulWidget {
  const ItineraryOverviewPage({super.key});

  @override
  State<ItineraryOverviewPage> createState() => _ItineraryOverviewPageState();
}

class _ItineraryOverviewPageState extends State<ItineraryOverviewPage> {
  late List<Map<String, dynamic>> _itineraryItems;

  @override
  void initState() {
    super.initState();
    _itineraryItems = MockItineraryData.detailedItinerary;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [

          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Journey',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Day 3 • Oct 12, 2026',
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
                      '4 items remaining today',
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
                      '33%',
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
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final isLast = index == _itineraryItems.length - 1;
                  return Column(
                    children: [
                      TimelineCard(
                        item: _itineraryItems[index],
                        index: index,
                      ),
                      if (!isLast) const SizedBox(height: 12),
                    ],
                  );
                },
                childCount: _itineraryItems.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}