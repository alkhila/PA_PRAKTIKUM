import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'time_converter_page.dart';
import '../services/api_service.dart';
// import '../services/location_service.dart'; // Dihapus
import 'cart_page.dart';
import 'lbs_page.dart';
import 'detail_page.dart';
import 'login_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'checkout_detail_page.dart';
import 'application_comment_page.dart';
// import '../services/currency_service.dart'; // Dihapus

const Color darkPrimaryColor = Color(0xFF703B3B);
const Color secondaryAccentColor = Color(0xFFA18D6D);
const Color lightBackgroundColor = Color(0xFFE1D0B3);

enum MenuFilter { all, makanan, minuman }

// NEW: Enum untuk opsi di Hamburger Menu
enum MenuChoice { applicationComment, timeConverter, logout }

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

  String _searchQuery = '';
  MenuFilter _currentFilter = MenuFilter.all;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _menuFuture = _apiService.fetchMenu();
  }

  void _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'FastFoodie';
      _currentUserEmail = prefs.getString('current_user_email') ?? '';
    });
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
          currentUserName: _userName,
        ), // Meneruskan username
      ),
    );
  }

  // MODIFIED FUNCTION: Rating Stars Renderer
  Widget _buildRatingStars(dynamic ratingValue) {
    double rating = 0.0;
    if (ratingValue is num) {
      rating = ratingValue.toDouble();
    } else {
      rating = 4.0; // Fallback
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 14), // Bintang visual
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1), // Nilai rating numerik
          style: const TextStyle(
            fontSize: 12,
            color: darkPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCatalog() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            0,
          ), // Mengubah padding atas menjadi 20
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER 'WELCOME' DAN ICON FEEDBACK DIHAPUS DARI SINI ---
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

                    // Harga default IDR
                    final double price = item['price'] is num
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
                                        Row(
                                          // Judul dan Rating berdampingan
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item['strMeal'] ?? 'Nama Menu',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: darkPrimaryColor,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            // RATING BARU (Bintang + Angka)
                                            _buildRatingStars(item['rate']),
                                          ],
                                        ),

                                        // DESKRIPSI MENU (Max 2 baris)
                                        Text(
                                          item['description'] ??
                                              'Deskripsi tidak tersedia.',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[700],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // HARGA DEFAULT IDR
                                        Text(
                                          'Rp ${price.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            color: darkPrimaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        // END HARGA DEFAULT
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

                  // TOMBOL KONVERSI WAKTU DIHAPUS DARI SINI
                  // SizedBox(height: 20) yang lama dihilangkan
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
                  // TOMBOL LOGOUT DIHAPUS DARI SINI
                ],
              ),
            ),
            // Tombol Logout asli dipindah ke sini agar tidak double
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
      // MODIFIED: AppBar Baru dengan Hamburger Menu
      appBar: AppBar(
        backgroundColor: lightBackgroundColor,
        elevation: 0,
        foregroundColor: darkPrimaryColor,
        automaticallyImplyLeading: false,

        title: Text(
          "Welcome, $_userName", // Judul AppBar menampilkan Welcome
          style: TextStyle(
            color: darkPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // Hamburger Menu Button
          PopupMenuButton<MenuChoice>(
            icon: Icon(Icons.menu, color: darkPrimaryColor, size: 30),
            onSelected: (MenuChoice result) {
              switch (result) {
                case MenuChoice.applicationComment:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ApplicationCommentPage(
                        userEmail: _currentUserEmail,
                        userName: _userName,
                      ),
                    ),
                  );
                  break;
                case MenuChoice.timeConverter:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TimeConverterPage(),
                    ),
                  );
                  break;
                case MenuChoice.logout:
                  _confirmLogout();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuChoice>>[
              const PopupMenuItem<MenuChoice>(
                value: MenuChoice.applicationComment,
                child: Row(
                  children: [
                    Icon(Icons.feedback, color: darkPrimaryColor),
                    SizedBox(width: 10),
                    Text('Komen Aplikasi'),
                  ],
                ),
              ),
              const PopupMenuItem<MenuChoice>(
                value: MenuChoice.timeConverter,
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: darkPrimaryColor),
                    SizedBox(width: 10),
                    Text('Konversi Waktu'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<MenuChoice>(
                value: MenuChoice.logout,
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),

      // END MODIFIED: AppBar Baru
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
