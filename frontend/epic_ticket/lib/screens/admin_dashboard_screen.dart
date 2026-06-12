import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'admin_scan_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _transactions = [];
  bool _loading = true;
  Map<int, bool> _processing = {};

  @override
  void initState() {
    super.initState();
    _fetchPendingTransactions();
  }

  Future<void> _fetchPendingTransactions() async {
    setState(() => _loading = true);
    try {
      final data = await _apiService.getPendingTransactions();
      setState(() => _transactions = data);
    } catch (e) {
      // if error, maybe user is not admin
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleVerify(int id, String action) async {
    setState(() => _processing[id] = true);
    try {
      await _apiService.verifyPayment(id, action);
      await _fetchPendingTransactions();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Transaction ${action}d'),
            backgroundColor: Colors.green),
      );
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('EPIC TICKET',
            style: TextStyle(fontStyle: FontStyle.italic)),
        backgroundColor: const Color(0xFF121414),
        foregroundColor: const Color(0xFFFFB4A8),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService().logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Navigation drawer (simplified)
          Container(
            width: 260,
            color: const Color(0xFF1E2020),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF8B0000),
                        child: Icon(Icons.person, color: Color(0xFFFF907F)),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Admin Portal',
                              style: TextStyle(
                                  color: Color(0xFFFFB4A8), fontSize: 16)),
                          Text('System Controller',
                              style: TextStyle(
                                  color: Color(0xFFE3BEB8), fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0x4C5A403C), thickness: 1),
                _drawerItem('Dashboard', true),
                _drawerItem('Sales Report', false),
                _drawerItem('Scanner', false),
                _drawerItem('Event Settings', false),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF282A2B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF5A403C)),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Color(0xFF8B0000),
                          child: Icon(Icons.admin_panel_settings,
                              size: 40, color: Color(0xFFFFB4A8)),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Welcome back, Admin.',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700)),
                              SizedBox(height: 8),
                              Text(
                                'The system is running optimally. You have 14 transactions awaiting verification.',
                                style: TextStyle(
                                    color: Color(0xFFE3BEB8), fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats cards
                  Row(
                    children: [
                      _statCard('REVENUE TODAY', '\$14,290', '+12%'),
                      const SizedBox(width: 16),
                      _statCard('TICKETS SOLD', '1,024', '+5%'),
                      const SizedBox(width: 16),
                      _statCard('PENDING APPROVAL', '14', 'Action Required'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Pending transactions list
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C0F0F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF5A403C)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 20),
                          decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: Color(0xFF5A403C))),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Transaksi Pending',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16)),
                              Text('VIEW ALL',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_transactions.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                                child: Text('Tidak ada transaksi pending',
                                    style:
                                        TextStyle(color: Color(0xFFE3BEB8)))),
                          )
                        else
                          ..._transactions
                              .map((t) => _transactionTile(t))
                              .toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(String title, bool isActive) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFB4A8) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isActive ? const Color(0xFF690000) : const Color(0xFFE3BEB8),
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, String change) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2020),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF5A403C)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Color(0xFFE3BEB8),
                    fontSize: 16,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700)),
                Text(change,
                    style: TextStyle(
                        color: change.contains('%')
                            ? const Color(0xFF4AE183)
                            : const Color(0xFFFFB4A8),
                        fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _transactionTile(dynamic t) {
    final isProcessing = _processing[t['id']] ?? false;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF5A403C))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF8B0000),
                child: Text(t['user_id'].toString(),
                    style: const TextStyle(color: Color(0xFFFF907F))),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User ${t['user_id']}',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    '${t['quantity']} tiket - Rp ${t['total_price']}',
                    style:
                        const TextStyle(color: Color(0xFFE3BEB8), fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () => _handleVerify(t['id'], 'approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB4A8),
                  foregroundColor: const Color(0xFF690000),
                ),
                child: const Text('Approve'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: isProcessing
                    ? null
                    : () => _handleVerify(t['id'], 'reject'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF5A403C)),
                  foregroundColor: const Color(0xFFFFB4AB),
                ),
                child: const Text('Reject'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
