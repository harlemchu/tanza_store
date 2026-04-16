import 'package:tanza_store/models/code_item.dart';

class CartItem {
  final CodeItem product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price! * quantity;
}
