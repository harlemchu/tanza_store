import 'package:flutter/material.dart';
import 'package:tanza_store/controllers/database_helper.dart';
import 'package:tanza_store/models/product_transaction.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ProductTransaction> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final transactions = await DatabaseHelper().getAllTransactions();
    setState(() {
      _transactions = transactions;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase History'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(child: Text('No transactions yet'))
              : ListView.builder(
                  itemCount: _transactions.length,
                  itemBuilder: (ctx, idx) {
                    final t = _transactions[idx];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ExpansionTile(
                        title: Text('₱${t.total.toStringAsFixed(2)}'),
                        subtitle: Text(
                            '${t.createdAt.toLocal()} · ${t.paymentMethod}'),
                        trailing: Text('${t.items.length} items'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: t.items.map((item) {
                                return ListTile(
                                  title: Text(item.product.name),
                                  subtitle: Text(
                                      '${item.quantity} x ₱${item.product.price}'),
                                  trailing: Text(
                                      '₱${item.subtotal.toStringAsFixed(2)}'),
                                );
                              }).toList(),
                            ),
                          ),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Paid: ₱${t.paid.toStringAsFixed(2)}'),
                                Text('Change: ₱${t.change.toStringAsFixed(2)}'),
                                Text('Payment: ${t.paymentMethod}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
