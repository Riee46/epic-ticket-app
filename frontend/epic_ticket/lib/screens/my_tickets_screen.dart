import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _qrCodes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchQRCodes();
  }

  Future<void> _fetchQRCodes() async {
    setState(() => _loading = true);
    try {
      final qrs = await _apiService.getMyQRCodes();
      setState(() => _qrCodes = qrs);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tiket Saya')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _qrCodes.isEmpty
              ? const Center(child: Text('Belum ada tiket terverifikasi'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _qrCodes.length,
                  itemBuilder: (context, index) {
                    final qr = _qrCodes[index];
                    final ticketCode = qr['ticket_code'];
                    final isUsed = qr['used'];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text('Kode: $ticketCode',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            QrImageView(
                                data: ticketCode,
                                version: QrVersions.auto,
                                size: 200),
                            const SizedBox(height: 8),
                            Text(
                              isUsed ? 'Sudah digunakan' : 'Belum digunakan',
                              style: TextStyle(
                                  color: isUsed ? Colors.red : Colors.green),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
