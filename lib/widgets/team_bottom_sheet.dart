import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:projet_sejour/models/team_member_model.dart';
import 'package:projet_sejour/services/location_sync_service.dart';

class TeamBottomSheet extends StatefulWidget {
  const TeamBottomSheet({super.key});

  @override
  State<TeamBottomSheet> createState() => _TeamBottomSheetState();
}

class _TeamBottomSheetState extends State<TeamBottomSheet> {
  final LocationSyncService _syncService = LocationSyncService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'test_user';
  final String _currentUserName = FirebaseAuth.instance.currentUser?.displayName ?? 'Traveler';

  bool _isScanning = false;
  bool _isLoading = false;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _createTeam() {
    showDialog(
      context: context,
      builder: (context) {
        String teamName = "";
        return AlertDialog(
          title: const Text("Create a New Team"),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(labelText: "Group Name"),
            onChanged: (val) => teamName = val,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (teamName.trim().isEmpty) return;
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  await _syncService.createTeam(_currentUserId, teamName.trim(), _currentUserName);
                } catch (e) {
                  _showError(e.toString());
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  void _showQrCode(Map<String, dynamic> teamData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Join ${teamData['name']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: teamData['joinCode'],
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: 16),
            const Text("Scan this code to join the team!"),
            const SizedBox(height: 8),
            Text(
              "Or enter code manually: ${teamData['joinCode']}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  void _leaveTeam(String teamId) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Leave Team?"),
        content: const Text("Are you sure you want to stop sharing locations and leave this group?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Leave"),
          ),
        ],
      ),
    );

    if (conf == true) {
      setState(() => _isLoading = true);
      await _syncService.leaveTeam(_currentUserId, teamId);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.15,
      maxChildSize: 0.8,
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
                  ],
                ),
              ),
              
              if (_isLoading)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else if (_isScanning)
                _buildScannerView()
              else
                StreamBuilder<Map<String, dynamic>?>(
                  stream: _syncService.streamUserTeamData(_currentUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                    }

                    final userData = snapshot.data;
                    final teamId = userData?['teamId'] as String?;
                    final isLeader = userData?['isTeamLeader'] as bool? ?? false;

                    if (teamId == null) {
                      return _buildNoTeamView();
                    }

                    return _buildActiveTeamView(teamId, isLeader);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScannerView() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                BackButton(onPressed: () => setState(() => _isScanning = false)),
                const Text("Scan QR Code", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SizedBox(
            height: 400,
            child: MobileScanner(
              onDetect: (capture) async {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null && !_isLoading) {
                  setState(() {
                    _isLoading = true;
                    _isScanning = false;
                  });
                  try {
                    await _syncService.joinTeam(_currentUserId, barcodes.first.rawValue!, _currentUserName);
                  } catch (e) {
                    _showError(e.toString());
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTeamView() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              "You are not in a Team",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Join a team to sync locations, receive leader alerts, and stay connected.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _createTeam,
              icon: const Icon(Icons.add),
              label: const Text("Create a Team"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => setState(() => _isScanning = true),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text("Scan QR to Join"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTeamView(String teamId, bool isLeader) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _syncService.getTeamData(teamId),
      builder: (context, teamSnap) {
        if (!teamSnap.hasData) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
        
        final teamData = teamSnap.data!;
        
        return StreamBuilder<List<TeamMember>>(
          stream: _syncService.getTeamLocations(teamId),
          builder: (context, snapshot) {
            final members = snapshot.data ?? [];
            final activeCount = members.where((m) => m.isOnline).length;

            return SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              teamData['name'] ?? 'My Team',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$activeCount Active',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (isLeader) ...[
                              ElevatedButton.icon(
                                onPressed: () {
                                  _syncService.pingTeam(teamId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Alert sent to team members!')),
                                  );
                                },
                                icon: const Icon(Icons.campaign, size: 16),
                                label: const Text('Ping Team'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade100,
                                  foregroundColor: Colors.red.shade900,
                                  elevation: 0,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showQrCode(teamData),
                                icon: const Icon(Icons.qr_code, size: 16),
                                label: const Text('QR Code'),
                                style: ElevatedButton.styleFrom(elevation: 0),
                              ),
                            ] else ...[
                              ElevatedButton.icon(
                                onPressed: () => _leaveTeam(teamId),
                                icon: const Icon(Icons.exit_to_app, size: 16),
                                label: const Text('Leave Team'),
                                style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: Colors.grey[200], foregroundColor: Colors.black87),
                              ),
                            ],
                          ],
                        ),
                        if (isLeader)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: OutlinedButton(
                              onPressed: () => _leaveTeam(teamId),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Disband / Leave Team'),
                            ),
                          ),
                        const Divider(),
                      ],
                    ),
                  ),
                ),
                
                if (members.isEmpty)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Text("No team members found"),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final member = members[index];
                        return _buildTeamMember(
                          context,
                          name: member.name,
                          role: member.role,
                          status: member.isOnline ? 'Online' : 'Offline',
                          distance: 'Live', // Calculate distance physically in a real app
                          avatarUrl: member.avatarUrl,
                          isActive: member.isOnline,
                          isCurrentUser: member.id == _currentUserId,
                        );
                      },
                      childCount: members.length,
                    ),
                  ),
              ],
            );
          }
        );
      }
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
    required bool isCurrentUser,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
            child: avatarUrl.isEmpty ? const Icon(Icons.person) : null,
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
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          if (isCurrentUser)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('YOU', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
