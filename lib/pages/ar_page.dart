
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:projet_sejour/services/search_api_service.dart';

class ARPage extends StatefulWidget {
  final bool isActive;

  const ARPage({super.key, this.isActive = true});

  @override
  State<ARPage> createState() => _ARPageState();
}

class _ARPageState extends State<ARPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraController;
  final SearchApiService _searchApiService = SearchApiService();
  
  bool _isCameraInitialized = false;
  String _statusMessage = 'Initializing Scanner...';
  bool _hasError = false;

  bool _isSearching = false;
  List<dynamic> _searchResults = [];
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.isActive) {
      _initCamera();
    }
  }

  @override
  void didUpdateWidget(covariant ARPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        if (!_isCameraInitialized &&
            !(_cameraController?.value.isInitialized ?? false)) {
          _initCamera();
        }
      } else {
        // We could stop stream but we aren't streaming, just showing camera preview.
        // It's generally safe to leave preview running or we can pause it.
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Pause camera or dispose if strictly needed
    } else if (state == AppLifecycleState.resumed && widget.isActive) {
      // Resume
    }
  }

  Future<void> _initCamera() async {
    try {
      setState(() {
        _hasError = false;
        _statusMessage = 'Requesting camera access...';
      });

      final status = await Permission.camera.request();
      if (status.isPermanentlyDenied) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _statusMessage =
                "Camera permission permanently denied. Please enable it in system settings.";
          });
        }
        return;
      }

      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _statusMessage =
                'Camera access denied. Please allow it to use the visual scanner.';
          });
        }
        return;
      }

      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _statusMessage = 'No cameras found on this device.';
          });
        }
        return;
      }

      final backCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      setState(() {
        _statusMessage = 'Starting camera...';
      });

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusMessage = 'Camera Error: $e';
        });
      }
      debugPrint("Camera Error: $e");
    }
  }

  Future<void> _captureAndSearch() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isSearching) {
      return;
    }

    setState(() {
      _isSearching = true;
      _showDetails = false;
      _searchResults.clear();
    });

    try {
      final xFile = await _cameraController!.takePicture();
      
      final scanResult = await _searchApiService.performVisualSearch(xFile.path);

      if (mounted) {
        if (scanResult != null && scanResult['visual_matches'] != null) {
          setState(() {
            _searchResults = List.from(scanResult['visual_matches']);
            _showDetails = true;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No results found or search failed.')),
          );
        }
      }
    } catch (e) {
      debugPrint("Search error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error conducting visual search: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview Layer
          if (_isCameraInitialized && _cameraController != null)
            Center(
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio < 1
                    ? _cameraController!.value.aspectRatio
                    : 1.0 / _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_hasError)
                      const CircularProgressIndicator(color: Colors.white)
                    else
                      const Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    if (_hasError)
                      TextButton(
                        onPressed: () async {
                          if (_statusMessage.contains('permanently denied')) {
                            await openAppSettings();
                          } else {
                            _initCamera();
                          }
                        },
                        child: Text(
                          _statusMessage.contains('permanently denied')
                              ? 'Open Settings'
                              : 'Try Again',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // 2. Scanner UI Guide Overlay
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    "Visual Scanner",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        const Shadow(blurRadius: 10, color: Colors.black54),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Point your camera and tap to scan",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const Spacer(),
                  // Viewfinder Frame
                  GestureDetector(
                    onTap: _captureAndSearch,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isSearching
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white.withValues(alpha: 0.8),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Center(
                        child: _isSearching
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Icon(
                                Icons.camera_alt,
                                color: Colors.white.withValues(alpha: 0.5),
                                size: 48,
                              ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  // Capture Button
                  if (!_isSearching && !_showDetails)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32.0),
                      child: FloatingActionButton.extended(
                        onPressed: _captureAndSearch,
                        icon: const Icon(Icons.search),
                        label: const Text('Scan Image'),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 3. Slide-up Detail Card
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            bottom: _showDetails ? 0 : -mediaSize.height,
            left: 0,
            right: 0,
            child: _buildInfoCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Visual Matches",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showDetails = false;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          if (_searchResults.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text("No matches found.")),
            )
          else
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final match = _searchResults[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          image: match['thumbnail'] != null
                              ? DecorationImage(
                                  image: NetworkImage(match['thumbnail']),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: match['thumbnail'] == null
                            ? const Icon(Icons.image, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              match['title'] ?? 'Unknown Item',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (match['source'] != null)
                              Text(
                                match['source'],
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            const SizedBox(height: 4),
                            if (match['price'] != null)
                              Text(
                                match['price'].toString(),
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
