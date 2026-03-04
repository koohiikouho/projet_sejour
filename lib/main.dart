import 'package:flutter/material.dart';
import 'package:projet_sejour/theme/app_theme.dart';
import 'package:projet_sejour/widgets/auth_wrapper.dart';

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Mapbox with the public access token
  MapboxOptions.setAccessToken('INSERT TOKEN HERE');
  runApp(const ProjetSejourApp());
}

class ProjetSejourApp extends StatelessWidget {
  const ProjetSejourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Projet Sejour',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
