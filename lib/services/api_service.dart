import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:math';

class ApiService {
  final String _baseUrl = 'https://free-food-menus-api-two.vercel.app';

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
          double price = (item['price'] is num)
              ? (item['price'] as num).toDouble()
              : 2.5;
          double rating = (item['rate'] is num)
              ? (item['rate'] as num).toDouble()
              : 4.0;

          double basePriceIdr = price * 15000.0;

          return {
            "idMeal":
                item['id']?.toString() ??
                item['name'].toString().replaceAll(' ', ''),
            "strMeal": item['name'] as String,
            "strMealThumb": item['img'] as String,
            "type": type,
            "price": basePriceIdr.toDouble(),
            "rate": rating,
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

    final drinksMenu = await _fetchAndProcessMenu(
      'drinks',
      'Minuman',
      'Minuman kafe yang menyegarkan.',
    );
    allMenu.addAll(drinksMenu);

    final pizzaMenu = await _fetchAndProcessMenu(
      'pizza',
      'Makanan',
      'Makanan pendamping kafe yang lezat.',
    );
    allMenu.addAll(pizzaMenu);

    final burgerMenu = await _fetchAndProcessMenu(
      'burgers',
      'Makanan',
      'Menu burger dan makanan berat lainnya.',
    );
    allMenu.addAll(burgerMenu);

    if (allMenu.isEmpty) {
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
