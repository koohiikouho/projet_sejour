import 'package:flutter/material.dart';
import 'package:projet_sejour/models/team_member_model.dart';
import 'package:projet_sejour/widgets/team/team_member_card.dart';

void showTeamMemberDetailSheet(
  BuildContext context, {
  required TeamMember member,
  required bool isCurrentUser,
  required String distance,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;

      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle
            Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 32),
            // Large avatar with online dot
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                  backgroundImage: member.avatarUrl.isNotEmpty
                      ? NetworkImage(member.avatarUrl)
                      : null,
                  child: member.avatarUrl.isEmpty
                      ? Text(
                          member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                if (member.isOnline)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Name + YOU badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'YOU',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Role pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                member.role,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Info row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoItem(
                  context,
                  icon: Icons.circle,
                  iconColor: member.isOnline ? Colors.green : Colors.grey,
                  iconSize: 12,
                  label: 'Status',
                  value: member.isOnline ? 'Active' : 'Offline',
                ),
                if (distance.isNotEmpty)
                  _buildInfoItem(
                    context,
                    icon: Icons.straighten,
                    label: 'Distance',
                    value: distance,
                  ),
                _buildInfoItem(
                  context,
                  icon: Icons.access_time,
                  label: 'Last Seen',
                  value: formatLastSeen(member.lastUpdated),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    },
  );
}

Widget _buildInfoItem(
  BuildContext context, {
  required IconData icon,
  Color? iconColor,
  double iconSize = 16,
  required String label,
  required String value,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return Column(
    children: [
      Icon(icon, color: iconColor ?? colorScheme.primary, size: iconSize),
      const SizedBox(height: 6),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ],
  );
}
