import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  // Ganti dengan koordinat venue sebenarnya (Sevendream City)
  final double venueLat = -8.123456;
  final double venueLng = 113.678901;

  Future<void> _openNavigation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Aktifkan layanan lokasi'),
            backgroundColor: Colors.red),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Izin lokasi ditolak'),
              backgroundColor: Colors.red),
        );
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    final url = Uri.parse(
      'https://www.openstreetmap.org/directions?engine=fossgis_router&route=${position.latitude},${position.longitude}&to=$venueLat,$venueLng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tidak dapat membuka peta'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigasi ke Venue'),
        backgroundColor: const Color(0xFFC00000),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Arahkan ke Sevendream City',
                style: TextStyle(color: Colors.white)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openNavigation,
              icon: const Icon(Icons.map),
              label: const Text('Buka Peta & Navigasi'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC00000)),
            ),
          ],
        ),
      ),
    );
  }
}
