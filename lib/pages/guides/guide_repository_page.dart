import 'package:flutter/material.dart';
import 'package:projet_sejour/services/guide_service.dart';
import 'package:projet_sejour/pages/guides/guide_detail_page.dart';

class GuideRepositoryPage extends StatefulWidget {
  const GuideRepositoryPage({super.key});

  @override
  State<GuideRepositoryPage> createState() => _GuideRepositoryPageState();
}

class _GuideRepositoryPageState extends State<GuideRepositoryPage> {
  final GuideService _guideService = GuideService();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  
  final List<String> _categories = ['All', 'Historical', 'Logistical', 'Phrasebook', 'Safety'];

  @override
  void initState() {
    super.initState();
    // In a real app, this might be triggered by an admin or on first launch
    _guideService.seedInitialGuides();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Guides', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline),
            tooltip: 'Available Offline',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Guides are automatically cached for offline use on the bus.')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryChips(),
          Expanded(child: _buildGuideList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search guides, locations, or keywords...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = category);
                }
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGuideList() {
    // We pass the category filter to Firestore, but handle text search locally 
    // since Firestore doesn't support native full-text search easily without extensions.
    final categoryFilter = _selectedCategory == 'All' ? null : _selectedCategory;

    return StreamBuilder<List<ActivityGuide>>(
      stream: _guideService.streamGuides(categoryFilter: categoryFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var guides = snapshot.data ?? [];

        // Local text filtering
        if (_searchQuery.isNotEmpty) {
          guides = guides.where((g) {
            return g.title.toLowerCase().contains(_searchQuery) ||
                   g.location.toLowerCase().contains(_searchQuery) ||
                   g.content.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        if (guides.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.library_books_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No guides found matching your search.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 20),
          itemCount: guides.length,
          itemBuilder: (context, index) {
            final guide = guides[index];
            return _buildGuideCard(guide);
          },
        );
      },
    );
  }

  Widget _buildGuideCard(ActivityGuide guide) {
    IconData getCategoryIcon(String category) {
      switch (category.toLowerCase()) {
        case 'historical': return Icons.account_balance;
        case 'logistical': return Icons.directions_transit;
        case 'phrasebook': return Icons.translate;
        case 'safety': return Icons.health_and_safety;
        default: return Icons.article;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GuideDetailPage(guide: guide)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  getCategoryIcon(guide.category),
                  color: Theme.of(context).colorScheme.secondary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            guide.location,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            guide.category,
                            style: TextStyle(color: Colors.grey[700], fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Spacer(),
                        if (guide.mediaUrls.isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.attachment, size: 14, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 4),
                              Text('Media Attached', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
