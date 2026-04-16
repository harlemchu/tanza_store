import 'dart:convert';
import 'package:tanza_store/models/code_item.dart';

import 'cart_item.dart';

class ProductTransaction {
  final String id;
  final DateTime createdAt;
  final List<CartItem> items;
  final double total;
  final double paid;
  final double change;
  final String paymentMethod; // e.g., 'cash', 'card'

  ProductTransaction({
    required this.id,
    required this.createdAt,
    required this.items,
    required this.total,
    required this.paid,
    required this.change,
    required this.paymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'total': total,
      'paid': paid,
      'change': change,
      'paymentMethod': paymentMethod,
      'itemsJson': jsonEncode(items
          .map((e) => {
                'code': e.product.code,
                'name': e.product.name,
                'price': e.product.price,
                'quantity': e.quantity,
              })
          .toList()),
    };
  }

  factory ProductTransaction.fromMap(Map<String, dynamic> map) {
    final itemsList = jsonDecode(map['itemsJson']) as List;
    return ProductTransaction(
      id: map['id'],
      createdAt: DateTime.parse(map['createdAt']),
      total: map['total'],
      paid: map['paid'],
      change: map['change'],
      paymentMethod: map['paymentMethod'],
      items: itemsList.map((item) {
        // For display purposes, we recreate a simplified product.
        // If you need full CodeItem, you could fetch from DB using the code.
        return CartItem(
          product: CodeItem(
            code: item['code'],
            name: item['name'],
            price: (item['price'] as num).toDouble(),
            type: 'barcode', // fallback
            description: '',
            createdAt: DateTime.now(),
          ),
          quantity: item['quantity'],
        );
      }).toList(),
    );
  }
}
