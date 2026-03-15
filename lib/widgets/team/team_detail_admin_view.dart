import 'package:flutter/material.dart';
import 'package:projet_sejour/models/team_member_model.dart';
import 'package:projet_sejour/services/team_service.dart';
import 'package:projet_sejour/services/location_sync_service.dart';

class TeamDetailAdminView extends StatelessWidget {
  final String teamId;
  final String teamName;
  final String teamCode;

  const TeamDetailAdminView({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.teamCode,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(teamName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => _showAddMemberSheet(context),
            tooltip: 'Add Member',
          ),
        ],
      ),
      body: Column(
        children: [
          // Team info header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.group_rounded, color: colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(teamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text('Code: $teamCode', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Text('Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              ],
            ),
          ),
          // Member list
          Expanded(
            child: StreamBuilder<List<TeamMember>>(
              stream: LocationSyncService().getTeamLocations(teamId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final members = snapshot.data ?? [];

                if (members.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('No members yet', style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.5))),
                        const SizedBox(height: 8),
                        Text('Tap + to add members', style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.4))),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return Card(
                      elevation: 2,
                      shadowColor: Colors.black.withValues(alpha: 0.05),
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                              backgroundImage: member.avatarUrl.isNotEmpty ? NetworkImage(member.avatarUrl) : null,
                              child: member.avatarUrl.isEmpty
                                  ? Text(
                                      member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                                      style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            // Name + role
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      member.role,
                                      style: TextStyle(color: colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Remove button
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () => _confirmRemoveMember(context, member),
                              tooltip: 'Remove from team',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(BuildContext context, TeamMember member) {
    showDialog(
      context: context,
      builder: (context) {
        bool isRemoving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('Remove ${member.name}?'),
              content: Text('${member.name} will be removed from $teamName and will need to rejoin.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: isRemoving
                      ? null
                      : () async {
                          setDialogState(() => isRemoving = true);
                          try {
                            await TeamService().removeMemberFromTeam(teamId, member.id);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${member.name} removed')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setDialogState(() => isRemoving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                  child: isRemoving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Remove', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddMemberSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Add Member', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Select a pilgrim to add to $teamName',
                      style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: TeamService().getUnassignedUsersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final users = snapshot.data ?? [];

                    if (users.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_off_outlined, size: 48, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              Text(
                                'All pilgrims are already in a team',
                                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final uid = user['uid'] as String;
                        final name = user['username'] as String? ?? 'Unknown';
                        final avatarUrl = user['avatarUrl'] as String? ?? '';

                        return _AddMemberTile(
                          uid: uid,
                          name: name,
                          avatarUrl: avatarUrl,
                          teamId: teamId,
                          teamName: teamName,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddMemberTile extends StatefulWidget {
  final String uid;
  final String name;
  final String avatarUrl;
  final String teamId;
  final String teamName;

  const _AddMemberTile({
    required this.uid,
    required this.name,
    required this.avatarUrl,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<_AddMemberTile> createState() => _AddMemberTileState();
}

class _AddMemberTileState extends State<_AddMemberTile> {
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
          backgroundImage: widget.avatarUrl.isNotEmpty ? NetworkImage(widget.avatarUrl) : null,
          child: widget.avatarUrl.isEmpty
              ? Text(
                  widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                  style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(widget.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: _isAdding
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : IconButton(
                icon: Icon(Icons.add_circle_outline, color: colorScheme.primary),
                onPressed: () async {
                  setState(() => _isAdding = true);
                  try {
                    await TeamService().addMemberToTeam(widget.teamId, widget.uid);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${widget.name} added to ${widget.teamName}')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isAdding = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
              ),
      ),
    );
  }
}
