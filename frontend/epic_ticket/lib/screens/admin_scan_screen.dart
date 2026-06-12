import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';

class AdminScanScreen extends StatefulWidget {
  const AdminScanScreen({super.key});

  @override
  State<AdminScanScreen> createState() => _AdminScanScreenState();
}

class _AdminScanScreenState extends State<AdminScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final ApiService _apiService = ApiService();
  bool _isProcessing = false;
  String? _lastScanned;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scanner Panitia',
            style: TextStyle(color: Color(0xFFFFB4A8))),
        backgroundColor: const Color(0xFF121414),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.flip_camera_android, color: Color(0xFFFFB4A8)),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: MobileScanner(
              controller: _scannerController,
              onDetect: (capture) async {
                final barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && !_isProcessing) {
                  final code = barcodes.first.rawValue;
                  if (code != null && code != _lastScanned) {
                    _lastScanned = code;
                    setState(() => _isProcessing = true);
                    try {
                      final message = await _apiService.scanTicket(code);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(message),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2)),
                        );
                        await Future.delayed(const Duration(seconds: 1));
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      setState(() => _isProcessing = false);
                      _lastScanned = null;
                    }
                  }
                }
              },
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Arahkan kamera ke QR Code tiket',
                    style: TextStyle(color: Color(0xFFE3BEB8), fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _scannerController.toggleTorch(),
                    icon: const Icon(Icons.flash_on),
                    label: const Text('Nyalakan Lampu'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B0000)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }
}
