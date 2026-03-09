import 'package:flutter/material.dart';

class ItineraryDetailPage extends StatelessWidget {
  final String date;

  const ItineraryDetailPage({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Itinerary Details'),
      ),
      body: Center(
        child: Text('Details for $date'),
      ),
    );
  }
}