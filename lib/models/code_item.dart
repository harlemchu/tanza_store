class CodeItem {
  int? id;
  final String code;
  final String type; // 'barcode' or 'qr'
  String name;
  String description;
  double? price; // <-- new field, nullable
  final DateTime createdAt;

  CodeItem({
    this.id,
    required this.code,
    required this.type,
    required this.name,
    required this.description,
    required this.price, // <-- added
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
      price: map['price'] != null
          ? (map['price'] as num).toDouble()
          : null, // <-- handle null
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
