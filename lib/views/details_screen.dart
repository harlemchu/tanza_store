import 'package:flutter/material.dart';
import '../controllers/database_helper.dart';
import '../models/code_item.dart';
import 'add_edit_screen.dart';

class DetailsScreen extends StatefulWidget {
  final CodeItem codeItem;

  const DetailsScreen({super.key, required this.codeItem});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late CodeItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.codeItem;
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper().deleteCode(_item.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _edit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditScreen(
          code: _item.code,
          type: _item.type,
          isEditing: true,
          existingItem: _item,
        ),
      ),
    );
    if (result == true) {
      // Refresh data
      final updated = await DatabaseHelper().getCodeByCode(_item.code);
      if (updated != null && mounted) {
        setState(() {
          _item = updated;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(onPressed: _edit, icon: const Icon(Icons.edit)),
          IconButton(onPressed: _delete, icon: const Icon(Icons.delete)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 1),
                ),
                child: Image.asset(
                  'assets/' + _item.name + '.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported),
                ),
              ),
              title: Text(
                _item.name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              subtitle: const Text('Stock:'),
            ),
            const Divider(),
            const SizedBox(height: 16),
            const SizedBox(height: 8),
            Text(
              _item.price != null
                  ? '\Price: ₱${_item.price!.toStringAsFixed(2)}'
                  : '—',
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 8),
            Text(_item.type == 'qr'
                ? 'QR Code: ${_item.code}'
                : 'BarCode: ${_item.code}'),
            const SizedBox(height: 16),
            const Text('Description:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_item.description.isEmpty ? '—' : _item.description),
            const Spacer(),
            Text('Added: ${_formatDate(_item.createdAt)}'),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}
