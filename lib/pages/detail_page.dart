import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart_item_model.dart';

const Color brownColor = Color(0xFF4E342E);
const Color accentColor = Color(0xFFFFB300);
const Color darkPrimaryColor = Color(0xFF703B3B);
const Color secondaryAccentColor = Color(0xFFA18D6D);
const Color lightBackgroundColor = Color(0xFFE1D0B3);

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> item;
  final String currentUserEmail;

  const DetailPage({
    super.key,
    required this.item,
    required this.currentUserEmail,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int _quantity = 1;
  late double _itemPrice;
  late double _basePrice;

  @override
  void initState() {
    super.initState();

    var priceData = widget.item['price'];

    if (priceData is double) {
      _basePrice = priceData;
    } else if (priceData is int) {
      _basePrice = priceData.toDouble();
    } else {
      _basePrice = 0.0;
    }
    _itemPrice = _basePrice;
  }

  void _addToCart() async {
    final cartBox = Hive.box<CartItemModel>('cartBox');

    final newItem = CartItemModel(
      idMeal: widget.item['idMeal'] ?? UniqueKey().toString(),
      strMeal: widget.item['strMeal'] ?? 'Unknown Item',
      strMealThumb: widget.item['strMealThumb'] ?? '',
      quantity: _quantity,
      price: _itemPrice,
      userEmail: widget.currentUserEmail,
    );

    final existingItemIndex = cartBox.values.toList().indexWhere(
      (e) => e.idMeal == newItem.idMeal && e.userEmail == newItem.userEmail,
    );

    if (existingItemIndex != -1) {
      final existingItem = cartBox.getAt(existingItemIndex)!;
      existingItem.quantity += _quantity;
      await existingItem.save();
    } else {
      await cartBox.add(newItem);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_quantity}x ${newItem.strMeal} ditambahkan ke keranjang!',
        ),
        backgroundColor: darkPrimaryColor,
      ),
    );
    Navigator.pop(context);
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: secondaryAccentColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: secondaryAccentColor.withOpacity(0.5)),
      ),
      child: IconButton(
        icon: Icon(icon, color: darkPrimaryColor),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isLocalAsset =
        (item['type'] == 'Minuman' &&
        (item['strMealThumb'] as String).startsWith('assets/'));
    final imageUrl = isLocalAsset
        ? item['strMealThumb']
        : item['strMealThumb'] ?? 'https://via.placeholder.com/250';

    return Scaffold(
      backgroundColor: lightBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            width: double.infinity,
            child: isLocalAsset
                ? Image.asset(imageUrl, fit: BoxFit.cover)
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.broken_image, size: 80)),
                  ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.fromLTRB(25, 30, 25, 0),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 249, 245, 241),
                borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['strMeal'] ?? 'Unknown Item',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: darkPrimaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Kategori: ${item['type'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const Divider(height: 30),

                  Text(
                    'Jumlah Pesanan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _buildQuantityButton(Icons.remove, () {
                        setState(() {
                          if (_quantity > 1) _quantity--;
                        });
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildQuantityButton(Icons.add, () {
                        setState(() {
                          _quantity++;
                        });
                      }),
                    ],
                  ),
                  const Divider(height: 30),

                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        'Aplikasi ini adalah tugas akhir Pemrograman Aplikasi Mobile (PAM). Menu yang ditampilkan berasal dari API TheMealDB dan data statis. Harga yang tertera adalah harga simulasi. Menu yang Anda pilih siap disajikan dengan cepat dan nikmat!',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 25.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _addToCart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: darkPrimaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.shopping_cart,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Add to Cart | Rp ${(_itemPrice * _quantity).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
}
