class CodeItem {
  int? id;
  final String code;
  final String type;
  String name;
  String description;
  double? price;
  int stock; // new field
  final DateTime createdAt;

  CodeItem({
    this.id,
    required this.code,
    required this.type,
    required this.name,
    required this.description,
    this.price,
    this.stock = 0, // default 0
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'type': type,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock, // added
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CodeItem.fromMap(Map<String, dynamic> map) {
    return CodeItem(
      id: map['id'],
      code: map['code'],
      type: map['type'],
      name: map['name'],
      description: map['description'],
      price: map['price'] != null ? (map['price'] as num).toDouble() : null,
      stock: map['stock'] ?? 0, // handle old records
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
