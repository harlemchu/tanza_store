import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tanza_store/services/sync_service.dart';
import 'package:tanza_store/views/history_screen.dart';
import 'package:tanza_store/views/scan_screen.dart';
import 'package:tanza_store/views/cashier_screen.dart';
import 'package:tanza_store/views/products_tab.dart';
import 'views/analytics_screen.dart';
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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tanza Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainScreen(),
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
