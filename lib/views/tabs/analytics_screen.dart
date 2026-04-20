import 'package:flutter/material.dart';
import 'package:tanza_store/controllers/database_helper.dart';
import 'package:tanza_store/models/code_item.dart';
import 'package:tanza_store/widgets/stat_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<CodeItem> _codes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final codes = await DatabaseHelper().getAllCodes();
      if (mounted) {
        setState(() {
          _codes = codes;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Map<String, dynamic> _getStats() {
    if (_codes.isEmpty) {
      return {
        'totalProducts': 0,
        'totalValue': 0.0,
        'avgPrice': 0.0,
        'maxPrice': 0.0,
        'mostExpensive': '',
        'productsWithPrice': 0,
      };
    }

    double totalValue = 0.0;
    double maxPrice = 0.0;
    String mostExpensive = '';
    int productsWithPrice = 0;

    for (var item in _codes) {
      if (item.price != null && item.price! > 0) {
        productsWithPrice++;
        totalValue += item.price!;
        if (item.price! > maxPrice) {
          maxPrice = item.price!;
          mostExpensive = item.name;
        }
      }
    }

    final avgPrice =
        productsWithPrice > 0 ? totalValue / productsWithPrice : 0.0;

    return {
      'totalProducts': _codes.length,
      'totalValue': totalValue,
      'avgPrice': avgPrice,
      'maxPrice': maxPrice,
      'mostExpensive': mostExpensive,
      'productsWithPrice': productsWithPrice,
    };
  }

  List<CodeItem> _getTopExpensive() {
    final withPrice =
        _codes.where((c) => c.price != null && c.price! > 0).toList();
    withPrice.sort((a, b) => b.price!.compareTo(a.price!));
    return withPrice.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    final stats = _getStats();
    final topExpensive = _getTopExpensive();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Analytics'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            const Text(
              'Financial Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
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
                      '₱${(stats['totalValue'] as double).toStringAsFixed(2)}',
                  icon: Icons.attach_money,
                  color: Colors.green.shade50,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                StatCard(
                  title: 'Average Price',
                  value: '₱${(stats['avgPrice'] as double).toStringAsFixed(2)}',
                  icon: Icons.trending_up,
                ),
                StatCard(
                  title: 'Most Expensive',
                  value: stats['mostExpensive'].toString().isEmpty
                      ? '—'
                      : '${stats['mostExpensive']}\n₱${(stats['maxPrice'] as double).toStringAsFixed(2)}',
                  icon: Icons.leaderboard,
                  color: Colors.amber.shade50,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Price Distribution
            const Text(
              'Price Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildPriceDistribution(),
            const SizedBox(height: 24),

            // Top 5 Most Expensive Products
            const Text(
              'Top 5 Most Expensive Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (topExpensive.isEmpty)
              const Center(child: Text('No products with price yet'))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topExpensive.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (ctx, idx) {
                  final item = topExpensive[idx];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text('${idx + 1}'),
                    ),
                    title: Text(item.name),
                    subtitle: Text(item.code),
                    trailing: Text(
                      '₱${item.price!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDistribution() {
    final prices = _codes
        .where((c) => c.price != null && c.price! > 0)
        .map((c) => c.price!)
        .toList();
    if (prices.isEmpty) {
      return const Center(child: Text('No price data available'));
    }

    // Define price ranges (in PHP)
    const ranges = [
      {'min': 0.0, 'max': 50.0, 'label': '₱0-50'},
      {'min': 50.0, 'max': 100.0, 'label': '₱50-100'},
      {'min': 100.0, 'max': 200.0, 'label': '₱100-200'},
      {'min': 200.0, 'max': 500.0, 'label': '₱200-500'},
      {'min': 500.0, 'max': double.infinity, 'label': '₱500+'},
    ];

    List<int> counts = List.filled(ranges.length, 0);
    for (var price in prices) {
      for (int i = 0; i < ranges.length; i++) {
        final min = ranges[i]['min'] as double;
        final max = ranges[i]['max'] as double;
        if (price >= min && price < max) {
          counts[i]++;
          break;
        }
      }
    }

    final maxCount = counts.reduce((a, b) => a > b ? a : b);

    // If maxCount is 0, nothing to show (already handled by prices.isEmpty)
    return Column(
      children: List.generate(ranges.length, (i) {
        final count = counts[i];
        double value = maxCount > 0 ? count / maxCount : 0.0;
        // Clamp to [0,1] and ensure double
        value = value.clamp(0.0, 1.0).toDouble();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(ranges[i]['label'] as String),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: value, // now explicitly a double
                  backgroundColor: Colors.grey.shade200,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                  minHeight: 20,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text('$count', textAlign: TextAlign.right),
              ),
            ],
          ),
        );
      }),
    );
  }
}
