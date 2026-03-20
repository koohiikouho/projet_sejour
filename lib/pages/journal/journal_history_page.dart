import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projet_sejour/models/journal_message.dart';
import 'package:projet_sejour/services/journal_service.dart';
import 'package:projet_sejour/pages/journal/journal_chat_page.dart';

class JournalHistoryPage extends StatefulWidget {
  const JournalHistoryPage({super.key});

  @override
  State<JournalHistoryPage> createState() => _JournalHistoryPageState();
}

class _JournalHistoryPageState extends State<JournalHistoryPage> {
  final JournalService _journalService = JournalService();
  final TextEditingController _searchController = TextEditingController();
  
  List<String> _activeDates = [];
  List<JournalMessage> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      setState(() => _isLoading = true);
      final dates = await _journalService.getActiveChatDates();
      if (mounted) {
        // Ensure today is always an option at the top if it doesn't exist
        final todayStr = DateTime.now().toIso8601String().split('T')[0];
        // Create a modifiable list from dates
        final List<String> modifiableDates = List<String>.from(dates);
        if (!modifiableDates.contains(todayStr)) {
          modifiableDates.insert(0, todayStr);
        }
        
        setState(() {
          _activeDates = modifiableDates;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading journal history: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history: $e')),
        );
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isLoading = true);
    final results = await _journalService.searchMessages(query);
    if (mounted) {
      setState(() {
        _isSearching = true;
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Reflection Journal', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: colorScheme.primary),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search memories, locations, or dates...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: _performSearch,
              onChanged: (val) {
                // If emptied, reset search immediately
                if (val.isEmpty) _performSearch('');
              },
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isSearching
                    ? _buildSearchResults()
                    : _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_activeDates.isEmpty) {
      return const Center(child: Text("No journal entries yet."));
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _activeDates.length,
        itemBuilder: (context, index) {
          final dateStr = _activeDates[index];
          final date = DateTime.parse(dateStr);
          final isToday = date.day == DateTime.now().day && date.year == DateTime.now().year;

          return Card(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isToday ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isToday ? Icons.edit_note_rounded : Icons.chat_bubble_outline_rounded,
                  color: isToday ? Theme.of(context).colorScheme.primary : Colors.grey[600],
                ),
              ),
              title: Text(
                isToday ? "Today's Journey" : DateFormat('MMMM d, yyyy').format(date),
                style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.w600, fontSize: 16),
              ),
              subtitle: Text(
                isToday ? "Tap to add your thoughts or pictures." : "View your memories from this day.",
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => JournalChatPage(dateStr: dateStr)),
                ).then((_) => _loadHistory()); // Refresh when coming back
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text("No memories found."));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final msg = _searchResults[index];
        IconData icon;
        String previewText;

        switch (msg.type) {
          case MessageType.text:
            icon = Icons.text_snippet_rounded;
            previewText = msg.content;
            break;
          case MessageType.image:
            icon = Icons.image_rounded;
            previewText = "Photo entry";
            break;
          case MessageType.audio:
            icon = Icons.mic_rounded;
            previewText = "Voice memo";
            break;
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
            title: Text(previewText, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              "${DateFormat('MMM d').format(msg.timestamp)} ${msg.locationName != null ? '• ${msg.locationName}' : ''}",
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => JournalChatPage(dateStr: msg.dateStr)),
              );
            },
          ),
        );
      },
    );
  }
}
