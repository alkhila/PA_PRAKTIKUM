import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../models/cart_item_model.dart';
import '../models/purchase_history_model.dart';
import '../services/currency_service.dart';
import '../services/location_service.dart';

const Color brownColor = Color(0xFF4E342E);
const Color accentColor = Color(0xFFFFB300);
const Color darkPrimaryColor = Color(0xFF703B3B);
const Color secondaryAccentColor = Color(0xFFA18D6D);
const Color lightBackgroundColor = Color(0xFFE1D0B3);

class ReceiptPage extends StatefulWidget {
  final bool isFromCheckout;

  const ReceiptPage({super.key, this.isFromCheckout = false});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  String _currentUserEmail = '';
  bool _showSuccessMessage = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();

    if (widget.isFromCheckout) {
      _showSuccessMessage = true;
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showSuccessMessage = false;
          });
        }
      });
    }
  }

  Future<void> _loadCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserEmail = prefs.getString('current_user_email') ?? '';
    });
  }

  void _backToHome(BuildContext context) async {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserEmail.isEmpty) {
      return Scaffold(
        backgroundColor: lightBackgroundColor,
        appBar: AppBar(
          title: const Text('Riwayat Pembelian'),
          backgroundColor: darkPrimaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator(color: darkPrimaryColor)),
      );
    }

    if (_showSuccessMessage) {
      return Scaffold(
        backgroundColor: lightBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 80),
              ),
              const SizedBox(height: 30),
              Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: darkPrimaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Pesanan Anda berhasil dibuat dan dibayar.',
                style: TextStyle(fontSize: 18, color: darkPrimaryColor),
              ),
              const SizedBox(height: 5),
              Text(
                'Silakan ambil pesanan Anda di cabang terdekat\ndengan menunjukkan riwayat pembelian ini.', // NEW PICKUP INSTRUCTION
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryAccentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Anda akan diarahkan ke riwayat pembelian...',
                style: TextStyle(fontSize: 14, color: secondaryAccentColor),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: lightBackgroundColor,
      appBar: AppBar(
        title: const Text('Riwayat Pembelian'),
        backgroundColor: darkPrimaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<PurchaseHistoryModel>(
          'historyBox',
        ).listenable(),
        builder: (context, Box<PurchaseHistoryModel> box, _) {
          final history = box.values
              .where((record) => record.userEmail == _currentUserEmail)
              .toList()
              .reversed
              .toList();

          if (history.isEmpty) {
            return Center(
              child: Text(
                'Belum ada riwayat pembelian.',
                style: TextStyle(color: darkPrimaryColor),
              ),
            );
          }

          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final record = history[index];
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Waktu Pembelian',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: secondaryAccentColor,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'dd MMM yyyy, HH:mm:ss',
                        ).format(record.purchaseTime),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkPrimaryColor,
                          fontSize: 16,
                        ),
                      ),
                      const Divider(height: 20),
                      Text(
                        'Total Bayar (${record.currency})',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: secondaryAccentColor,
                        ),
                      ),
                      Text(
                        '${record.currency} ${record.finalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: darkPrimaryColor,
                        ),
                      ),
                      const Divider(height: 20),
                      Text(
                        'Detail Item:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: darkPrimaryColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      ...record.items
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                '${item.strMeal} (${item.quantity}x) - Rp ${(item.price * item.quantity).toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _backToHome(context),
        label: const Text(
          'Kembali ke Home',
          style: TextStyle(color: Colors.white),
        ),
        icon: const Icon(Icons.home, color: Colors.white),
        backgroundColor: darkPrimaryColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class CheckoutDetailPage extends StatefulWidget {
  final double totalPrice;
  final List<CartItemModel> items;

  const CheckoutDetailPage({
    super.key,
    required this.totalPrice,
    required this.items,
  });

  @override
  State<CheckoutDetailPage> createState() => _CheckoutDetailPageState();
}

class _CheckoutDetailPageState extends State<CheckoutDetailPage> {
  final CurrencyService _currencyService = CurrencyService();
  final LocationService _locationService = LocationService();

  late Future<Map<String, double>> _ratesFuture;
  bool _isLocating = true;
  String _targetCurrency = 'IDR';
  double _convertedAmount = 0.0;
  String _locationStatus = 'Menentukan mata uang default...';
  String _currentUserEmail = '';

  @override
  void initState() {
    super.initState();
    _ratesFuture = _currencyService.getExchangeRates();
    _convertedAmount = widget.totalPrice;
    _loadCurrentUserEmailAndDetermineCurrency();
  }

  Future<void> _loadCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserEmail = prefs.getString('current_user_email') ?? '';
  }

  void _loadCurrentUserEmailAndDetermineCurrency() async {
    await _loadCurrentUserEmail();
    _determineDefaultCurrency();
  }

  void _determineDefaultCurrency() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final locationData = await _locationService.getCountryCode(
        position.latitude,
        position.longitude,
      );

      final countryCode = locationData['code']!;
      final countryName = locationData['name']!;

      final defaultCurrency = _currencyService.getDefaultCurrency(countryCode);

      setState(() {
        _isLocating = false;
        _targetCurrency = defaultCurrency;
        _locationStatus = 'Default Mata Uang: $defaultCurrency ($countryName).';

        _ratesFuture.then((rates) {
          _convertCurrency(rates);
        });
      });
    } catch (e) {
      setState(() {
        _isLocating = false;
        _targetCurrency = 'IDR';
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        _locationStatus = 'Gagal melacak lokasi. Default: IDR. ($errorMsg)';

        _ratesFuture.then((rates) {
          _convertCurrency(rates);
        });
      });
    }
  }

  void _convertCurrency(Map<String, double> rates) {
    if (rates.containsKey(_targetCurrency)) {
      final double targetRate = rates[_targetCurrency]!;

      setState(() {
        _convertedAmount = widget.totalPrice * targetRate;
      });
    }
  }

  void _handlePayment() async {
    if (_currentUserEmail.isEmpty) {
      return;
    }

    final historyBox = Hive.box<PurchaseHistoryModel>('historyBox');

    final newRecord = PurchaseHistoryModel(
      finalPrice: _convertedAmount,
      currency: _targetCurrency,
      purchaseTime: DateTime.now(),
      items: widget.items.toList(),
      userEmail: _currentUserEmail,
    );
    await historyBox.add(newRecord);

    final cartBox = Hive.box<CartItemModel>('cartBox');
    final keysToDelete = cartBox.keys
        .where((key) => cartBox.get(key)?.userEmail == _currentUserEmail)
        .toList();

    await cartBox.deleteAll(keysToDelete);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const ReceiptPage(isFromCheckout: true),
      ),
    );
  }

  Widget _buildPriceRow(String title, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? darkPrimaryColor : Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? darkPrimaryColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackgroundColor,
      appBar: AppBar(
        title: const Text('Konfirmasi Pembelian'),
        backgroundColor: darkPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, double>>(
        future: _ratesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isLocating) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: darkPrimaryColor),
                  const SizedBox(height: 10),
                  Text(
                    _locationStatus,
                    style: TextStyle(color: darkPrimaryColor),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Gagal memuat rate mata uang: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (snapshot.hasData) {
            final rates = snapshot.data!;
            final currencyList = rates.keys.toList();

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ringkasan Pesanan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: darkPrimaryColor,
                          ),
                        ),
                        const Divider(color: secondaryAccentColor),
                        Container(
                          color: Color(0xFFE1D0B3),
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            children: widget.items
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${item.strMeal} (${item.quantity}x)',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Rp ${(item.price * item.quantity).toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          'Status Konversi: $_locationStatus',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryAccentColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(
                    left: 20.0,
                    right: 20.0,
                    bottom: 10.0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: secondaryAccentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: secondaryAccentColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.store, color: darkPrimaryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Silakan ambil produk di cabang terdekat setelah pembayaran berhasil.',
                            style: TextStyle(
                              fontSize: 14,
                              color: darkPrimaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Container(
                  color: lightBackgroundColor,
                  padding: const EdgeInsets.only(
                    top: 10.0,
                    left: 20.0,
                    right: 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPriceRow(
                        'Subtotal Harga (IDR)',
                        'Rp ${widget.totalPrice.toStringAsFixed(0)}',
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mata Uang Target:',
                            style: TextStyle(
                              fontSize: 16,
                              color: darkPrimaryColor,
                            ),
                          ),
                          DropdownButton<String>(
                            value: _targetCurrency,
                            style: TextStyle(
                              color: darkPrimaryColor,
                              fontSize: 16,
                            ),
                            dropdownColor: lightBackgroundColor,
                            iconEnabledColor: darkPrimaryColor,
                            items: currencyList.map((String currency) {
                              return DropdownMenuItem<String>(
                                value: currency,
                                child: Text(
                                  currency,
                                  style: TextStyle(color: darkPrimaryColor),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _targetCurrency = newValue;
                                  _convertCurrency(rates);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: darkPrimaryColor),

                      _buildPriceRow(
                        'Total Pembayaran',
                        '$_targetCurrency ${_convertedAmount.toStringAsFixed(2)}',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton.icon(
                    onPressed: _handlePayment,
                    icon: const Icon(Icons.payment, color: Colors.white),
                    label: const Text(
                      'Bayar Sekarang (Simulasi)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkPrimaryColor,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
