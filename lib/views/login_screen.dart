import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tanza_store/main.dart';
import 'package:tanza_store/services/auth_services.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tanza Store Login'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.store, size: 80, color: Colors.blue),
              const SizedBox(height: 32),
              const Text(
                'Welcome to Tanza Store',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please sign in to continue',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              // In login_screen.dart - temporary test version
              ElevatedButton.icon(
                onPressed: () async {
                  debugPrint('Button pressed');
                  final user = await authService.signInWithGoogle();
                  debugPrint('Got user: $user');

                  // Force navigation even if user is null (for testing)
                  if (user != null && context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MainScreen()
                          // Container(
                          //     color: Colors.red,
                          //     child: const Center(
                          //         child:
                          //             Text('Test'))
                          // )
                          ), // Temporary test screen
                    );
                  }
                },
                icon: const Icon(
                  FontAwesomeIcons.google,
                  color: Colors.white,
                ),
                label: const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  minimumSize: const Size(210, 40),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final user = await authService.signInWithFacebook();
                  if (user != null && context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                    );
                  }
                },
                icon: const Icon(Icons.facebook),
                label: const Text('Sign in with Facebook'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                  minimumSize: const Size(210, 40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
