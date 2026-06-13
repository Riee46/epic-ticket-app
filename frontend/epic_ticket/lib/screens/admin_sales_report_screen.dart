import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminSalesReportScreen extends StatefulWidget {
  const AdminSalesReportScreen({super.key});

  @override
  State<AdminSalesReportScreen> createState() => _AdminSalesReportScreenState();
}

class _AdminSalesReportScreenState extends State<AdminSalesReportScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _paidTransactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchSales();
  }

  Future<void> _fetchSales() async {
    setState(() => _loading = true);
    try {
      final data = await _apiService.getPaidTransactions();
      setState(() => _paidTransactions = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal memuat laporan: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  String _formatRupiah(int price) {
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    int totalRevenue = _paidTransactions.fold<int>(
        0, (sum, t) => sum + (t['total_price'] as int? ?? 0));
    int totalTickets = _paidTransactions.fold<int>(
        0, (sum, t) => sum + (t['quantity'] as int? ?? 0));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Sales Report'),
        backgroundColor: const Color(0xFF1E2020),
        foregroundColor: const Color(0xFFFFB4A8),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  color: const Color(0xFF121414),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Total Revenue',
                              style: TextStyle(color: Color(0xFFE3BEB8))),
                          const SizedBox(height: 8),
                          Text(_formatRupiah(totalRevenue),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Tickets Sold',
                              style: TextStyle(color: Color(0xFFE3BEB8))),
                          const SizedBox(height: 8),
                          Text(totalTickets.toString(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _paidTransactions.isEmpty
                      ? const Center(
                          child: Text('Belum ada penjualan',
                              style: TextStyle(color: Color(0xFFE3BEB8))))
                      : ListView.builder(
                          itemCount: _paidTransactions.length,
                          itemBuilder: (context, index) {
                            final t = _paidTransactions[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF8B0000),
                                child: Text('${t['quantity']}',
                                    style: const TextStyle(
                                        color: Color(0xFFFF907F))),
                              ),
                              title: Text('User ID: ${t['user_id']}',
                                  style: const TextStyle(color: Colors.white)),
                              subtitle: Text(
                                  'Transaction ID: ${t['transaction_id']}',
                                  style: const TextStyle(
                                      color: Color(0xFFE3BEB8))),
                              trailing: Text(_formatRupiah(t['total_price']),
                                  style: const TextStyle(
                                      color: Color(0xFF4AE183),
                                      fontWeight: FontWeight.bold)),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
