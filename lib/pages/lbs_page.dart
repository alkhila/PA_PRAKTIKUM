import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const Color brownColor = Color(0xFF4E342E);
const Color accentColor = Color(0xFFFFB300);

final List<Map<String, dynamic>> branches = [
  {'name': 'Cabang UPN (Pusat)', 'lat': -7.760166, 'lon': 110.407981},
  {'name': 'Cabang Malioboro', 'lat': -7.791550, 'lon': 110.366479},
  {'name': 'Cabang Jakal KM 5', 'lat': -7.765636, 'lon': 110.384661},
];

class LBSPage extends StatefulWidget {
  const LBSPage({super.key});

  @override
  State<LBSPage> createState() => _LBSPageState();
}

class _LBSPageState extends State<LBSPage> {
  LatLng _userLocation = const LatLng(-7.78, 110.37);
  bool _isLoading = true;
  String _status = 'Mencari lokasi Anda...';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
        _status = 'Lokasi ditemukan.';
      });
    } catch (e) {
      setState(() {
        _status = 'Gagal mendapatkan lokasi: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String findNearestBranch() {
    if (_isLoading) return 'Menunggu lokasi...';

    double minDistance = double.infinity;
    String nearestBranchName = 'N/A';

    for (var branch in branches) {
      double distance = Geolocator.distanceBetween(
        _userLocation.latitude,
        _userLocation.longitude,
        branch['lat'] as double,
        branch['lon'] as double,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestBranchName =
            '${branch['name']} (${(minDistance / 1000).toStringAsFixed(2)} km)';
      }
    }

    return nearestBranchName;
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];
    for (var branch in branches) {
      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(branch['lat'] as double, branch['lon'] as double),
          child: Column(
            children: [
              Icon(Icons.store, color: brownColor, size: 30),
              Text(
                branch['name'] as String,
                style: TextStyle(
                  fontSize: 10,
                  color: brownColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    markers.add(
      Marker(
        width: 80.0,
        height: 80.0,
        point: _userLocation,
        child: Icon(
          Icons.person_pin_circle,
          color: Color(0xFF703B3B),
          size: 40,
        ),
      ),
    );

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: brownColor,
                  ),
                ),
                Text(
                  _status,
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
                const SizedBox(height: 10),
                Text(
                  'Cabang Terdekat:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: brownColor,
                  ),
                ),
                Text(
                  findNearestBranch(),
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFF703B3B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: accentColor))
                : FlutterMap(
                    options: MapOptions(
                      initialCenter: _userLocation,
                      initialZoom: 13.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        userAgentPackageName: 'com.example.pa_restoran2',
                      ),
                      MarkerLayer(markers: _buildMarkers()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
