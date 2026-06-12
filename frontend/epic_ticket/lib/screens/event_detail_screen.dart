import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/ticket_model.dart';
import 'checkout_screen.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<TicketModel>> _ticketsFuture;
  int _selectedTicketId = 1;
  int _quantity = 1;
  String _selectedCategory = 'Regular';

  @override
  void initState() {
    super.initState();
    _ticketsFuture = _apiService.fetchTickets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Detail Event'),
        backgroundColor: const Color(0xFFC00000),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => Navigator.pushNamed(context, '/my-tickets'),
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => Navigator.pushNamed(context, '/navigation'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService().logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: FutureBuilder<List<TicketModel>>(
        future: _ticketsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tiket tidak tersedia'));
          }

          final tickets = snapshot.data!;
          final selectedTicket = tickets.firstWhere(
            (t) => t.id == _selectedTicketId,
            orElse: () => tickets.first,
          );

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner image (placeholder)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: NetworkImage('https://placehold.co/348x195'),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EPIC 2K26',
                        style: TextStyle(
                          color: Color(0xFFFFB4A8),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Dari The Cloves & The Tobacco, dengan fasilitas lengkap, sound system berkualitas tinggi, dan pengalaman tak terlupakan.',
                        style:
                            TextStyle(color: Color(0xFFE3BEB8), fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Pilih Kategori Tiket',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      ...tickets.map((ticket) => _buildTicketCard(
                          ticket, ticket.id == _selectedTicketId)),
                      const SizedBox(height: 24),
                      const Text(
                        'Jumlah Tiket',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_quantity > 1) setState(() => _quantity--);
                              },
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Color(0xFFFFB4A8)),
                            ),
                            Container(
                              width: 48,
                              alignment: Alignment.center,
                              child: Text(
                                '$_quantity',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _quantity++),
                              icon: const Icon(Icons.add_circle_outline,
                                  color: Color(0xFFFFB4A8)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Info pembayaran transfer manual
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2020),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF5A403C)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0x19FFB4A8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.payment,
                                  color: Color(0xFFFFB4A8)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Pembayaran Transfer Manual',
                                    style: TextStyle(
                                        color: Color(0xFFFFB4A8),
                                        fontWeight: FontWeight.w500),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Setelah checkout, upload bukti transfer untuk verifikasi',
                                    style: TextStyle(
                                        color: Color(0xFFE3BEB8), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Total dan tombol checkout
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                          Text(
                            'Rp ${selectedTicket.price * _quantity}',
                            style: const TextStyle(
                              color: Color(0xFFFFB4A8),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CheckoutScreen(
                                  ticketId: _selectedTicketId,
                                  quantity: _quantity,
                                  totalPrice: selectedTicket.price * _quantity,
                                  ticketCategory: _selectedCategory,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B0000),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Lanjut ke Checkout',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(TicketModel ticket, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTicketId = ticket.id;
          _selectedCategory = ticket.category;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x338B0000) : const Color(0xFF1A1C1C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF8B0000) : const Color(0xFF5A403C),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.category,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ticket.quota} Tersisa',
                  style:
                      const TextStyle(color: Color(0xFFE3BEB8), fontSize: 12),
                ),
              ],
            ),
            Text(
              'Rp ${ticket.price}',
              style: const TextStyle(
                  color: Color(0xFFFFB4A8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
