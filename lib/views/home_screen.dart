import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/database_helper.dart';
import '../models/code_item.dart';
import 'add_edit_screen.dart';
import 'details_screen.dart';
import 'scan_screen.dart';
import '../widgets/stat_card.dart';

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  List<CodeItem> _allCodes = [];
  List<CodeItem> _filteredCodes = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCodes();
    _searchController.addListener(_filterCodes);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCodes);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCodes() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final codes = await DatabaseHelper().getAllCodes();
    if (mounted) {
      setState(() {
        _allCodes = codes;
        _filteredCodes = codes;
        _loading = false;
      });
    }
  }

  void _filterCodes() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredCodes = _allCodes);
      return;
    }
    setState(() {
      _filteredCodes = _allCodes.where((item) {
        return item.name.toLowerCase().contains(query) ||
            item.code.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query);
      }).toList();
    });
  }

  Map<String, dynamic> _getStats() {
    if (_filteredCodes.isEmpty) {
      return {
        'totalProducts': 0,
        'totalValue': 0.0,
        'avgPrice': 0.0,
        'maxPrice': 0.0,
        'mostExpensive': '',
      };
    }
    double totalValue = 0;
    double maxPrice = 0;
    String mostExpensive = '';
    int withPrice = 0;
    for (var item in _filteredCodes) {
      if (item.price != null && item.price! > 0) {
        withPrice++;
        totalValue += item.price!;
        if (item.price! > maxPrice) {
          maxPrice = item.price!;
          mostExpensive = item.name;
        }
      }
    }
    final avgPrice = withPrice > 0 ? totalValue / withPrice : 0.0;
    return {
      'totalProducts': _filteredCodes.length,
      'totalValue': totalValue,
      'avgPrice': avgPrice,
      'maxPrice': maxPrice,
      'mostExpensive': mostExpensive,
    };
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About Tanza Store'),
        content: const Text(
          'Version 1.0\n\n'
          'A QR/Barcode scanner app that stores product information.\n'
          'Scan, add, edit, and manage your items easily.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _getStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tanza Store'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, code, or description...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
        actions: const [],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Tanza Store',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Manage your products',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scan'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanScreen()),
                );
                if (result == true && mounted) _loadCodes();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add New'),
              onTap: () async {
                Navigator.pop(context);
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
                if (result == true && mounted) _loadCodes();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Exit'),
              onTap: () {
                Navigator.pop(context);
                _confirmExit();
              },
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Cards (only show if not searching and products exist)
                if (_searchController.text.isEmpty && _filteredCodes.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            StatCard(
                              title: 'Total Products',
                              value: stats['totalProducts'].toString(),
                              icon: Icons.inventory,
                            ),
                            StatCard(
                              title: 'Inventory Value',
                              value:
                                  '₱${stats['totalValue'].toStringAsFixed(2)}',
                              icon: Icons.attach_money,
                              color: Colors.green.shade50,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            StatCard(
                              title: 'Average Price',
                              value: '₱${stats['avgPrice'].toStringAsFixed(2)}',
                              icon: Icons.trending_up,
                            ),
                            StatCard(
                              title: 'Most Expensive',
                              value: stats['mostExpensive'].isEmpty
                                  ? '—'
                                  : '${stats['mostExpensive']}\n₱${stats['maxPrice'].toStringAsFixed(2)}',
                              icon: Icons.leaderboard,
                              color: Colors.amber.shade50,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _filteredCodes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'No codes saved yet'
                                    : 'No matching codes found',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 8),
                          itemCount: _filteredCodes.length,
                          itemBuilder: (ctx, idx) {
                            final item = _filteredCodes[idx];
                            return Container(
                              margin: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            DetailsScreen(codeItem: item),
                                      ),
                                    );
                                    if (mounted) _loadCodes();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: item.type == 'qr'
                                                ? Colors.blue.shade50
                                                : Colors.green.shade50,
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: Icon(
                                            item.type == 'qr'
                                                ? Icons.qr_code_scanner
                                                : Icons.barcode_reader,
                                            color: item.type == 'qr'
                                                ? Colors.blue.shade700
                                                : Colors.green.shade700,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (item.price != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Price: ₱${item.price!.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: Colors.grey[400],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
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
              if (result == true && mounted) _loadCodes();
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
              if (result == true && mounted) _loadCodes();
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
