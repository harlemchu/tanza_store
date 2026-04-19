import 'package:flutter/material.dart';
import '../models/code_item.dart';
import '../models/cart_item.dart';
import '../controllers/database_helper.dart';
import 'scan_screen.dart';
import '../views/cart_screen.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final List<CartItem> _cart = [];
  final TextEditingController _searchController = TextEditingController();
  List<CodeItem> _searchResults = [];

  // Add a product to the cart
  // void _addToCart(CodeItem product) {
  //   setState(() {
  //     final existing = _cart.indexWhere((item) =>
  //         item.product.code ==
  //         product
  //             .code); //_cart.firstWhereOrNull((item) => item.product.code == product.code);
  //     _cart[existing].quantity++; //existing.quantity++;
  //         _searchController.clear();
  //     _searchResults.clear();
  //   });
  // }

  // void _addToCart(CodeItem product) {
  //   setState(() {
  //     final existingIndex = _cart.indexWhere(
  //       (item) => item.product.code == product.code,
  //     );
  //     if (existingIndex != -1) {
  //       // Product already in cart – increase quantity
  //       _cart[existingIndex].quantity++;
  //     } else {
  //       // New product – add to cart
  //       _cart.add(CartItem(product: product));
  //     }
  //     _searchController.clear();
  //     _searchResults.clear();
  //   });
  // }

  void _addToCart(CodeItem product) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Out of stock! Cannot add to cart.')),
      );
      return;
    }
    setState(() {
      final existingIndex =
          _cart.indexWhere((item) => item.product.code == product.code);
      if (existingIndex != -1) {
        // Check if adding another would exceed stock
        if (_cart[existingIndex].quantity + 1 > product.stock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Only ${product.stock} in stock. Cannot add more.')),
          );
          return;
        }
        _cart[existingIndex].quantity++;
      } else {
        _cart.add(CartItem(product: product));
      }
      _searchController.clear();
      _searchResults.clear();
    });
  }

  // Remove or update quantity (same as before)
  void _removeFromCart(CartItem item) {
    setState(() => _cart.remove(item));
  }

  void _updateQuantity(CartItem item, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _cart.remove(item);
      } else {
        item.quantity = newQuantity;
      }
    });
  }

  double get _total => _cart.fold(0, (sum, item) => sum + item.subtotal);

  // Search local products by name or code
  void _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final all = await DatabaseHelper().getAllCodes();
    setState(() {
      _searchResults = all
          .where((p) =>
              p.name.toLowerCase().contains(query.toLowerCase()) ||
              p.code.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _scanAndAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ScanScreen(isCashierMode: true),
      ),
    );
    if (result != null && result is CodeItem) {
      _addToCart(result);
    } else if (result != null && result is String) {
      // If you only returned the code, fetch product
      final product = await DatabaseHelper().getCodeByCode(result);
      if (product != null) _addToCart(product);
    } else {
      // User cancelled or error
    }
  }

  void _checkout() async {
    if (_cart.isEmpty) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(cart: _cart, total: _total),
      ),
    );
    if (result == true) {
      setState(() => _cart.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction completed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: _checkout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search product by name or code',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanAndAdd,
                ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _searchProducts,
            ),
          ),
          // Search results
          if (_searchResults.isNotEmpty)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade200, blurRadius: 4)
                ],
              ),
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (ctx, idx) {
                  final product = _searchResults[idx];
                  return ListTile(
                    leading: const Icon(Icons.add_shopping_cart),
                    title: Text(product.name),
                    subtitle:
                        Text('₱${product.price?.toStringAsFixed(2) ?? '0.00'}'),
                    trailing: const Icon(Icons.add),
                    onTap: () => _addToCart(product),
                  );
                },
              ),
            ),
          // Cart list
          Expanded(
            child: _cart.isEmpty
                ? const Center(
                    child: Text('Cart is empty. Search or scan a product.'))
                : ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (ctx, idx) {
                      final item = _cart[idx];
                      return ListTile(
                        leading: Text('${item.quantity}x'),
                        title: Text(item.product.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '₱${item.product.price!.toStringAsFixed(2)} each'),
                            Text('In stock: ${item.product.stock}',
                                // ignore: prefer_const_constructors
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () =>
                                  _updateQuantity(item, item.quantity - 1),
                            ),
                            Text(item.quantity.toString()),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () =>
                                  _updateQuantity(item, item.quantity + 1),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeFromCart(item),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Total bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              boxShadow: const [BoxShadow(blurRadius: 4)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('₱${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _checkout,
                  icon: const Icon(Icons.payment),
                  label: const Text('Checkout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
