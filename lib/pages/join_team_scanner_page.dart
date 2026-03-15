import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:projet_sejour/services/team_service.dart';

class JoinTeamScannerPage extends StatefulWidget {
  const JoinTeamScannerPage({super.key});

  @override
  State<JoinTeamScannerPage> createState() => _JoinTeamScannerPageState();
}

class _JoinTeamScannerPageState extends State<JoinTeamScannerPage> {
  final TeamService _teamService = TeamService();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _isProcessing = true);

    try {
      final data = jsonDecode(barcode.rawValue!) as Map<String, dynamic>;

      if (data['type'] != 'projet_sejour_team') {
        _showError('Invalid QR code');
        return;
      }

      final teamId = data['teamId'] as String?;
      if (teamId == null || teamId.isEmpty) {
        _showError('Invalid QR code');
        return;
      }

      final teamInfo = await _teamService.getTeamInfo(teamId);
      if (teamInfo == null) {
        _showError('Team not found');
        return;
      }

      if (!mounted) return;

      // Show join confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Join Team?'),
          content: Text('Do you want to join "${teamInfo.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Join'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await _teamService.joinTeam(teamId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Joined ${teamInfo.name}!')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) setState(() => _isProcessing = false);
      }
    } on FormatException {
      _showError('Invalid QR code');
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Team QR', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              // Camera permission denied or error
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Camera permission is required to scan QR codes')),
                  );
                  Navigator.pop(context);
                }
              });
              return const Center(
                child: Text('Camera error', style: TextStyle(color: Colors.white)),
              );
            },
          ),
          // Overlay with scan area
          CustomPaint(
            painter: _ScanOverlayPainter(borderColor: colorScheme.primary),
            child: const SizedBox.expand(),
          ),
          // Bottom instruction
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Text(
              'Point your camera at a team QR code',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final Color borderColor;

  _ScanOverlayPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final scanAreaSize = 250.0;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2;
    final scanRect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    // Semi-transparent overlay
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.5);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), overlayPaint);
    canvas.drawRect(Rect.fromLTWH(0, top, left, scanAreaSize), overlayPaint);
    canvas.drawRect(Rect.fromLTWH(left + scanAreaSize, top, size.width - left - scanAreaSize, scanAreaSize), overlayPaint);
    canvas.drawRect(Rect.fromLTWH(0, top + scanAreaSize, size.width, size.height - top - scanAreaSize), overlayPaint);

    // Border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final rrect = RRect.fromRectAndRadius(scanRect, const Radius.circular(16));
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
