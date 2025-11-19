import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _baseUrl =
      'https://api.exchangerate-api.com/v4/latest/IDR';
  final Map<String, String> countryToCurrency = {
    'ID': 'IDR',
    'US': 'USD',
    'EU': 'EUR',
    'GB': 'GBP',
    'JP': 'JPY',
  };

  final List<String> supportedCurrencies = ['IDR', 'USD', 'EUR', 'JPY'];

  Future<Map<String, double>> getExchangeRates() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        Map<String, double> filteredRates = {};
        for (var code in supportedCurrencies) {
          if (rates.containsKey(code)) {
            filteredRates[code] = rates[code].toDouble();
          }
        }
        return filteredRates;
      } else {
        throw Exception('Gagal memuat rate mata uang: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kesalahan koneksi saat memuat rate: $e');
    }
  }

  String getDefaultCurrency(String countryCode) {
    return countryToCurrency[countryCode] ?? 'IDR';
  }
}
