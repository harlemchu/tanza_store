import 'package:flutter/material.dart';
import '../controllers/database_helper.dart';
import '../models/code_item.dart';
import 'add_edit_screen.dart';
import 'details_screen.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CodeItem> _codes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCodes();
  }

  Future<void> _loadCodes() async {
    setState(() => _loading = true);
    final codes = await DatabaseHelper().getAllCodes();
    setState(() {
      _codes = codes;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product List'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _codes.isEmpty
              ? const Center(child: Text('No codes saved yet'))
              : ListView.builder(
                  itemCount: _codes.length,
                  itemBuilder: (ctx, idx) {
                    final item = _codes[idx];
                    return ListTile(
                      leading: Icon(
                        item.type == 'qr'
                            ? Icons.qr_code
                            : Icons.barcode_reader,
                      ),
                      title: Text(item.name),
                      subtitle: Text(item.code),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailsScreen(codeItem: item),
                          ),
                        );
                        _loadCodes(); // refresh after potential edit/delete
                      },
                    );
                  },
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'scan',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              );
              if (result == true) _loadCodes();
            },
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddEditScreen(
                    code: '',
                    type: 'barcode',
                    isEditing: false,
                  ),
                ),
              );
              if (result == true) _loadCodes();
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
