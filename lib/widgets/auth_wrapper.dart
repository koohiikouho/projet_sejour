import 'package:flutter/material.dart';
import 'package:projet_sejour/pages/login_page.dart';
import 'package:projet_sejour/pages/main_page.dart';
import 'package:projet_sejour/services/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return FutureBuilder<bool>(
      future: authService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          return const MainPage();
        }

        return const LoginPage();
      },
    );
  }
}
