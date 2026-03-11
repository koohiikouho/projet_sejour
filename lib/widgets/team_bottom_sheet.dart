import 'package:flutter/material.dart';

import 'package:projet_sejour/models/team_member_model.dart';
import 'package:projet_sejour/services/notification_service.dart';

class TeamBottomSheet extends StatefulWidget {
  final Stream<List<TeamMember>> teamStream;
  const TeamBottomSheet({super.key, required this.teamStream});

  @override
  State<TeamBottomSheet> createState() => _TeamBottomSheetState();
}

class _TeamBottomSheetState extends State<TeamBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.25, // Start peeking slightly above the nav bar
      minChildSize: 0.15, // Only show the handle and "Team" header
      maxChildSize: 0.8, // Expand almost to the top
      snap: true,
      snapSizes: const [0.15, 0.4, 0.8],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Grab Handle
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            'Team Members',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              NotificationService.showLocalNotification(
                                title: "Alert Triggered!", 
                                body: "A team member needs your assistance."
                              );
                            },
                            icon: const Icon(Icons.campaign, size: 16),
                            label: const Text('Alert'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade100,
                              foregroundColor: Colors.red.shade900,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              minimumSize: const Size(0, 32),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: StreamBuilder<List<TeamMember>>(
                              stream: widget.teamStream,
                              builder: (context, snapshot) {
                                int activeCount = 0;
                                if (snapshot.hasData) {
                                  activeCount = snapshot.data!.where((m) => m.isOnline).length;
                                }
                                return Text(
                                  '$activeCount Active',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              }
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                  ],
                ),
              ),
              
              // Scrollable List of Members
              StreamBuilder<List<TeamMember>>(
                stream: widget.teamStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    debugPrint('Firebase Stream Error: \${snapshot.error}');
                    return SliverFillRemaining(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "Error: \${snapshot.error}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    );
                  }
                  
                  final members = snapshot.data ?? [];
                  if (members.isEmpty) {
                    return const SliverFillRemaining(child: Center(child: Text("No team members found")));
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final member = members[index];
                        return _buildTeamMember(
                          context,
                          name: member.name,
                          role: member.role,
                          // Temporary static status/distance until we build the map logic
                          status: member.isOnline ? 'Online' : 'Offline',
                          distance: 'Unknown',
                          avatarUrl: member.avatarUrl,
                          isActive: member.isOnline,
                        );
                      },
                      childCount: members.length,
                    ),
                  );
                }
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamMember(
    BuildContext context, {
    required String name,
    required String role,
    required String status,
    required String distance,
    required String avatarUrl,
    required bool isActive,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(avatarUrl),
          ),
          if (isActive)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          if (role.contains('You')) // Highlight current user
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'YOU',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(role, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                isActive ? Icons.location_on : Icons.location_off,
                size: 14,
                color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(
                    color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Text(
        distance,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.black87 : Colors.grey,
        ),
      ),
    );
  }
}
