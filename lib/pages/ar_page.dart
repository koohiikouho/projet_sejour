import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:projet_sejour/services/ar_detection_service.dart';

class ARPage extends StatefulWidget {
  final bool isActive;

  const ARPage({super.key, this.isActive = true});

  @override
  State<ARPage> createState() => _ARPageState();
}

class _ARPageState extends State<ARPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraController;
  final ARDetectionService _arDetectionService = ARDetectionService();
  bool _isCameraInitialized = false;
  String _statusMessage = 'Initializing AR View...';
  bool _hasError = false;

  // State for detected Object
  bool _isObjectDetected = false;
  double _objectConfidence = 0.0;
  Rect? _objectBoundingBox;
  Size? _cameraImageSize;

  // UI States
  bool _showDetails = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Only initialize hardware if the tab is actually visible on launch.
    // This prevents locking the main thread during splash screens.
    if (widget.isActive) {
      _initCamera();
    }
  }

  @override
  void didUpdateWidget(covariant ARPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle tab switching inside the IndexedStack
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        if (!_isCameraInitialized &&
            !(_cameraController?.value.isInitialized ?? false)) {
          _initCamera();
        } else if (_cameraController != null &&
            !_cameraController!.value.isStreamingImages) {
          _startCameraStream();
        }
      } else {
        if (_cameraController != null &&
            _cameraController!.value.isStreamingImages) {
          _cameraController?.stopImageStream();
        }
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
      // Free up the camera and ML resources when app is backgrounded
      if (_cameraController!.value.isStreamingImages) {
        _cameraController?.stopImageStream();
      }
    } else if (state == AppLifecycleState.resumed && widget.isActive) {
      // Restart the camera stream when app comes back, ONLY if this tab is active
      if (_cameraController != null &&
          !_cameraController!.value.isStreamingImages) {
        _startCameraStream();
      }
    }
  }

  Future<void> _initCamera() async {
    try {
      setState(() {
        _hasError = false;
        _statusMessage = 'Requesting camera access...';
      });

      // Explicitly request permission
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
                'Camera access denied. Please allow it to use the AR scanner.';
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
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      setState(() {
        _statusMessage = 'Starting camera...';
      });

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      // Only start the stream if the tab is STILL active after the async initialization
      if (widget.isActive) {
        _startCameraStream();
      }
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

  void _startCameraStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _cameraController!.startImageStream((CameraImage image) async {
      if (!mounted) return;

      // Pass the image size along with the results to ensure they stay in sync
      final imgSize = Size(image.width.toDouble(), image.height.toDouble());

      final objects = await _arDetectionService.processCameraFrame(image);
      if (objects != null && mounted) {
        _processObjects(objects, imgSize);
      }
    });
  }

  void _processObjects(List<DetectedObject> objects, Size imageSize) {
    if (!mounted) return;

    bool foundObject = objects.isNotEmpty;
    double highestConfidence = 0.0;
    Rect? bestBoundingBox;

    if (foundObject) {
      final object = objects.first;
      if (object.labels.isNotEmpty) {
        highestConfidence = object.labels.first.confidence;
      }
      bestBoundingBox = object.boundingBox;
    }

    // Always update inside setState to ensure build() has correct data
    setState(() {
      _isObjectDetected = foundObject;
      _objectConfidence = highestConfidence;
      _objectBoundingBox = bestBoundingBox;
      _cameraImageSize = imageSize;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _arDetectionService.dispose();
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

          // 2. Scanner UI Guide Overlay (Ignored for touches)
          Positioned.fill(
            child: IgnorePointer(
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      "AR Scanner",
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
                      "Point your camera at a Television for testing",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const Spacer(),
                    // Viewfinder Reticle
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isObjectDetected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white.withValues(
                                  alpha: _showDetails ? 0.0 : 0.5,
                                ),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating Label positioned by Object Detector
          if (!_showDetails)
            _buildBoundingBoxLabel(mediaSize.width, mediaSize.height),

          // 4. Slide-up Detail Card
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

  Widget _buildBoundingBoxLabel(double screenWidth, double screenHeight) {
    if (!_isObjectDetected ||
        _objectBoundingBox == null ||
        _cameraImageSize == null ||
        _cameraImageSize!.width == 0 ||
        _cameraImageSize!.height == 0) {
      return const SizedBox();
    }

    try {
      // Force preview aspect ratio to be portrait (always < 1.0)
      final rawAR = _cameraController!.value.aspectRatio;
      final previewAR = rawAR < 1 ? rawAR : 1.0 / rawAR;

      final screenAR = screenWidth / screenHeight;

      double displayedWidth, displayedHeight, offsetX = 0, offsetY = 0;

      // AspectRatio widget behavior inside a Center/Stack expand
      if (previewAR > screenAR) {
        // Limited by width (top/bottom borders)
        displayedWidth = screenWidth;
        displayedHeight = screenWidth / previewAR;
        offsetY = (screenHeight - displayedHeight) / 2;
      } else {
        // Limited by height (left/right borders)
        displayedHeight = screenHeight;
        displayedWidth = screenHeight * previewAR;
        offsetX = (screenWidth - displayedWidth) / 2;
      }

      double scaleX, scaleY, left, top, height;

      if (Platform.isAndroid) {
        // Android camera stream is usually landscape (1280x720)
        scaleX = displayedWidth / _cameraImageSize!.height;
        scaleY = displayedHeight / _cameraImageSize!.width;

        left = offsetX + (_objectBoundingBox!.top * scaleX);
        top = offsetY + (_objectBoundingBox!.left * scaleY);
        height = _objectBoundingBox!.width * scaleY;
      } else {
        // iOS camera stream matches orientation more closely
        scaleX = displayedWidth / _cameraImageSize!.width;
        scaleY = displayedHeight / _cameraImageSize!.height;

        left = offsetX + (_objectBoundingBox!.left * scaleX);
        top = offsetY + (_objectBoundingBox!.top * scaleY);
        height = _objectBoundingBox!.height * scaleY;
      }

      // Check for valid coordinates
      if (!left.isFinite || !top.isFinite || !height.isFinite) {
        return const SizedBox();
      }

      // Try placing above the object. If it clips top of screen, place below.
      double labelTop = top - 70;
      if (labelTop < 100) labelTop = top + height + 20;

      // Ensure it doesn't clip off left/right
      double labelLeft = left;
      if (labelLeft < 20) labelLeft = 20;
      if (labelLeft > screenWidth - 250) labelLeft = screenWidth - 250;

      // Final check
      if (!labelTop.isFinite || !labelLeft.isFinite) {
        return const SizedBox();
      }

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        top: labelTop,
        left: labelLeft,
        child: _buildActionLabel(),
      );
    } catch (e) {
      debugPrint("Error mapping AR coordinates: $e");
      return const SizedBox();
    }
  }

  Widget _buildActionLabel() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showDetails = true;
        });
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          // Subtle floating effect using translation and scale
          final dy = 10.0 * _pulseController.value;

          return Transform(
            // Apply faux-3D perspective
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002) // Perspective depth
              ..rotateX(-0.15) // Tilt back slightly
              ..rotateY(0.2) // Turn to the right slightly
              ..translate(0.0, dy),
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Tap to scan: 1950s Television",
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 48),
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
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.museum_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Historical Television Display",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "Match Confidence: ${(_objectConfidence * 100).toStringAsFixed(0)}%",
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "This 1950s broadcast terminal represents a revolution in communication. "
            "It was used for the first educational television transmissions in this region.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showDetails = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text("Close"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Future action: open full details page
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("Read Full History"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
