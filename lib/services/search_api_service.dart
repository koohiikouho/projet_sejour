import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SearchApiService {
  static const String _cloudinaryUploadUrl = 'https://api.cloudinary.com/v1_1/';

  /// Uploads an image to Cloudinary and returns the secure URL
  Future<String?> uploadImageToCloudinary(String imagePath) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final apiKey = dotenv.env['CLOUDINARY_API_KEY'];
    final apiSecret = dotenv.env['CLOUDINARY_API_SECRET'];

    if (cloudName == null || apiKey == null || apiSecret == null) {
      print('Cloudinary credentials are not set in .env');
      return null;
    }

    try {
      final url = Uri.parse('$_cloudinaryUploadUrl$cloudName/image/upload');
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
        ..files.add(await http.MultipartFile.fromPath('file', imagePath));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(responseData);
        return json['secure_url']; // Return the uploaded image URL
      } else {
        print('Failed to upload image to Cloudinary: ${response.statusCode}');
        print(responseData);
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  /// Searches for visual matches using Google Lens via SearchAPI
  Future<Map<String, dynamic>?> searchVisualMatches(String imageUrl) async {
    final searchApiKey = dotenv.env['SEARCHAPI_API_KEY'];
    if (searchApiKey == null) {
      print('SearchAPI key is not set in .env');
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
        print('SearchAPI Error: ${response.statusCode}');
        print(response.body);
        return null;
      }
    } catch (e) {
      print('Error calling SearchAPI: $e');
      return null;
    }
  }

  /// Orchestrates the full flow: uploads to Cloudinary, then searches using SearchAPI
  Future<Map<String, dynamic>?> performVisualSearch(String localImagePath) async {
    print('Starting upload to Cloudinary...');
    final imageUrl = await uploadImageToCloudinary(localImagePath);
    
    if (imageUrl != null) {
      print('Successfully uploaded to Cloudinary: $imageUrl');
      print('Starting SearchAPI visual match request...');
      return await searchVisualMatches(imageUrl);
    } else {
      print('Failed to get image URL from Cloudinary. Aborting search.');
      return null;
    }
  }
}
