import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'time_converter_page.dart';
import '../services/api_service.dart';
import 'cart_page.dart';
import 'lbs_page.dart';
import 'detail_page.dart';
import 'login_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'checkout_detail_page.dart';
import 'application_comment_page.dart';
import 'favorite_page.dart';
import '../models/favorite_model.dart';
import 'edit_profile_page.dart';
import 'checkout_detail_page.dart';
import 'package:flutter/foundation.dart'; // Import untuk kIsWeb

const Color darkPrimaryColor = Color(0xFF703B3B);
const Color secondaryAccentColor = Color(0xFFA18D6D);
const Color lightBackgroundColor = Color(0xFFE1D0B3);

enum MenuFilter { all, makanan, minuman }

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
  final favoriteBox = Hive.box<FavoriteModel>('favoriteBox');

  String _searchQuery = '';
  MenuFilter _currentFilter = MenuFilter.all;

  String _userAddress = 'Alamat belum diatur';
  String _profileImagePath = '';

  // FIXED CONSTANTS
  final double avatarRadius = 60;
  final double headerHeight = 150; // Ketinggian header

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
      _userAddress = prefs.getString('user_address') ?? 'Alamat belum diatur';
      _profileImagePath = prefs.getString('profile_image_path') ?? '';
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
    await prefs.remove('user_address');
    await prefs.remove('profile_image_path');

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    );
    _loadUserInfo();
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.photo_library, color: darkPrimaryColor),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromSource(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: darkPrimaryColor),
              title: const Text('Ambil Foto Baru'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromSource(ImageSource.camera);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 55,
    );

    if (pickedFile != null) {
      final prefs = await SharedPreferences.getInstance();

      // Di Web/Mobile, simpan path/url
      await prefs.setString('profile_image_path', pickedFile.path);
      _loadUserInfo();
    }
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
        ),
      ),
    );
  }

  void _toggleFavorite(Map<String, dynamic> item) async {
    if (_currentUserEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon login untuk menggunakan fitur favorit.'),
        ),
      );
      return;
    }

    final String itemId = item['idMeal'] ?? UniqueKey().toString();
    final existingFavoriteKey = favoriteBox.keys.firstWhere(
      (key) =>
          favoriteBox.get(key)?.idMeal == itemId &&
          favoriteBox.get(key)?.userEmail == _currentUserEmail,
      orElse: () => null,
    );

    if (existingFavoriteKey != null) {
      await favoriteBox.delete(existingFavoriteKey);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item['strMeal']} dihapus dari favorit.'),
          backgroundColor: secondaryAccentColor,
        ),
      );
    } else {
      final newFavorite = FavoriteModel(
        idMeal: itemId,
        strMeal: item['strMeal'] ?? 'Unknown Item',
        strMealThumb: item['strMealThumb'] ?? '',
        userEmail: _currentUserEmail,
      );
      await favoriteBox.add(newFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item['strMeal']} ditambahkan ke favorit!'),
          backgroundColor: darkPrimaryColor,
        ),
      );
    }
  }

  Widget _buildRatingStars(dynamic ratingValue) {
    double rating = 0.0;
    if (ratingValue is num) {
      rating = ratingValue.toDouble();
    } else {
      rating = 4.0;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 14),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

                return ValueListenableBuilder(
                  valueListenable: favoriteBox.listenable(),
                  builder: (context, Box<FavoriteModel> box, _) {
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        final itemId = item['idMeal'];

                        final isFavorite = box.values.any(
                          (favItem) =>
                              favItem.idMeal == itemId &&
                              favItem.userEmail == _currentUserEmail,
                        );

                        final isLocalAsset =
                            (item['type'] == 'Minuman' &&
                            (item['strMealThumb'] as String).startsWith(
                              'assets/',
                            ));

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
                                    child: Stack(
                                      children: [
                                        isLocalAsset
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
                                        Positioned(
                                          top: 5,
                                          right: 5,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              iconSize: 20,
                                              icon: Icon(
                                                isFavorite
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: isFavorite
                                                    ? Colors.red
                                                    : Colors.white,
                                              ),
                                              onPressed: () =>
                                                  _toggleFavorite(item),
                                            ),
                                          ),
                                        ),
                                      ],
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item['strMeal'] ??
                                                        'Nama Menu',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: darkPrimaryColor,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                _buildRatingStars(item['rate']),
                                              ],
                                            ),
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
                                            Text(
                                              'Rp ${price.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                color: darkPrimaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
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

  // REVISED: Struktur field diperbaiki agar sesuai gambar referensi
  Widget _buildProfileInfoField({
    required String label,
    required String value,
    required IconData icon,
    bool isPassword = false,
    bool isDeliveryAddress = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label (Nama/Email/Alamat) - Dibuat kecil dan diletakkan di atas input
        Padding(
          padding: const EdgeInsets.only(left: 10.0, bottom: 4.0),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: darkPrimaryColor.withOpacity(0.7),
            ),
          ),
        ),
        // Input Container/Box (White box)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              20,
            ), // Border radius diperbesar agar lebih melengkung
            border: Border.all(color: secondaryAccentColor.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 0,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isPassword ? '••••••••' : value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isPassword ? FontWeight.bold : FontWeight.w500,
                    color: isPassword ? Colors.black : darkPrimaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: isDeliveryAddress ? 2 : 1,
                ),
              ),
              // Icon berada di dalam field, di kanan
              Icon(icon, color: darkPrimaryColor.withOpacity(0.7), size: 20),
            ],
          ),
        ),
        const SizedBox(height: 15), // Jarak antar field
      ],
    );
  }

  // MODIFIED: Implementasi UI Profil - Final Structural Fix
  Widget _buildProfilePage() {
    // NEW: Handle crash on web (since File() is unsupported)
    final bool isWeb = kIsWeb;
    // FIX IMAGE LOGIC: Jika path ada, kita asumsikan gambar bisa ditampilkan
    final bool hasImagePath = _profileImagePath.isNotEmpty;

    // FIXED CONSTANTS
    final Color headerColorStart = darkPrimaryColor;
    final Color headerColorEnd = secondaryAccentColor;
    final double avatarOverlap = 60.0; // Jarak avatar menonjol ke bawah

    ImageProvider? imageProvider;
    if (hasImagePath) {
      if (isWeb) {
        // Web: Gunakan NetworkImage untuk blob URL
        imageProvider = NetworkImage(_profileImagePath);
      } else {
        // Mobile/Desktop: Check file existence before FileImage
        if (File(_profileImagePath).existsSync()) {
          imageProvider = FileImage(File(_profileImagePath));
        }
      }
    }

    // Perhitungan space kompensasi agar konten fields terangkat pas di bawah avatar
    final double verticalCompensationSpace =
        avatarRadius * 2 + 160; // 60*2 + 20 = 140px (Nilai baru)

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          // 1. Header Background (Curved Bottom)
          Container(
            height: headerHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [headerColorStart, headerColorEnd],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
          ),

          // 2. Profile Details/Content (FIELDS)
          // Menggunakan Transform.translate untuk menggeser konten ke atas (menghilangkan gap)
          Transform.translate(
            offset: Offset(0, -avatarOverlap), // PULL UP CONTENT 60px
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Kompensasi Ruang di atas Fields ---
                  // Memberikan ruang yang dihilangkan oleh Transform.translate
                  // FIXED: Disesuaikan menjadi 140px untuk memastikan clearance visual
                  SizedBox(height: verticalCompensationSpace),

                  // --- Profile Fields ---
                  _buildProfileInfoField(
                    label: 'Nama',
                    value: _userName,
                    icon: Icons.person_outline,
                  ),
                  _buildProfileInfoField(
                    label: 'Email',
                    value: _currentUserEmail,
                    icon: Icons.email_outlined,
                  ),
                  _buildProfileInfoField(
                    label: 'Alamat Pengiriman',
                    value: _userAddress,
                    icon: Icons.location_on_outlined,
                    isDeliveryAddress: true,
                  ),
                  _buildProfileInfoField(
                    label: 'Kata Sandi',
                    value: '••••••••',
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: 10),

                  // 5. Order History
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReceiptPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: secondaryAccentColor.withOpacity(0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 0,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Riwayat Pembelian',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: darkPrimaryColor,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: darkPrimaryColor.withOpacity(0.7),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- Action Buttons ---
                  Row(
                    children: [
                      // Edit Profile Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openEditProfile,
                          icon: const Icon(
                            Icons.edit_note_sharp,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Edit Profile',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkPrimaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Logout Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _confirmLogout,
                          icon: const Icon(
                            Icons.logout,
                            color: darkPrimaryColor,
                          ),
                          label: const Text(
                            'Log out',
                            style: TextStyle(color: darkPrimaryColor),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            side: BorderSide(color: darkPrimaryColor, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. Profile Picture (Diposisikan di tengah area overlap)
          Positioned(
            top: headerHeight - avatarRadius, // 150 - 60 = 90px dari atas
            child: Center(
              child: Stack(
                children: [
                  // Profile Picture
                  CircleAvatar(
                    radius: avatarRadius, // 60
                    backgroundColor: Colors.white,
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: darkPrimaryColor,
                          )
                        : null,
                  ),
                  // Add/Change Photo Button
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: darkPrimaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildFavoritePage() {
    return const FavoritePage();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      _buildMenuCatalog(),
      _buildLBSPage(),
      _buildCartPage(),
      _buildFavoritePage(),
      _buildProfilePage(),
    ];

    return Scaffold(
      backgroundColor: lightBackgroundColor,
      appBar: AppBar(
        backgroundColor: lightBackgroundColor,
        elevation: 0,
        foregroundColor: darkPrimaryColor,
        automaticallyImplyLeading: false,
        title: Text(
          "Welcome, $_userName",
          style: TextStyle(
            color: darkPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
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
            label: 'Favorit',
            icon: Icon(Icons.favorite),
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
            if (index == 4) {
              _loadUserInfo();
            }
          });
        },
      ),
    );
  }
}
