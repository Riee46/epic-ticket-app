import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'admin_scan_screen.dart';
import 'admin_sales_report_screen.dart';
import 'admin_event_settings_screen.dart';

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
  int _selectedIndex = 0;
  int _totalRevenue = 0;
  int _totalTickets = 0;
  int _pendingApproval = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _loading = true);
    try {
      final transactions = await _apiService.getPendingTransactions();
      final stats = await _apiService.getAdminStats();
      setState(() {
        _transactions = transactions;
        _totalRevenue = stats['total_revenue'] ?? 0;
        _totalTickets = stats['tickets_sold'] ?? 0;
        _pendingApproval = stats['pending_approval'] ?? _transactions.length;
      });
    } catch (e) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleVerify(int id, String action) async {
    setState(() => _processing[id] = true);
    try {
      await _apiService.verifyPayment(id, action);
      await _fetchDashboardData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Transaction ${action}d'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _processing.remove(id));
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context); // close drawer
    if (index == 2) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AdminScanScreen()));
    } else if (index == 1) {
      // Sales Report
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AdminSalesReportScreen()));
    } else if (index == 3) {
      // Event Settings
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AdminEventSettingsScreen()));
    }
  }

  String _formatRupiah(int price) {
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
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
              await _apiService.logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E2020),
        child: Column(
          children: [
            const SizedBox(height: 48), // Padding status bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
            _buildDrawerItem('Dashboard', 0, Icons.dashboard),
            _buildDrawerItem('Sales Report', 1, Icons.bar_chart),
            _buildDrawerItem('Scanner', 2, Icons.qr_code_scanner),
            _buildDrawerItem('Event Settings', 3, Icons.settings),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Version 1.0',
                style: TextStyle(
                    color: const Color(0xFFE3BEB8).withOpacity(0.5),
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
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
                            children: [
                              const Text('Welcome back, Admin.',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text(
                                'The system is running optimally. You have $_pendingApproval transactions awaiting verification.',
                                style: const TextStyle(
                                    color: Color(0xFFE3BEB8), fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stat Cards
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatCard('REVENUE TODAY', _formatRupiah(_totalRevenue), '+12%'),
                        const SizedBox(width: 16),
                        _buildStatCard('TICKETS SOLD', _totalTickets.toString(), '+5%'),
                        const SizedBox(width: 16),
                        _buildStatCard('PENDING APPROVAL', _pendingApproval.toString(), 'Action Required'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Pending Transactions List
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
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
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
                              .map((t) => _buildTransactionTile(t))
                              .toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDrawerItem(String title, int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon,
          color:
              isSelected ? const Color(0xFF690000) : const Color(0xFFE3BEB8)),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF690000) : const Color(0xFFE3BEB8),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFFFFB4A8),
      onTap: () => _onItemTapped(index),
    );
  }

  Widget _buildStatCard(String label, String value, String change) {
    return Container(
      width: 240,
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
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
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
    );
  }

  Widget _buildTransactionTile(dynamic t) {
    final isProcessing = _processing[t['id']] ?? false;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF5A403C))),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
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
          Wrap(
            spacing: 12,
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
