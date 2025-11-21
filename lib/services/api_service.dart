import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:math';

class ApiService {
  // Base URL dari Free Food Menus API
  // API ini menyediakan harga dan gambar langsung.
  final String _baseUrl = 'https://free-food-menus-api-two.vercel.app';

  // Fungsi utilitas untuk mengambil data, memprosesnya, dan mengonversi harga
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
          // Ambil harga dari API. Gagal ambil, beri harga default 25.0
          double price = (item['price'] is num)
              ? (item['price'] as num).toDouble()
              : 25.0;

          // Harga API ini dalam USD/simulasi. Dikalikan 15000 untuk simulasi IDR yang realistis
          double adjustedPrice = price * 15000.0;

          return {
            "idMeal":
                item['id']?.toString() ??
                item['name'].toString().replaceAll(' ', ''),
            "strMeal": item['name'] as String,
            // Mapping field 'img' ke 'strMealThumb'
            "strMealThumb": item['img'] as String,
            "type": type,
            // Harga diambil dari API dan disesuaikan ke IDR
            "price": adjustedPrice.toDouble(),
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

    // 1. Ambil Menu Minuman Kafe (Endpoint: /drinks) -> Kategori: Minuman
    final drinksMenu = await _fetchAndProcessMenu(
      'drinks',
      'Minuman',
      'Minuman kafe yang menyegarkan.',
    );
    allMenu.addAll(drinksMenu);

    // 2. Ambil Menu Makanan Pendamping (Endpoint: /pizza) -> Kategori: Makanan
    final pizzaMenu = await _fetchAndProcessMenu(
      'pizza',
      'Makanan',
      'Makanan pendamping kafe yang lezat.',
    );
    allMenu.addAll(pizzaMenu);

    // 3. Ambil Menu Makanan Utama (Endpoint: /burgers) -> Kategori: Makanan
    final burgerMenu = await _fetchAndProcessMenu(
      'burgers',
      'Makanan',
      'Menu burger dan makanan berat lainnya.',
    );
    allMenu.addAll(burgerMenu);

    // **SEMUA DATA LOKAL/STATIS DIHAPUS TOTAL SESUAI PERMINTAAN**

    if (allMenu.isEmpty) {
      // Jika semua API gagal, lempar exception.
      throw Exception('Gagal memuat menu dari semua sumber eksternal.');
    }

    return allMenu;
  }
}
