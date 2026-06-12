import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/ticket_model.dart';

class ApiService {
  final String baseUrl = AppConfig.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } else {
      return {'Content-Type': 'application/json'};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // ========== USER ENDPOINTS ==========
  Future<List<TicketModel>> fetchTickets() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/tickets'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'success') {
        List<dynamic> data = jsonResponse['data'];
        return data.map((item) => TicketModel.fromJson(item)).toList();
      } else {
        throw Exception('Gagal memuat data tiket');
      }
    } else {
      throw Exception('Gagal terhubung ke server (${response.statusCode})');
    }
  }

  Future<String> checkoutTicket(int ticketId, int quantity) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/checkout'),
      headers: headers,
      body: json.encode({'ticket_id': ticketId, 'quantity': quantity}),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'success') {
        String message = jsonResponse['message'];
        String? transId = jsonResponse['data']?['id_transaksi'];
        int? totalPrice = jsonResponse['data']?['total_price'];
        String totalFormatted =
            totalPrice != null ? _formatRupiah(totalPrice) : '';
        return '✅ $message (ID: $transId) - Total: $totalFormatted';
      } else {
        return '❌ Gagal: ${jsonResponse['message'] ?? 'Terjadi kesalahan'}';
      }
    } else if (response.statusCode == 400 || response.statusCode == 404) {
      try {
        final Map<String, dynamic> errorResponse = json.decode(response.body);
        if (errorResponse.containsKey('detail')) {
          final detail = errorResponse['detail'];
          String errorMessage = detail['message'] ?? detail.toString();
          return '❌ Gagal: $errorMessage';
        } else {
          return '❌ Gagal: ${errorResponse['message'] ?? 'Request error'}';
        }
      } catch (e) {
        return '❌ Gagal: Server error (${response.statusCode})';
      }
    } else {
      return '❌ Gagal: Koneksi error (${response.statusCode})';
    }
  }

  Future<List<dynamic>> getMyQRCodes() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/user/tickets/qr'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal mengambil QR code: ${response.statusCode}');
    }
  }

  String _formatRupiah(int price) {
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }

  // ========== ADMIN ENDPOINTS ==========
  Future<List<dynamic>> getPendingTransactions() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/transactions/pending'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal mengambil transaksi pending');
    }
  }

  Future<String> verifyPayment(int transactionId, String action) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/verify-payment'),
      headers: headers,
      body: json.encode({'transaction_id': transactionId, 'action': action}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['message'] ?? 'Success';
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Verification failed');
    }
  }

  Future<String> scanTicket(String ticketCode) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/scan'),
      headers: headers,
      body: json.encode({'ticket_code': ticketCode}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return '✅ Tiket valid! Pengguna: ${data['user_id']}';
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Invalid ticket');
    }
  }
}
