import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class ARDetectionService {
  late ObjectDetector _objectDetector;
  bool _canProcess = true;
  bool _isBusy = false;

  ARDetectionService() {
    final mode = DetectionMode.stream;
    final options = ObjectDetectorOptions(
      mode: mode,
      classifyObjects: true,
      multipleObjects: false,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  void dispose() {
    _canProcess = false;
    _objectDetector.close();
  }

  Future<List<DetectedObject>?> processCameraFrame(CameraImage image) async {
    if (!_canProcess || _isBusy) return null;
    _isBusy = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return null;

      final objects = await _objectDetector.processImage(inputImage);
      return objects;
    } catch (e) {
      debugPrint('Error processing image: $e');
      return null;
    } finally {
      _isBusy = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    // A simplified conversion for Android/iOS.
    // In a prod app, orientation and format handling require more camera specific rotation config.
    // We assume NV21/YUV_420_888 for Android or BGRA8888 for iOS for this basic example.

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    InputImageRotation imageRotation =
        InputImageRotation.rotation90deg; // Defaulting for simple portrait

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
  }
}
