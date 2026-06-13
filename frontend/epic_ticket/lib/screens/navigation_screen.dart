import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  // Koordinat venue: Jl. Slamet Riyadi No.168, Baratan, Patrang, Jember
  final LatLng _venueLocation = const LatLng(-8.16340, 113.71672);
  final String _venueAddress =
      'Jl. Slamet Riyadi No.168, RT.02/RW.10, Baratan Wetan, Baratan, Kec. Patrang, Kabupaten Jember, Jawa Timur 68112';

  LatLng? _userLocation;
  bool _loadingLocation = true;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _loadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _loadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _loadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _loadingLocation = false;
      });
    } catch (e) {
      setState(() => _loadingLocation = false);
    }
  }

  void _openInGoogleMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${_venueLocation.latitude},${_venueLocation.longitude}',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tidak dapat membuka Google Maps'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _centerOnVenue() {
    _mapController.move(_venueLocation, 16.0);
  }

  void _centerOnUser() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 16.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Navigasi ke Venue'),
        backgroundColor: const Color(0xFF1E2020),
        foregroundColor: const Color(0xFFFFB4A8),
      ),
      body: Column(
        children: [
          // Peta
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _venueLocation,
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.epic.ticket',
                    ),
                    MarkerLayer(
                      markers: [
                        // Marker venue
                        Marker(
                          point: _venueLocation,
                          width: 50,
                          height: 50,
                          child: const Column(
                            children: [
                              Icon(Icons.location_on,
                                  color: Color(0xFFC00000), size: 36),
                            ],
                          ),
                        ),
                        // Marker user
                        if (_userLocation != null)
                          Marker(
                            point: _userLocation!,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(Icons.my_location,
                                    color: Colors.blue, size: 24),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                // Tombol kontrol peta
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Column(
                    children: [
                      // Tombol ke lokasi venue
                      FloatingActionButton.small(
                        heroTag: 'venue',
                        onPressed: _centerOnVenue,
                        backgroundColor: const Color(0xFF8B0000),
                        child: const Icon(Icons.location_on,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(height: 8),
                      // Tombol ke lokasi user
                      FloatingActionButton.small(
                        heroTag: 'user',
                        onPressed: _centerOnUser,
                        backgroundColor: Colors.blue,
                        child: const Icon(Icons.my_location,
                            color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
                // Loading indicator
                if (_loadingLocation)
                  const Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Card(
                        color: Color(0xFF1E2020),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFFFB4A8)),
                              ),
                              SizedBox(width: 8),
                              Text('Mencari lokasi Anda...',
                                  style:
                                      TextStyle(color: Color(0xFFE3BEB8))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Info venue
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E2020),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on,
                          color: Color(0xFFFFB4A8), size: 20),
                      SizedBox(width: 8),
                      Text('Lokasi Venue',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _venueAddress,
                    style: const TextStyle(
                        color: Color(0xFFE3BEB8), fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openInGoogleMaps,
                      icon:
                          const Icon(Icons.directions, color: Colors.white),
                      label: const Text('Buka Rute di Google Maps',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B0000),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
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
}
