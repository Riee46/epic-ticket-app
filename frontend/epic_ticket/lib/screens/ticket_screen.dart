import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/ticket_model.dart';

class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final Map<int, bool> _loadingCheckout = {};

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  String _formatRupiah(int price) {
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }

  Future<void> _handleCheckout(int ticketId) async {
    setState(() => _loadingCheckout[ticketId] = true);
    final resultMessage = await _apiService.checkoutTicket(ticketId, 1);
    setState(() => _loadingCheckout[ticketId] = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultMessage),
          backgroundColor:
              resultMessage.startsWith('✅') ? Colors.green : Colors.red,
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Tiket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => Navigator.pushNamed(context, '/my-tickets'),
            tooltip: 'Tiket Saya',
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => Navigator.pushNamed(context, '/navigation'),
            tooltip: 'Navigasi',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: FutureBuilder<List<TicketModel>>(
        future: _apiService.fetchTickets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada tiket tersedia'));
          }

          final tickets = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                final isLoading = _loadingCheckout[ticket.id] ?? false;
                final isSoldOut = ticket.quota <= 0;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ticket.category,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSoldOut
                                    ? Colors.red.shade800
                                    : const Color(0xFFC00000).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isSoldOut ? 'Habis' : 'Sisa: ${ticket.quota}',
                                style: TextStyle(
                                    color: isSoldOut
                                        ? Colors.white
                                        : const Color(0xFFC00000)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _formatRupiah(ticket.price),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFC00000)),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (isSoldOut || isLoading)
                                ? null
                                : () => _handleCheckout(ticket.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSoldOut
                                  ? Colors.grey
                                  : const Color(0xFFC00000),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Text(isSoldOut ? 'Habis' : 'Beli 1 Tiket'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
