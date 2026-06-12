import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() =>
      _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  List<dynamic> _transactions = [];
  bool _loading = true;
  Map<int, bool> _processing = {};

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _loading = true);
    try {
      final data = await _apiService.getPendingTransactions();
      setState(() => _transactions = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal memuat transaksi: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleVerify(int id, String action) async {
    setState(() => _processing[id] = true);
    try {
      final message = await _apiService.verifyPayment(id, action);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
      await _fetchTransactions(); // refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _processing.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Pembayaran'),
        backgroundColor: const Color(0xFFC00000),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(child: Text('Tidak ada transaksi pending'))
              : RefreshIndicator(
                  onRefresh: _fetchTransactions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final t = _transactions[index];
                      final isLoading = _processing[t['id']] ?? false;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID Transaksi: ${t['transaction_id']}'),
                              Text('User ID: ${t['user_id']}'),
                              Text('Ticket ID: ${t['ticket_id']}'),
                              Text('Jumlah: ${t['quantity']}'),
                              Text('Total: Rp ${t['total_price']}'),
                              Text('Status: ${t['status']}'),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: isLoading
                                          ? null
                                          : () =>
                                              _handleVerify(t['id'], 'approve'),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green),
                                      child: isLoading
                                          ? const CircularProgressIndicator()
                                          : const Text('Approve'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: isLoading
                                          ? null
                                          : () =>
                                              _handleVerify(t['id'], 'reject'),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red),
                                      child: isLoading
                                          ? const CircularProgressIndicator()
                                          : const Text('Reject'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
