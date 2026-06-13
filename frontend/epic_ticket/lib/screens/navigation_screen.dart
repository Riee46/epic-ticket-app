import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  // Koordinat SEVENDREAM CITY yang benar
  final LatLng _venueLocation = const LatLng(-8.1565, 113.6934);
  final String _venueAddress =
      'SEVENDREAM CITY\nJl. Slamet Riyadi No.168, RT.02/RW.10, Baratan Wetan, Baratan, Kec. Patrang, Kabupaten Jember, Jawa Timur 68112';

  LatLng? _userLocation;
  List<LatLng> _routePoints = [];
  bool _loadingLocation = true;
  bool _loadingRoute = false;
  String? _locationError;
  String _distanceText = '';
  String _durationText = '';

  StreamSubscription<Position>? _positionStream;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _loadingLocation = false;
          _locationError = 'GPS tidak aktif. Aktifkan layanan lokasi Anda.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _loadingLocation = false;
            _locationError = 'Izin lokasi ditolak.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _loadingLocation = false;
          _locationError =
              'Izin lokasi ditolak permanen. Ubah di Pengaturan > Aplikasi.';
        });
        return;
      }

      // Ambil posisi awal
      final Position initialPos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (!mounted) return;
      setState(() {
        _userLocation = LatLng(initialPos.latitude, initialPos.longitude);
        _loadingLocation = false;
      });

      // Ambil rute dari OSRM
      await _fetchRoute(_userLocation!);

      // Zoom agar kedua titik terlihat
      _fitAll();

      // Mulai stream real-time update posisi
      _startPositionStream();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
          _locationError = 'Gagal mendapatkan lokasi: $e';
        });
      }
    }
  }

  void _startPositionStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // update setiap 10 meter pergerakan
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      if (!mounted) return;
      final newPos = LatLng(position.latitude, position.longitude);
      setState(() => _userLocation = newPos);

      // Geser kamera mengikuti user secara otomatis
      _mapController.move(newPos, _mapController.camera.zoom);

      // Update rute dari posisi baru
      await _fetchRoute(newPos);
    });
  }

  Future<void> _fetchRoute(LatLng from) async {
    setState(() => _loadingRoute = true);
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${from.longitude},${from.latitude};'
          '${_venueLocation.longitude},${_venueLocation.latitude}'
          '?overview=full&geometries=geojson&steps=false';

      debugPrint('[NAV] Fetching route from OSRM...');
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));

      debugPrint('[NAV] OSRM status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          final double distanceM =
              (data['routes'][0]['distance'] as num).toDouble();
          final double durationS =
              (data['routes'][0]['duration'] as num).toDouble();

          final List<LatLng> points = coords
              .map<LatLng>((c) => LatLng((c[1] as num).toDouble(),
                  (c[0] as num).toDouble()))
              .toList();

          debugPrint('[NAV] Route OK: ${points.length} points, ${distanceM}m');

          if (mounted) {
            setState(() {
              _routePoints = points;
              _distanceText = distanceM >= 1000
                  ? '${(distanceM / 1000).toStringAsFixed(1)} km'
                  : '${distanceM.toStringAsFixed(0)} m';
              _durationText = '${(durationS / 60).ceil()} menit';
              _loadingRoute = false;
            });
          }
          return; // sukses, keluar
        }
      }

      // OSRM gagal -> fallback garis lurus
      debugPrint('[NAV] OSRM failed, using fallback straight line');
      _useFallbackLine(from);
    } catch (e) {
      debugPrint('[NAV] Route error: $e');
      // Timeout atau error lain -> fallback garis lurus
      if (mounted) _useFallbackLine(from);
    }
  }

  void _useFallbackLine(LatLng from) {
    const distance = Distance();
    final km = distance.as(LengthUnit.Kilometer, from, _venueLocation);
    setState(() {
      _routePoints = [from, _venueLocation];
      _distanceText = km >= 1
          ? '${km.toStringAsFixed(1)} km'
          : '${(km * 1000).toStringAsFixed(0)} m';
      _durationText = '~${(km / 40 * 60).ceil()} menit';
      _loadingRoute = false;
    });
  }

  void _centerOnVenue() =>
      _mapController.move(_venueLocation, 16.0);

  void _centerOnUser() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 16.0);
    }
  }

  void _fitAll() {
    if (_userLocation != null) {
      final bounds =
          LatLngBounds.fromPoints([_userLocation!, _venueLocation]);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(72),
        ),
      );
    } else {
      _centerOnVenue();
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
        actions: [
          if (_loadingRoute)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFFFB4A8),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Banner info jarak + waktu
          if (_distanceText.isNotEmpty)
            Container(
              color: const Color(0xFF8B0000),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.route, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '$_distanceText  ·  $_durationText',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          // Peta
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _venueLocation,
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.epic.ticket',
                    ),
                    // Rute OSRM mengikuti jalan
                    if (_routePoints.isNotEmpty)
                      PolylineLayer<Object>(
                        polylines: [
                          // Shadow
                          Polyline(
                            points: _routePoints,
                            color: Colors.black.withValues(alpha: 0.3),
                            strokeWidth: 7.0,
                          ),
                          // Rute utama
                          Polyline(
                            points: _routePoints,
                            color: const Color(0xFFFF5252),
                            strokeWidth: 5.0,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        // Marker venue
                        Marker(
                          point: _venueLocation,
                          width: 130,
                          height: 80,
                          alignment: Alignment.topCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B0000),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: const Text(
                                  'SEVENDREAM CITY',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Icon(Icons.location_on,
                                  color: Color(0xFFC00000), size: 38),
                            ],
                          ),
                        ),
                        // Marker user (bergerak real-time)
                        if (_userLocation != null)
                          Marker(
                            point: _userLocation!,
                            width: 50,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.blue, width: 2.5),
                              ),
                              child: const Center(
                                child: Icon(Icons.navigation_rounded,
                                    color: Colors.blue, size: 26),
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
                      FloatingActionButton.small(
                        heroTag: 'fitAll',
                        onPressed: _fitAll,
                        backgroundColor: const Color(0xFF333333),
                        child: const Icon(Icons.zoom_out_map,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'venue',
                        onPressed: _centerOnVenue,
                        backgroundColor: const Color(0xFF8B0000),
                        child: const Icon(Icons.location_on,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(height: 8),
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
                // Loading awal
                if (_loadingLocation)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                              color: Color(0xFFFFB4A8)),
                          SizedBox(height: 16),
                          Text('Mencari lokasi Anda...',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                // Error banner
                if (_locationError != null && !_loadingLocation)
                  Positioned(
                    top: 8,
                    left: 12,
                    right: 12,
                    child: Card(
                      color: const Color(0xFF2A1A1A),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Color(0xFFFFB4A8), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_locationError!,
                                  style: const TextStyle(
                                      color: Color(0xFFE3BEB8),
                                      fontSize: 12)),
                            ),
                            TextButton(
                              onPressed: _initLocation,
                              child: const Text('Coba Lagi',
                                  style: TextStyle(
                                      color: Color(0xFFFFB4A8),
                                      fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Panel info venue
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E2020),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
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
                      Text(
                        'Lokasi Venue',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _venueAddress,
                    style: const TextStyle(
                        color: Color(0xFFE3BEB8),
                        fontSize: 13,
                        height: 1.4),
                  ),
                  if (_distanceText.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _infoChip(
                            Icons.straighten, _distanceText, Colors.blue),
                        const SizedBox(width: 8),
                        _infoChip(Icons.access_time, _durationText,
                            const Color(0xFFFF5252)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
