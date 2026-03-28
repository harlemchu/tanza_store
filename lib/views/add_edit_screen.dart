import 'package:flutter/material.dart';
import '../controllers/database_helper.dart';
import '../models/code_item.dart';

class AddEditScreen extends StatefulWidget {
  final String code;
  final String type;
  final bool isEditing;
  final CodeItem? existingItem;

  const AddEditScreen({
    super.key,
    required this.code,
    required this.type,
    required this.isEditing,
    this.existingItem,
  });

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.existingItem != null) {
      _nameController = TextEditingController(text: widget.existingItem!.name);
      _descController =
          TextEditingController(text: widget.existingItem!.description);
      _priceController = TextEditingController(
        text: widget.existingItem!.price != null
            ? widget.existingItem!.price.toString()
            : '',
      );
    } else {
      _nameController = TextEditingController();
      _descController = TextEditingController();
      _priceController = TextEditingController();
      if (widget.code.isNotEmpty) {
        _nameController.text = widget.code;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose(); // <-- dispose
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Parse price
    double? price;
    if (_priceController.text.trim().isNotEmpty) {
      price = double.tryParse(_priceController.text.trim());
      if (price == null) {
        // Show error if price is invalid
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter a valid number for price')),
        );
        return;
      }
      if (price < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Price cannot be negative')),
        );
        return;
      }
    }

    final db = DatabaseHelper();
    if (widget.isEditing && widget.existingItem != null) {
      final updated = CodeItem(
        id: widget.existingItem!.id,
        code: widget.existingItem!.code,
        type: widget.existingItem!.type,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: price, // <-- include price
        createdAt: widget.existingItem!.createdAt,
      );
      await db.updateCode(updated);
    } else {
      final newItem = CodeItem(
        code: widget.code,
        type: widget.type,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: price, // <-- include price
        createdAt: DateTime.now(),
      );
      await db.insertCode(newItem);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Code' : 'Add New Code'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isEditing) ...[
                  Text('Code: ${widget.code}'),
                  const SizedBox(height: 8),
                  Text('Type: ${widget.type.toUpperCase()}'),
                  const Divider(),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g., Product Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.blue.shade700, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Price',
                    hintText: 'e.g., 19.99',
                    prefixText: '\₱ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.blue.shade700, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    if (val == null || val.isEmpty) return null; // optional
                    final parsed = double.tryParse(val);
                    if (parsed == null) return 'Enter a valid number';
                    if (parsed < 0) return 'Price cannot be negative';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Additional info',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.blue.shade700, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // button background
                      foregroundColor: Colors.white, // text/icon color
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(widget.isEditing ? 'Update' : 'Save'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
