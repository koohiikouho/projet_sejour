import 'package:flutter/material.dart';
import 'package:projet_sejour/services/guide_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GuideDetailPage extends StatelessWidget {
  final ActivityGuide guide;

  const GuideDetailPage({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Guide Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Guide bookmarked for quick access.')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                guide.category.toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              guide.title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.2),
            ),
            const SizedBox(height: 8),
            
            // Location metadata
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  guide.location,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content Body
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Text(
                guide.content,
                style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
              ),
            ),
            
            const SizedBox(height: 32),

            // Media Section
            if (guide.mediaUrls.isNotEmpty) ...[
              const Text(
                'Media Attachments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...guide.mediaUrls.map((url) => _buildMediaAttachment(context, url)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMediaAttachment(BuildContext context, String url) {
    final isAudio = url.toLowerCase().contains('.mp3') || url.toLowerCase().contains('.wav');
    
    if (isAudio) {
      // Mock Audio Player UI for Brother Mawel's lectures
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: const Icon(Icons.play_arrow, color: Colors.white),
          ),
          title: const Text('Historical Lecture Audio', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Brother Mawel (04:23)', style: TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.volume_up),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Playing historical lecture...')),
            );
          },
        ),
      );
    } else {
      // Image attachment
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        clipBehavior: Clip.antiAlias,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
        ),
      );
    }
  }
}
