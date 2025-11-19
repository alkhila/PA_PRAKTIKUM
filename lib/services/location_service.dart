import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class LocationService {
  static const String _nominatimBaseUrl =
      'https://nominatim.openstreetmap.org/reverse';

  static const Map<String, String> _headers = {
    'User-Agent': 'FastFoodApp/1.0 (contact@pa-restoran.com)',
  };

  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Layanan lokasi tidak diaktifkan.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Izin lokasi ditolak permanen. Mohon aktifkan di pengaturan.',
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<Map<String, String>> getCountryCode(
    double latitude,
    double longitude,
  ) async {
    try {
      final url = Uri.parse(
        '$_nominatimBaseUrl?lat=$latitude&lon=$longitude&format=jsonv2',
      );

      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data != null &&
            data['address'] != null &&
            data['address']['country_code'] != null) {
          final countryCode = data['address']['country_code']
              .toString()
              .toUpperCase();
          final countryName = data['address']['country'].toString();

          return {'code': countryCode, 'name': countryName};
        } else {
          return {'code': 'ID', 'name': 'Indonesia (Default)'};
        }
      } else {
        return {'code': 'ID', 'name': 'Indonesia (API Error)'};
      }
    } catch (e) {
      return {'code': 'ID', 'name': 'Indonesia (Koneksi Error)'};
    }
  }

  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final url = Uri.parse(
        '$_nominatimBaseUrl?lat=$latitude&lon=$longitude&format=jsonv2',
      );
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] as String;
      } else {
        return 'Gagal memuat alamat (Status: ${response.statusCode})';
      }
    } catch (e) {
      return 'Kesalahan koneksi saat melacak lokasi.';
    }
  }
}
