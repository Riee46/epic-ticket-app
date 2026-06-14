import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/ticket_model.dart';

class AdminEventSettingsScreen extends StatefulWidget {
  const AdminEventSettingsScreen({super.key});

  @override
  State<AdminEventSettingsScreen> createState() => _AdminEventSettingsScreenState();
}

class _AdminEventSettingsScreenState extends State<AdminEventSettingsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<TicketModel>> _ticketsFuture;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  void _loadTickets() {
    setState(() {
      _ticketsFuture = _apiService.fetchTickets();
    });
  }

  Future<void> _showEditPriceDialog(TicketModel ticket) async {
    final TextEditingController _priceController =
        TextEditingController(text: ticket.price.toString());
    
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2020),
          title: const Text('Edit Harga / Diskon', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Kategori: ${ticket.category}', style: const TextStyle(color: Color(0xFFE3BEB8))),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Harga Baru (Rp)',
                  labelStyle: TextStyle(color: Color(0xFFE3BEB8)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF5A403C)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFFB4A8)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Color(0xFFE3BEB8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B0000)),
              onPressed: () async {
                final newPrice = int.tryParse(_priceController.text);
                if (newPrice != null) {
                  Navigator.pop(context);
                  await _updatePrice(ticket.id, newPrice);
                }
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updatePrice(int ticketId, int newPrice) async {
    try {
      final message = await _apiService.updateTicketPrice(ticketId, newPrice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
        _loadTickets();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Event Settings'),
        backgroundColor: const Color(0xFF121414),
        foregroundColor: const Color(0xFFFFB4A8),
      ),
      body: FutureBuilder<List<TicketModel>>(
        future: _ticketsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada data tiket', style: TextStyle(color: Colors.white)));
          }

          final tickets = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return Card(
                color: const Color(0xFF1E2020),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Color(0xFF5A403C)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(ticket.category, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('Rp ${ticket.price} | Kuota: ${ticket.quota}', style: const TextStyle(color: Color(0xFFE3BEB8))),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFFFFB4A8)),
                    onPressed: () => _showEditPriceDialog(ticket),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
