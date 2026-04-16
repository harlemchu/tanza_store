import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/database_helper.dart';
import '../models/code_item.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _lastSyncKey = 'last_products_sync_timestamp';

  // ------------------------------------------------------------------
  // Helper: check internet connection
  // ------------------------------------------------------------------
  Future<bool> hasInternetConnection() async {
    final List<ConnectivityResult> connectivityResult =
        await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }
    return true;
  }

  // ------------------------------------------------------------------
  // Get / update last sync timestamp (for incremental pull)
  // ------------------------------------------------------------------
  Future<DateTime?> _getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestampMs = prefs.getInt(_lastSyncKey);
    if (timestampMs == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestampMs);
  }

  Future<void> _updateLastSyncTimestamp(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, timestamp.millisecondsSinceEpoch);
  }

  // ------------------------------------------------------------------
  // 1. PUSH: Upload all local products to Firestore (only if empty)
  //    - Fixes empty codes by generating a new code and updating DB
  //    - Stores full product details
  //    - Uses collection 'products'
  // ------------------------------------------------------------------
  Future<int> pushAllProductsToFirestore(
      {Function(int, int)? onProgress}) async {
    if (!await hasInternetConnection()) {
      throw Exception('No internet connection. Please check your network.');
    }

    // Get all local products
    List<CodeItem> localProducts = await _dbHelper.getAllCodes();

    // Fix empty codes
    bool needRefresh = false;
    for (int i = 0; i < localProducts.length; i++) {
      final product = localProducts[i];
      if (product.code.trim().isEmpty) {
        final newCode =
            'gen_${product.id}_${DateTime.now().millisecondsSinceEpoch}';
        final updatedProduct = CodeItem(
          id: product.id,
          code: newCode,
          type: product.type,
          name: product.name,
          description: product.description,
          price: product.price,
          createdAt: product.createdAt,
        );
        await _dbHelper.updateCode(updatedProduct);
        localProducts[i] = updatedProduct;
        needRefresh = true;
      }
    }
    if (needRefresh) {
      localProducts = await _dbHelper.getAllCodes();
    }

    if (localProducts.isEmpty) {
      throw Exception('No products found in local database.');
    }

    // Check if Firestore 'products' collection already has data
    final existingDocs = await _firestore.collection('products').limit(1).get();
    if (existingDocs.docs.isNotEmpty) {
      throw Exception(
          'Firestore already contains product data. Use sync (pull) for updates.');
    }

    // Upload all products in batches of 500
    int uploaded = 0;
    final int total = localProducts.length;
    for (int i = 0; i < total; i += 500) {
      final end = (i + 500 < total) ? i + 500 : total;
      final batch = _firestore.batch();
      for (int j = i; j < end; j++) {
        final product = localProducts[j];
        final docRef = _firestore.collection('products').doc(product.code);
        batch.set(docRef, {
          'code': product.code,
          'name': product.name,
          'type': product.type,
          'description': product.description,
          'price': product.price ?? 0.0,
          'createdAt': product.createdAt.toIso8601String(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      uploaded += (end - i);
      if (onProgress != null) {
        onProgress(total, uploaded);
      }
    }
    return uploaded;
  }

  // ------------------------------------------------------------------
  // 2. PULL: Download all product details from Firestore (incremental)
  //    - Fetches documents where updatedAt > lastSync
  //    - Updates local products if any field changed, inserts new ones
  //    - Returns number of local products affected
  // ------------------------------------------------------------------
  Future<int> syncProducts({Function(int, int)? onProgress}) async {
    if (!await hasInternetConnection()) {
      throw Exception('No internet connection. Please check your network.');
    }

    final lastSync = await _getLastSyncTimestamp();
    Query query = _firestore.collection('products');
    if (lastSync != null) {
      query = query.where('updatedAt', isGreaterThan: lastSync);
    }

    final querySnapshot = await query.get();
    final List<CodeItem> changedItems = [];

    for (var doc in querySnapshot.docs) {
      final code = doc.id;
      if (code.isEmpty) continue;

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      // Extract fields from Firestore
      final String name = data['name'] ?? '';
      final String type = data['type'] ?? 'barcode';
      final String description = data['description'] ?? '';
      final double price = (data['price'] as num?)?.toDouble() ?? 0.0;
      final String createdAtStr =
          data['createdAt'] ?? DateTime.now().toIso8601String();
      final DateTime createdAt =
          DateTime.tryParse(createdAtStr) ?? DateTime.now();

      // Check if product already exists locally
      final existingItem = await _dbHelper.getCodeByCode(code);

      if (existingItem == null) {
        // New product – insert
        final newItem = CodeItem(
          code: code,
          type: type,
          name: name,
          description: description,
          price: price,
          createdAt: createdAt,
        );
        await _dbHelper.insertCode(newItem);
        changedItems.add(newItem);
      } else {
        // Existing product – compare fields and update if different
        bool needsUpdate = false;
        if (existingItem.name != name) needsUpdate = true;
        if (existingItem.type != type) needsUpdate = true;
        if (existingItem.description != description) needsUpdate = true;
        if (existingItem.price != price) needsUpdate = true;
        // (createdAt should not change, but if it does, update)
        if (existingItem.createdAt != createdAt) needsUpdate = true;

        if (needsUpdate) {
          final updatedItem = CodeItem(
            id: existingItem.id,
            code: existingItem.code,
            type: type,
            name: name,
            description: description,
            price: price,
            createdAt: createdAt,
          );
          await _dbHelper.updateCode(updatedItem);
          changedItems.add(updatedItem);
        }
      }

      if (onProgress != null) {
        onProgress(querySnapshot.docs.length, changedItems.length);
      }
    }

    // Update last sync timestamp to now
    await _updateLastSyncTimestamp(DateTime.now());
    return changedItems.length;
  }
}
