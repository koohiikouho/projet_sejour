import 'package:flutter/material.dart';
import 'package:projet_sejour/data/mock_data.dart';
import 'package:projet_sejour/models/announcement.dart';
import 'package:projet_sejour/widgets/announcement_card.dart';

class AllAnnouncementsPage extends StatefulWidget {
  const AllAnnouncementsPage({super.key});

  @override
  State<AllAnnouncementsPage> createState() => _AllAnnouncementsPageState();
}

class _AllAnnouncementsPageState extends State<AllAnnouncementsPage> {
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    List<Announcement> filteredList = mockAnnouncements.where((ann) {
      final matchesSearch =
          ann.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ann.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter =
          _selectedFilter == 'all' || ann.type.name == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Announcements',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search announcements...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Important', 'important'),
                const SizedBox(width: 8),
                _buildFilterChip('Alert', 'alert'),
                const SizedBox(width: 8),
                _buildFilterChip('Info', 'info'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: AnnouncementCard(announcement: filteredList[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      selectedColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.black87,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    );
  }
}
