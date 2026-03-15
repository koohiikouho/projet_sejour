import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TeamHeaderCard extends StatelessWidget {
  final String teamName;
  final String teamCode;
  final int totalMembers;
  final int onlineMembers;

  const TeamHeaderCard({
    super.key,
    required this.teamName,
    required this.teamCode,
    required this.totalMembers,
    required this.onlineMembers,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final offlineMembers = totalMembers - onlineMembers;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Team icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 12),
          // Team name
          Text(
            teamName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Team code pill
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: teamCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Team code "$teamCode" copied to clipboard'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.copy, color: Colors.white70, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    teamCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat('Total', totalMembers.toString()),
              Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.3)),
              _buildStat('Online', onlineMembers.toString()),
              Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.3)),
              _buildStat('Offline', offlineMembers.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
