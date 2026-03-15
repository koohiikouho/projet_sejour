import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:projet_sejour/models/team_member_model.dart';
import 'package:projet_sejour/models/team_info_model.dart';
import 'package:projet_sejour/services/team_service.dart';
import 'package:projet_sejour/services/location_sync_service.dart';
import 'package:projet_sejour/widgets/team/team_header_card.dart';
import 'package:projet_sejour/widgets/team/team_member_card.dart';
import 'package:projet_sejour/widgets/team/team_member_detail_sheet.dart';
import 'package:projet_sejour/widgets/team/no_team_view.dart';
import 'package:projet_sejour/widgets/team/team_qr_dialog.dart';
import 'package:projet_sejour/widgets/team/manage_teams_view.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  final TeamService _teamService = TeamService();
  final LocationSyncService _syncService = LocationSyncService();
  geo.Position? _currentPosition;
  bool _isAdmin = false;
  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
    _checkAdminStatus();
  }

  Future<void> _getCurrentPosition() async {
    try {
      final position = await geo.Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 5),
      );
      if (mounted) setState(() => _currentPosition = position);
    } catch (_) {
      // Position not available — distance will just not show
    }
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _teamService.isCurrentUserAdmin();
    if (mounted) setState(() => _isAdmin = isAdmin);
  }

  String _calculateDistance(TeamMember member) {
    if (_currentPosition == null || !member.isOnline) return '';
    final meters = geo.Geolocator.distanceBetween(
      _currentPosition!.latitude, _currentPosition!.longitude,
      member.latitude, member.longitude,
    );
    if (meters < 1000) return '${meters.round()}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  void _showLeaveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Leave Team?'),
        content: const Text('You can rejoin later using the team code or QR code.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _teamService.leaveTeam();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You left the team')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: _teamService.currentUserTeamIdStream(),
      builder: (context, snapshot) {
        final teamId = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (teamId == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Team', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
            ),
            body: NoTeamView(isAdmin: _isAdmin),
          );
        }

        // Sync current user's profile data into the member doc (fixes stale avatars/roles)
        _teamService.syncMemberProfile(teamId);

        return _buildTeamHub(context, teamId);
      },
    );
  }

  Widget _buildTeamHub(BuildContext context, String teamId) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Team', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Share QR icon
          FutureBuilder<TeamInfo?>(
            future: _teamService.getTeamInfo(teamId),
            builder: (context, snapshot) {
              return IconButton(
                icon: const Icon(Icons.qr_code_rounded),
                onPressed: snapshot.data == null
                    ? null
                    : () {
                        showDialog(
                          context: context,
                          builder: (_) => TeamQrDialog(
                            teamId: teamId,
                            teamCode: snapshot.data!.teamCode,
                          ),
                        );
                      },
              );
            },
          ),
          // Popup menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'leave') _showLeaveConfirmation(context);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Leave Team', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<TeamMember>>(
        stream: _syncService.getTeamLocations(teamId),
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
                  Text(
                    'No team members found',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          // Sort: current user first → online → offline → alphabetical
          final sorted = List<TeamMember>.from(members);
          sorted.sort((a, b) {
            if (a.id == _currentUserId) return -1;
            if (b.id == _currentUserId) return 1;
            if (a.isOnline && !b.isOnline) return -1;
            if (!a.isOnline && b.isOnline) return 1;
            return a.name.compareTo(b.name);
          });

          final onlineCount = members.where((m) => m.isOnline).length;

          return CustomScrollView(
            slivers: [
              // Team header card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: FutureBuilder<TeamInfo?>(
                    future: _teamService.getTeamInfo(teamId),
                    builder: (context, teamSnapshot) {
                      final team = teamSnapshot.data;
                      return TeamHeaderCard(
                        teamName: team?.name ?? 'Loading...',
                        teamCode: team?.teamCode ?? '------',
                        totalMembers: members.length,
                        onlineMembers: onlineCount,
                      );
                    },
                  ),
                ),
              ),
              // Section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Members',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$onlineCount Active',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Member list with staggered animation
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final member = sorted[index];
                      final isCurrentUser = member.id == _currentUserId;
                      final distance = _calculateDistance(member);

                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 400 + (index * 80)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TeamMemberCard(
                            member: member,
                            isCurrentUser: isCurrentUser,
                            distance: distance,
                            onTap: () => showTeamMemberDetailSheet(
                              context,
                              member: member,
                              isCurrentUser: isCurrentUser,
                              distance: distance,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: sorted.length,
                  ),
                ),
              ),
              // Admin manage teams button
              if (_isAdmin)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ManageTeamsView()),
                        );
                      },
                      icon: const Icon(Icons.admin_panel_settings),
                      label: const Text('Manage Teams'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        side: BorderSide(color: colorScheme.primary),
                      ),
                    ),
                  ),
                ),
              // Bottom padding
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          );
        },
      ),
    );
  }
}
