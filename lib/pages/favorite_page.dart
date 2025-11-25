import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_model.dart';
import 'detail_page.dart';
import '../services/api_service.dart';

const Color darkPrimaryColor = Color(0xFF703B3B);
const Color secondaryAccentColor = Color(0xFFA18D6D);
const Color lightBackgroundColor = Color(0xFFE1D0B3);

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  String _currentUserEmail = '';
  String _currentUserName = '';
  late Future<List<dynamic>> _menuFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _menuFuture = _apiService.fetchMenu();
  }

  void _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserEmail = prefs.getString('current_user_email') ?? '';
      _currentUserName = prefs.getString('userName') ?? 'Pengguna';
    });
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
          currentUserName: _currentUserName,
        ),
      ),
    );
  }

  Map<String, dynamic>? _findMenuDetail(String idMeal, List<dynamic> allMenus) {
    try {
      return allMenus.firstWhere((menu) => menu['idMeal'] == idMeal);
    } catch (_) {
      return null;
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

  @override
  Widget build(BuildContext context) {
    if (_currentUserEmail.isEmpty) {
      return Center(
        child: Text(
          'Mohon login untuk melihat favorit.',
          style: TextStyle(color: darkPrimaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: lightBackgroundColor,
      body: FutureBuilder<List<dynamic>>(
        future: _menuFuture,
        builder: (context, menuSnapshot) {
          if (menuSnapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: darkPrimaryColor),
            );
          } else if (menuSnapshot.hasError || !menuSnapshot.hasData) {
            return Center(
              child: Text(
                'Gagal memuat data menu: ${menuSnapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final List<dynamic> allMenus = menuSnapshot.data!;

          return ValueListenableBuilder(
            valueListenable: Hive.box<FavoriteModel>(
              'favoriteBox',
            ).listenable(),
            builder: (context, Box<FavoriteModel> box, _) {
              final userFavorites = box.values
                  .where((item) => item.userEmail == _currentUserEmail)
                  .toList();

              if (userFavorites.isEmpty) {
                return Center(
                  child: Text(
                    'Anda belum memiliki menu favorit.',
                    style: TextStyle(color: darkPrimaryColor),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: userFavorites.length,
                itemBuilder: (context, index) {
                  final favoriteItem = userFavorites[index];
                  final itemDetail = _findMenuDetail(
                    favoriteItem.idMeal,
                    allMenus,
                  );

                  final item =
                      itemDetail ??
                      {
                        "idMeal": favoriteItem.idMeal,
                        "strMeal": favoriteItem.strMeal,
                        "strMealThumb": favoriteItem.strMealThumb,
                        "type": "N/A",
                        "price": 0.0,
                        "rate": 0.0,
                        "description": "Deskripsi tidak tersedia.",
                      };

                  final isLocalAsset =
                      (item['type'] == 'Minuman' &&
                      (item['strMealThumb'] as String).startsWith('assets/'));
                  final double price = item['price'] is num
                      ? item['price'].toDouble()
                      : 0.0;
                  final double rating = item['rate'] is num
                      ? item['rate'].toDouble()
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
                            child: Stack(
                              children: [
                                ClipRRect(
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
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Center(
                                                    child: Icon(
                                                      Icons.broken_image,
                                                    ),
                                                  ),
                                        ),
                                ),
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      iconSize: 20,
                                      icon: const Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        box.delete(favoriteItem.key);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${favoriteItem.strMeal} dihapus dari favorit.',
                                            ),
                                            backgroundColor: darkPrimaryColor,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
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
                                          _buildRatingStars(rating),
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
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Rp ${price.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: darkPrimaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
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
        },
      ),
    );
  }
}
