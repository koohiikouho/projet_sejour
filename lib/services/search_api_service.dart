import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SearchApiService {
  static const String _cloudinaryUploadUrl = 'https://api.cloudinary.com/v1_1/';

  /// Uploads media (image/audio/video) to Cloudinary and returns the secure URL
  Future<String?> uploadMediaToCloudinary(String filePath) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final apiKey = dotenv.env['CLOUDINARY_API_KEY'];
    final apiSecret = dotenv.env['CLOUDINARY_API_SECRET'];

    if (cloudName == null || apiKey == null || apiSecret == null) {
      debugPrint('Cloudinary credentials are not set in .env');
      return null;
    }

    try {
      // 'auto' resource_type automatically detects image, video, or raw files
      final url = Uri.parse('$_cloudinaryUploadUrl$cloudName/auto/upload');
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

      // To generate the signature:
      // String to sign: "timestamp=$timestamp$apiSecret"
      final stringToSign = 'timestamp=$timestamp$apiSecret';
      final bytes = utf8.encode(stringToSign);
      final digest = sha1.convert(bytes);
      final signature = digest.toString();

      final request = http.MultipartRequest('POST', url)
        ..fields['api_key'] = apiKey
        ..fields['timestamp'] = timestamp
        ..fields['signature'] = signature
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(responseData);
        return json['secure_url']; // Return the uploaded media URL
      } else {
        debugPrint('Failed to upload media to Cloudinary: ${response.statusCode}');
        debugPrint(responseData);
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  /// Searches for visual matches using Google Lens via SearchAPI
  Future<Map<String, dynamic>?> searchVisualMatches(String imageUrl) async {
    final searchApiKey = dotenv.env['SEARCHAPI_API_KEY'];
    if (searchApiKey == null) {
      debugPrint('SearchAPI key is not set in .env');
      return null;
    }

    try {
      final url = Uri.parse('https://www.searchapi.io/api/v1/search').replace(
        queryParameters: {
          'engine': 'google_lens',
          'search_type': 'visual_matches',
          'url': imageUrl,
          'api_key': searchApiKey,
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('SearchAPI Error: ${response.statusCode}');
        debugPrint(response.body);
        return null;
      }
    } catch (e) {
      debugPrint('Error calling SearchAPI: $e');
      return null;
    }
  }

  /// Orchestrates the full flow: uploads to Cloudinary, then searches using SearchAPI
  Future<Map<String, dynamic>?> performVisualSearch(String localImagePath) async {
    debugPrint('Starting upload to Cloudinary...');
    final imageUrl = await uploadMediaToCloudinary(localImagePath);
    
    if (imageUrl != null) {
      debugPrint('Successfully uploaded to Cloudinary: $imageUrl');
      debugPrint('Starting SearchAPI visual match request...');
      return await searchVisualMatches(imageUrl);
    } else {
      debugPrint('Failed to get image URL from Cloudinary. Aborting search.');
      return null;
    }
  }
}
