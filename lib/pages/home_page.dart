import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'time_converter_page.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'cart_page.dart';
import 'lbs_page.dart';
import 'detail_page.dart';
import 'login_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'checkout_detail_page.dart';
import 'application_comment_page.dart';
import '../services/currency_service.dart'; // Import CurrencyService

const Color darkPrimaryColor = Color(0xFF703B3B);
const Color secondaryAccentColor = Color(0xFFA18D6D);
const Color lightBackgroundColor = Color(0xFFE1D0B3);

enum MenuFilter { all, makanan, minuman }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _userName = 'Pengguna';
  String _currentUserEmail = '';
  late Future<List<dynamic>> _menuFuture;

  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  final CurrencyService _currencyService =
      CurrencyService(); // Currency Service instance

  String _currentAddress = 'Klik Lacak Lokasi';
  bool _isLocating = false;

  // NEW STATE FOR CURRENCY
  String _currentCurrencyCode = 'IDR';
  Map<String, double> _exchangeRates = {};

  String _searchQuery = '';
  MenuFilter _currentFilter = MenuFilter.all;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadInitialData(); // Load currency and then menu
  }

  void _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'FastFoodie';
      _currentUserEmail = prefs.getString('current_user_email') ?? '';
    });
  }

  // NEW METHOD: Load location, determine currency, fetch rates, then fetch menu
  void _loadInitialData() async {
    // 1. Fetch Currency Rates
    try {
      _exchangeRates = await _currencyService.getExchangeRates();
    } catch (e) {
      debugPrint('Error fetching rates: $e');
    }

    // 2. Determine User Location and Default Currency
    await _determineDefaultCurrency();

    // 3. Fetch Menu (Start fetching the menu)
    _menuFuture = _apiService.fetchMenu();
    setState(() {}); // Trigger rebuild to show menu
  }

  // Method to fetch location, determine currency, and update state
  Future<void> _determineDefaultCurrency({bool manualTrack = false}) async {
    if (!manualTrack && _currentAddress != 'Klik Lacak Lokasi') return;

    if (manualTrack) {
      setState(() {
        _isLocating = true;
      });
    }

    try {
      final position = await _locationService.getCurrentPosition();
      final locationData = await _locationService.getCountryCode(
        position.latitude,
        position.longitude,
      );
      final countryCode = locationData['code']!;
      final defaultCurrency = _currencyService.getDefaultCurrency(countryCode);
      final address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentAddress = address;
        _currentCurrencyCode = defaultCurrency;
        _isLocating = false;
      });
    } catch (e) {
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _currentAddress = manualTrack
            ? 'Error: $errorMsg'
            : 'Klik Lacak Lokasi';
        _isLocating = false;
      });
    }
  }

  // Modified _trackLocation to use _determineDefaultCurrency logic
  void _trackLocation() async {
    // Only update loading status in state for visual feedback
    setState(() {
      _isLocating = true;
      _currentAddress = 'Sedang melacak lokasi...';
    });
    // Use the comprehensive method for manual track
    await _determineDefaultCurrency(manualTrack: true);
  }

  // NEW FUNCTION: Price Converter
  String _convertAndFormatPrice(double basePrice) {
    if (_exchangeRates.isEmpty || _currentCurrencyCode == 'IDR') {
      return 'Rp ${basePrice.toStringAsFixed(0)}';
    }

    final targetRate = _exchangeRates[_currentCurrencyCode];
    if (targetRate == null) {
      return 'Rp ${basePrice.toStringAsFixed(0)}'; // Fallback
    }

    // Convert Price_IDR (basePrice) to Price_Target: Price_IDR * Rate_Target
    final convertedAmount = basePrice * targetRate;

    // Use NumberFormat for proper symbol/code formatting
    final format = NumberFormat.currency(
      locale: 'en_US', // Using en_US for consistent code placement
      symbol: _currentCurrencyCode,
      decimalDigits: convertedAmount >= 1000
          ? 0
          : 2, // Tampilkan 2 desimal jika nilainya kecil
    );

    return format.format(convertedAmount);
  }

  // NEW FUNCTION: Rating Stars Renderer
  Widget _buildRatingStars(dynamic ratingValue) {
    double rating = 0.0;
    if (ratingValue is num) {
      rating = ratingValue.toDouble();
    } else {
      // Default ke 4.0 jika tidak ada rating
      rating = 4.0;
    }

    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    // Mengubah return untuk menyertakan nilai numerik
    return Row(
      children: [
        ...List.generate(5, (index) {
          if (index < fullStars) {
            return const Icon(Icons.star, color: Colors.amber, size: 14);
          } else if (index == fullStars && hasHalfStar) {
            return const Icon(Icons.star_half, color: Colors.amber, size: 14);
          } else {
            return const Icon(Icons.star_border, color: Colors.amber, size: 14);
          }
        }),
        const SizedBox(width: 4), // Memberi sedikit spasi
        Text(
          rating.toStringAsFixed(1), // Menampilkan rating dengan 1 desimal
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Batal',
                style: TextStyle(color: darkPrimaryColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('current_user_email');
    await prefs.remove('userName');

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  void _openDetailPage(Map<String, dynamic> item) {
    if (_currentUserEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon login terlebih dahulu.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPage(
          item: item,
          currentUserEmail: _currentUserEmail,
          currentUserName: _userName, // NEW: Kirim nama pengguna
        ),
      ),
    );
  }

  Widget _buildMenuCatalog() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- END: Tombol Feedback & Welcome diatur sejajar ---

              // --- START: LOKASI DIPINDAHKAN KE HOME TAB ---
              Text(
                'Lokasi Saya:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: darkPrimaryColor,
                ),
              ),
              Text(
                '$_currentAddress | Kurs: $_currentCurrencyCode', // Display current currency
                style: TextStyle(
                  fontSize: 14,
                  color: _isLocating
                      ? Color(0xFF703B3B)
                      : darkPrimaryColor.withOpacity(0.8),
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 5),
              ElevatedButton.icon(
                onPressed: _isLocating ? null : _trackLocation,
                icon: _isLocating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.location_on, size: 18),
                label: Text(
                  _isLocating ? 'Melacak...' : 'Lacak Lokasi Sekarang',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkPrimaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(180, 35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // --- END: LOKASI DIPINDAHKAN KE HOME TAB ---
              TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search...",
                  prefixIcon: Icon(Icons.search, color: darkPrimaryColor),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 10,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkPrimaryColor,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      [
                        _buildFilterChip('Semua', MenuFilter.all),
                        _buildFilterChip('Makanan', MenuFilter.makanan),
                        _buildFilterChip('Minuman', MenuFilter.minuman),
                      ].map((widget) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: widget,
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),

        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _menuFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: darkPrimaryColor),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final rawMenuList = snapshot.data!;

                List<dynamic> filteredList = rawMenuList.where((item) {
                  final Map<String, dynamic> itemMap =
                      Map<String, dynamic>.from(item);
                  final String itemName =
                      itemMap['strMeal']?.toLowerCase() ?? '';
                  final bool matchesSearch = itemName.contains(
                    _searchQuery.toLowerCase(),
                  );
                  final String itemType = itemMap['type']?.toLowerCase() ?? '';
                  bool matchesFilter = true;

                  if (_currentFilter == MenuFilter.makanan) {
                    matchesFilter = itemType == 'makanan';
                  } else if (_currentFilter == MenuFilter.minuman) {
                    matchesFilter = itemType == 'minuman';
                  }
                  return matchesSearch && matchesFilter;
                }).toList();

                if (filteredList.isEmpty) {
                  return Center(
                    child: Text(
                      'Menu tidak ditemukan.',
                      style: TextStyle(color: darkPrimaryColor),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];

                    final isLocalAsset =
                        (item['type'] == 'Minuman' &&
                        (item['strMealThumb'] as String).startsWith('assets/'));

                    // Base price is assumed to be in IDR (from API service)
                    final double basePrice = item['price'] is num
                        ? item['price'].toDouble()
                        : 0.0;

                    return InkWell(
                      onTap: () => _openDetailPage(item),
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: darkPrimaryColor.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(15),
                                ),
                                child: isLocalAsset
                                    ? Image.asset(
                                        item['strMealThumb'],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      )
                                    : Image.network(
                                        item['strMealThumb'] ??
                                            'https://via.placeholder.com/150',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  8,
                                  10,
                                  8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // MODIFIED: RATING STARS (using item['rate'] from API)
                                        _buildRatingStars(item['rate']),
                                        const SizedBox(height: 4),

                                        // END RATING STARS
                                        Text(
                                          item['strMeal'] ?? 'Nama Menu',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: darkPrimaryColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // MODIFIED: DYNAMIC CURRENCY DISPLAY
                                        Text(
                                          _convertAndFormatPrice(basePrice),
                                          style: const TextStyle(
                                            color: darkPrimaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        // END DYNAMIC CURRENCY
                                        Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: darkPrimaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              } else {
                return Center(
                  child: Text(
                    'Tidak ada menu yang tersedia.',
                    style: TextStyle(color: darkPrimaryColor),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: darkPrimaryColor, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/alza.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person,
                          size: 60,
                          color: darkPrimaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text(
                    'Alkhila Syadza Fariha / 124230090',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: darkPrimaryColor,
                    ),
                  ),

                  const Text(
                    'Mahasiswa Pemrograman Aplikasi Mobile',
                    style: TextStyle(color: darkPrimaryColor, fontSize: 14),
                  ),

                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kesan:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: darkPrimaryColor,
                            ),
                          ),
                          const Text(
                            'Saya sangat sangat mempunyai kesan dengan mata kuliah mobile ini, lumayan ngos ngosan.',
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Saran:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: darkPrimaryColor,
                            ),
                          ),
                          const Text(
                            'Tolong dikasih deadline tugas akhir yang lebih panjang agar lebih optimal dalam pengerjaannya.',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 40, color: Colors.grey),

                  Text(
                    'Username: $_userName',
                    style: TextStyle(
                      fontSize: 18,
                      color: secondaryAccentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TimeConverterPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkPrimaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time),
                        SizedBox(width: 8),
                        Text(
                          'Konversi Waktu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReceiptPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history, color: Colors.white),
                    label: const Text(
                      'Riwayat Pembelian',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF703B3B),
                      foregroundColor: darkPrimaryColor,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, MenuFilter filter) {
    bool isSelected = _currentFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: darkPrimaryColor,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _currentFilter = filter;
          });
        }
      },
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : darkPrimaryColor,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected
              ? darkPrimaryColor
              : secondaryAccentColor.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildCartPage() {
    return const CartPage();
  }

  Widget _buildLBSPage() {
    return const LBSPage();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      _buildMenuCatalog(),
      _buildLBSPage(),
      _buildCartPage(),
      _buildProfilePage(),
    ];

    return Scaffold(
      backgroundColor: lightBackgroundColor,
      appBar: AppBar(
        backgroundColor: lightBackgroundColor,
        elevation: 0,
        foregroundColor: darkPrimaryColor,

        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Welcome, $_userName",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: darkPrimaryColor,
              ),
            ),
            // Feedback Icon Button
            IconButton(
              icon: Icon(Icons.feedback, color: secondaryAccentColor, size: 30),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // FIX: Meneruskan parameter wajib
                    builder: (context) => ApplicationCommentPage(
                      userEmail: _currentUserEmail,
                      userName: _userName,
                    ),
                  ),
                );
              },
              tooltip: 'Kirim Feedback & Ulasan',
            ),
          ],
        ),
      ),
      body: widgetOptions.elementAt(_selectedIndex),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            label: 'Home',
            icon: Icon(Icons.home),
            backgroundColor: lightBackgroundColor,
          ),
          BottomNavigationBarItem(
            label: 'Jelajah',
            icon: Icon(Icons.location_on),
            backgroundColor: lightBackgroundColor,
          ),
          BottomNavigationBarItem(
            label: 'Keranjang',
            icon: Icon(Icons.shopping_cart),
            backgroundColor: lightBackgroundColor,
          ),
          BottomNavigationBarItem(
            label: 'Profil',
            icon: Icon(Icons.person),
            backgroundColor: lightBackgroundColor,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: darkPrimaryColor,
        unselectedItemColor: secondaryAccentColor,
        backgroundColor: lightBackgroundColor,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
