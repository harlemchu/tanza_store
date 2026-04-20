class AppConstants {
  // App info
  static const String appName = 'Tanza Store';
  static const String appVersion = '1.0.0';

  // Database & Firestore
  static const String dbName = 'codes.db';
  static const String productsCollection = 'products';
  static const String transactionsTable = 'transactions';

  // SharedPreferences keys
  static const String lastSyncKey = 'last_products_sync_timestamp';
  static const String hasSeededFirestoreKey = 'has_seeded_firestore';

  // Timeouts (in milliseconds)
  static const int syncTimeoutMs = 30000;
  static const int splashDelayMs = 2000;

  // Regular expressions
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Payment methods
  static const List<String> paymentMethods = ['cash', 'card', 'gcash'];
}
