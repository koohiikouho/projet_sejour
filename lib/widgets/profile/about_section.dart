import 'package:flutter/material.dart';

class AboutSection extends StatelessWidget {
  final String? name;

  const AboutSection({
    super.key,
    this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Me',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hi. My name is ${name ?? 'User'}. I am excited to be participating in this spiritual journey and exploring the historical sites. Nice to meet you!',
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          
          // Details Grid (Keeping static for now as per theme)
          const Text(
            'Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Age
          _buildDetailRow(
            context,
            Icons.cake_rounded,
            'Age',
            '-- years old',
          ),
          const SizedBox(height: 12),

          // Department (Renamed to clear placeholder)
          _buildDetailRow(
            context,
            Icons.school_rounded,
            'Group',
            'Team Alpha',
          ),
          const SizedBox(height: 12),

          // Member Since
          _buildDetailRow(
            context,
            Icons.calendar_today_rounded,
            'Member since',
            'March 2024',
          ),
          const SizedBox(height: 12),

          // Languages
          _buildDetailRow(
            context,
            Icons.language_rounded,
            'Languages',
            'English, Local Dialect',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}