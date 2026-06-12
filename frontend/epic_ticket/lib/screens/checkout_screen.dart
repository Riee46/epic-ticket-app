import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';

class CheckoutScreen extends StatefulWidget {
  final int ticketId;
  final int quantity;
  final int totalPrice;
  final String ticketCategory;

  const CheckoutScreen({
    super.key,
    required this.ticketId,
    required this.quantity,
    required this.totalPrice,
    required this.ticketCategory,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final ApiService _apiService = ApiService();
  File? _proofImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _proofImage = File(picked.path));
    }
  }

  Future<void> _submitCheckout() async {
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap upload bukti transfer')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Lakukan checkout (POST /checkout)
      final result =
          await _apiService.checkoutTicket(widget.ticketId, widget.quantity);
      // 2. Di sini Anda bisa upload bukti ke endpoint /upload-payment jika sudah ada
      // Untuk sementara, kita hanya menampilkan pesan sukses.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result), backgroundColor: Colors.green),
        );
        // Kembali ke halaman event detail
        Navigator.popUntil(context, ModalRoute.withName('/tickets'));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: const Color(0xFFC00000),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Ringkasan pesanan
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2020),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF5A403C)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ringkasan Pesanan',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const Divider(color: Color(0xFF5A403C), height: 24),
                  _buildRow('Event', 'EPIC 2K26'),
                  _buildRow('Kategori', widget.ticketCategory),
                  _buildRow('Jumlah', '${widget.quantity} tiket'),
                  _buildRow('Harga', 'Rp ${widget.totalPrice}'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Total',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      Text('Rp 150.000',
                          style: TextStyle(
                              color: Color(0xFFFFB4A8),
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            // Metode pembayaran
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2020),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF5A403C)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Metode Pembayaran',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0x338B0000),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF8B0000)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Transfer Manual',
                            style: TextStyle(
                                color: Color(0xFFFFB4A8),
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        const Text('Transfer ke rekening berikut :',
                            style: TextStyle(
                                color: Color(0xFFE3BEB8), fontSize: 16)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF333535),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF5A403C)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Bank BCA',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700)),
                                  Text('1234567890',
                                      style: TextStyle(
                                          color: Color(0xFFFFB4A8),
                                          fontSize: 16)),
                                  Text('a.n EPIC Ticket Indonesia',
                                      style: TextStyle(
                                          color: Color(0xFFE3BEB8),
                                          fontSize: 16)),
                                ],
                              ),
                              const Icon(Icons.copy, color: Color(0xFFFFB4A8)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Upload bukti transfer
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2020),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF5A403C)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Upload Bukti Transfer',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 46),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFF5A403C), width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                              _proofImage == null
                                  ? Icons.cloud_upload
                                  : Icons.check_circle,
                              size: 48,
                              color: const Color(0xFFFFB4A8)),
                          const SizedBox(height: 8),
                          Text(
                            _proofImage == null
                                ? 'Ketuk untuk pilih foto'
                                : 'Bukti terpilih',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
                          const Text('JPG, PNG, OR PDF',
                              style: TextStyle(
                                  color: Color(0xFFE3BEB8), fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B0000),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Kirim Bukti Pembayaran',
                          style: TextStyle(
                              color: Color(0xFFFF907F), fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xFFE3BEB8), fontSize: 16)),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}
