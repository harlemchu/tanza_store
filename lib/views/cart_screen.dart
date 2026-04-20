import 'package:flutter/material.dart';
import 'package:tanza_store/controllers/database_helper.dart';
import 'package:tanza_store/models/cart_item.dart';
import 'package:tanza_store/models/product_transaction.dart';

class CartScreen extends StatefulWidget {
  final List<CartItem> cart;
  final double total;
  const CartScreen({super.key, required this.cart, required this.total});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _paidController = TextEditingController();
  String _paymentMethod = 'cash';
  double _change = 0.0;
  bool _isProcessing = false;

  void _calculateChange() {
    final paid = double.tryParse(_paidController.text) ?? 0;
    setState(() => _change = paid - widget.total);
  }

  Future<void> _completeTransaction() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final paid = double.tryParse(_paidController.text) ?? 0;
      if (paid < widget.total) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insufficient payment')),
        );
        _isProcessing = false;
        return;
      }

      // Deduct stock for each cart item
      for (var cartItem in widget.cart) {
        final product = cartItem.product;
        final newStock = product.stock - cartItem.quantity;
        if (newStock < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Insufficient stock for ${product.name}')),
          );
          _isProcessing = false;
          return;
        }
        await DatabaseHelper().updateStock(product.code, newStock);
      }

      // Save transaction
      final transaction = ProductTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        items: widget.cart,
        total: widget.total,
        paid: paid,
        change: paid - widget.total,
        paymentMethod: _paymentMethod,
      );
      await DatabaseHelper().insertTransaction(transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Transaction completed!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e, stack) {
      debugPrint('Transaction error: $e');
      debugPrint('Stack trace: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: widget.cart.length,
                itemBuilder: (ctx, idx) {
                  final item = widget.cart[idx];
                  return ListTile(
                    title: Text(item.product.name),
                    subtitle: Text('${item.quantity} x ₱${item.product.price}'),
                    trailing: Text('₱${item.subtotal.toStringAsFixed(2)}'),
                  );
                },
              ),
            ),
            const Divider(),
            Text('Total: ₱${widget.total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'card', child: Text('Card')),
                DropdownMenuItem(value: 'gcash', child: Text('GCash')),
              ],
              onChanged: (val) => setState(() => _paymentMethod = val!),
              decoration: const InputDecoration(labelText: 'Payment Method'),
            ),
            TextField(
              controller: _paidController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount Paid'),
              onChanged: (_) => _calculateChange(),
            ),
            if (_change >= 0)
              Text('Change: ₱${_change.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, color: Colors.green)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _completeTransaction,
              icon: const Icon(Icons.check_circle),
              label: const Text('Complete Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
