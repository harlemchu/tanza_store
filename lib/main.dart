import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tanza_store/services/auth_services.dart';
import 'package:tanza_store/services/sync_service.dart';
import 'package:tanza_store/tabs/history_screen.dart';
import 'package:tanza_store/views/login_screen.dart';
import 'package:tanza_store/tabs/scan_screen.dart';
import 'package:tanza_store/tabs/cashier_screen.dart';
import 'package:tanza_store/tabs/products_tab.dart';
import 'tabs/analytics_screen.dart';
// Import the generated file
import 'firebase_options.dart';

void main() async {
  // 1. Ensure Flutter binding is initialized
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // 2. Preserve the native splash screen
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 3. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final prefs = await SharedPreferences.getInstance();
  final hasSeeded = prefs.getBool('has_seeded_firestore') ?? false;
  if (!hasSeeded) {
    try {
      final syncService = SyncService();
      final uploaded = await syncService.pushAllProductsToFirestore();
      if (uploaded > 0) {
        if (kDebugMode) {
          print('Seeded $uploaded products to Firestore');
        }
        await prefs.setBool('has_seeded_firestore', true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Auto‑seed skipped or failed: $e');
      }
    }
  }

  debugPrint('Firebase initialized');
  runApp(const MyApp());
  debugPrint('runApp called');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tanza Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthWrapper(),
    );
  }
}

// In main.dart, you should have something like:
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _splashRemoved = false;

  @override
  void initState() {
    super.initState();
    debugPrint('AuthWrapper initState');
    // Force remove splash after 2 seconds regardless of auth state
    Future.delayed(const Duration(seconds: 2), () {
      if (!_splashRemoved && mounted) {
        debugPrint('Force removing splash after timeout');
        FlutterNativeSplash.remove();
        _splashRemoved = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('AuthWrapper build');
    final authService = AuthService();
    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, snapshot) {
        debugPrint(
            'StreamBuilder snapshot: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}');
        // Remove splash once we have any result (or after a short delay)
        if (!_splashRemoved &&
            snapshot.connectionState != ConnectionState.waiting) {
          debugPrint('Removing splash because auth state resolved');
          FlutterNativeSplash.remove();
          _splashRemoved = true;
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('Waiting for auth state...');
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          debugPrint('Auth error: ${snapshot.error}');
          return const Scaffold(
              body: Center(child: Text('Authentication error')));
        }
        final user = snapshot.data;
        debugPrint('User: ${user?.email ?? "null"}');
        if (user == null) {
          return const LoginScreen();
        }
        return const MainScreen();
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const ProductsTab(),
    const CashierScreen(),
    const ScanScreen(),
    const HistoryScreen(),
    const AnalyticsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Products',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale), label: 'Cashier'),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_2_outlined), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          )
        ],
      ),
    );
  }
}
