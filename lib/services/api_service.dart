// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:math';

class ApiService {
  // Base URL dari Free Food Menus API (stabil dan menyediakan harga/rating)
  final String _baseUrl = 'https://free-food-menus-api-two.vercel.app';

  // Fungsi utilitas untuk mengambil data, memprosesnya, dan mengonversi harga/rating
  Future<List<Map<String, dynamic>>> _fetchAndProcessMenu(
    String endpoint,
    String type,
    String defaultDesc,
  ) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$endpoint'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        return data.map((item) {
          // Ambil harga dan rating dari API. Gagal ambil, beri harga/rating default.
          double price = (item['price'] is num)
              ? (item['price'] as num).toDouble()
              : 2.5;
          double rating = (item['rate'] is num)
              ? (item['rate'] as num).toDouble()
              : 4.0;

          // Harga API ini dalam USD/simulasi. Dikalikan 15000 untuk simulasi IDR yang realistis
          double basePriceIdr = price * 15000.0;

          return {
            "idMeal":
                item['id']?.toString() ??
                item['name'].toString().replaceAll(' ', ''),
            "strMeal": item['name'] as String,
            // Mapping field 'img' ke 'strMealThumb'
            "strMealThumb": item['img'] as String,
            "type": type,
            // Harga dasar (IDR simulasi) yang akan dikonversi di home_page
            "price": basePriceIdr.toDouble(),
            // Rating diambil langsung dari API
            "rate": rating,
            // Mapping field 'dsc' ke 'description'
            "description": item['dsc'] as String? ?? defaultDesc,
          };
        }).toList();
      } else {
        debugPrint('Gagal memuat $type dari API: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Kesalahan koneksi saat memuat $type: $e');
      return [];
    }
  }

  @override
  Future<List<dynamic>> fetchMenu() async {
    List<dynamic> allMenu = [];

    // 1. Ambil Menu Minuman Kafe (Endpoint: /drinks)
    final drinksMenu = await _fetchAndProcessMenu(
      'drinks',
      'Minuman',
      'Minuman kafe yang menyegarkan.',
    );
    allMenu.addAll(drinksMenu);

    // 2. Ambil Menu Makanan Pendamping (Endpoint: /pizza)
    final pizzaMenu = await _fetchAndProcessMenu(
      'pizza',
      'Makanan',
      'Makanan pendamping kafe yang lezat.',
    );
    allMenu.addAll(pizzaMenu);

    // 3. Ambil Menu Makanan Utama (Endpoint: /burgers)
    final burgerMenu = await _fetchAndProcessMenu(
      'burgers',
      'Makanan',
      'Menu burger dan makanan berat lainnya.',
    );
    allMenu.addAll(burgerMenu);

    if (allMenu.isEmpty) {
      // Fallback data minimal jika API gagal
      return [
        {
          "idMeal": "F001",
          "strMeal": "Fallback Coffee",
          "strMealThumb": "https://via.placeholder.com/150",
          "type": "Minuman",
          "price": 25000.0,
          "rate": 4.5,
          "description": "Menu fallback karena API down.",
        },
      ];
    }

    return allMenu;
  }
}
