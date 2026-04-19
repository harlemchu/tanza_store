import 'package:flutter/material.dart';
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
                  if (context.mounted) {
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
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
