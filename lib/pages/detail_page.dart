import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/cart_item_model.dart';
import '../models/comment_model.dart'; // Import Model Komentar

const Color brownColor = Color(0xFF4E342E);
const Color accentColor = Color(0xFFFFB300);
const Color darkPrimaryColor = Color(0xFF703B3B);
const Color secondaryAccentColor = Color(0xFFA18D6D);
const Color lightBackgroundColor = Color(0xFFE1D0B3);

// --- WIDGET: Product Comments Section (Untuk Tab Ulasan) ---
class _ProductCommentsSection extends StatefulWidget {
  final String itemId;
  final String userEmail;
  final String userName;

  const _ProductCommentsSection({
    required this.itemId,
    required this.userEmail,
    required this.userName,
  });

  @override
  State<_ProductCommentsSection> createState() =>
      _ProductCommentsSectionState();
}

class _ProductCommentsSectionState extends State<_ProductCommentsSection> {
  final TextEditingController _commentController = TextEditingController();
  final commentBox = Hive.box<CommentModel>('commentBox');

  void _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      return;
    }

    final newComment = CommentModel(
      userEmail: widget.userEmail,
      userName: widget.userName,
      content: content,
      timestamp: DateTime.now(),
      itemId: widget.itemId,
    );

    await commentBox.add(newComment);
    _commentController.clear();
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ulasan berhasil ditambahkan!'),
        backgroundColor: darkPrimaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = widget.userEmail.isNotEmpty;

    return ValueListenableBuilder(
      valueListenable: commentBox.listenable(),
      builder: (context, Box<CommentModel> box, _) {
        final comments = box.values
            .where((c) => c.itemId == widget.itemId)
            .toList()
            .reversed
            .toList();

        // Padding untuk seluruh konten komentar
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 25.0,
          ), // Padding disamakan
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Input Komentar (Hanya muncul jika logged in)
              if (isLoggedIn)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0, top: 15.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText:
                                'Tulis ulasan Anda, ${widget.userName}...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: secondaryAccentColor,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _submitComment,
                        icon: const Icon(Icons.send, size: 28),
                        color: darkPrimaryColor,
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 15, bottom: 10),
                  child: Text(
                    'Mohon login untuk dapat memberikan ulasan.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: secondaryAccentColor,
                    ),
                  ),
                ),

              Text(
                'Semua Ulasan (${comments.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkPrimaryColor,
                ),
              ),
              const Divider(),

              // Daftar Komentar
              Column(
                children: [
                  if (comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Belum ada ulasan untuk menu ini.',
                        style: TextStyle(color: secondaryAccentColor),
                      ),
                    )
                  else
                    ...comments.map((comment) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: darkPrimaryColor,
                              radius: 16,
                              child: Text(
                                comment.userName.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment.userName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: darkPrimaryColor,
                                    ),
                                  ),
                                  Text(
                                    DateFormat(
                                      'dd/MM/yy HH:mm',
                                    ).format(comment.timestamp),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: secondaryAccentColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comment.content,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
// --- END WIDGET ---

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> item;
  final String currentUserEmail;
  final String currentUserName;

  const DetailPage({
    super.key,
    required this.item,
    required this.currentUserEmail,
    required this.currentUserName,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> with TickerProviderStateMixin {
  int _quantity = 1;
  late double _itemPrice;
  late double _basePrice;
  late TabController _tabController;
  final double curveRadius = 35.0;
  final double nameCategoryContentHeight = 140.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    final itemID = item['idMeal'] ?? UniqueKey().toString();

    final isLocalAsset =
        (item['type'] == 'Minuman' &&
        (item['strMealThumb'] as String).startsWith('assets/'));
    final imageUrl = isLocalAsset
        ? item['strMealThumb']
        : item['strMealThumb'] ?? 'https://via.placeholder.com/250';

    // Image: Forced 16:9 Aspect Ratio (Landscape)
    final double fixedImageHeight =
        MediaQuery.of(context).size.width / (16 / 9);

    return Scaffold(
      backgroundColor: Color.fromARGB(
        255,
        249,
        245,
        241,
      ), // Warna Latar Belakang Scaffold
      body: Column(
        children: [
          // --- FIXED HEADER GROUP: IMAGE + CURVE OVERLAP ---
          SizedBox(
            height: fixedImageHeight + nameCategoryContentHeight,
            width: double.infinity,
            child: Stack(
              children: [
                // 1. Area Gambar (Diposisikan untuk menempati area 16:9)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: fixedImageHeight,
                  child: isLocalAsset
                      ? Image.asset(imageUrl, fit: BoxFit.cover)
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                              ),
                        ),
                ),
                // Back Button (Fixed Position)
                Positioned(
                  top: 40,
                  left: 20,
                  child: IconButton(
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

                // 2. Container Melengkung (Diposisikan di Bawah Gambar untuk overlap)
                Positioned(
                  top: fixedImageHeight - curveRadius,
                  left: 0,
                  right: 0,
                  height: nameCategoryContentHeight + curveRadius,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(25, 2 + curveRadius, 25, 0),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(
                        255,
                        249,
                        245,
                        241,
                      ), // Warna kotak coklat
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(curveRadius),
                      ), // Kurva
                    ),
                    // Konten Nama & Kategori
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        // Kategori Text
                        Text(
                          'Kategori: ${item['type'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const Divider(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- SCROLLABLE SECTION CONTAINER ---
          Expanded(
            child: Transform.translate(
              // Mengangkat sisa body ke atas untuk menyambung dengan FIXED HEADER 2
              offset: Offset(0, -curveRadius),
              child: Container(
                color: Color.fromARGB(255, 249, 245, 241),
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      // TabBar (Fixed di area scrollable)
                      Container(
                        color: Color.fromARGB(255, 249, 245, 241),
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: darkPrimaryColor,
                          unselectedLabelColor: secondaryAccentColor,
                          indicatorColor: darkPrimaryColor,
                          tabs: const [
                            Tab(text: 'Detail & Kuantitas'),
                            Tab(text: 'Ulasan Produk'),
                          ],
                        ),
                      ),

                      // TabBarView
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Tab 1: Detail & Kuantitas
                            _buildScrollableContent(
                              context,
                              isReviewTab: false,
                              itemID: itemID,
                            ),
                            // Tab 2: Ulasan Produk
                            _buildScrollableContent(
                              context,
                              isReviewTab: true,
                              itemID: itemID,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // --- FIXED FOOTER: ADD TO CART BUTTON ---
      bottomNavigationBar: Container(
        // Padding atas disetel ke 0 untuk menghilangkan artifact / ruang coklat yang tidak perlu
        padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
        color: Color.fromARGB(255, 249, 245, 241), // Warna latar belakang sama
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
              const Icon(Icons.shopping_cart, color: Colors.white),
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
    );
  }

  // Helper untuk membuat konten scrollable di setiap tab
  Widget _buildScrollableContent(
    BuildContext context, {
    required bool isReviewTab,
    required String itemID,
  }) {
    // SingleChildScrollView di dalam TabBarView memastikan konten scrollable secara independen
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10), // Padding diatur di sini
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kontrol Kuantitas & Info Dasar (Hanya di Tab 1)
          if (!isReviewTab)
            Padding(
              padding: const EdgeInsets.only(left: 25, right: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NEW FIX: Menambahkan SizedBox untuk memberi jarak di atas "Jumlah Pesanan"
                  const SizedBox(height: 15),
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
                  const Text(
                    'Aplikasi ini adalah tugas akhir Pemrograman Aplikasi Mobile (PAM). Menu yang ditampilkan berasal dari API TheMealDB dan data statis. Harga yang tertera adalah harga simulasi. Menu yang Anda pilih siap disajikan dengan cepat dan nikmat!',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 20), // Tambahan space di akhir konten
                ],
              ),
            )
          // Konten Review (Hanya di Tab 2)
          else
            _ProductCommentsSection(
              itemId: itemID,
              userEmail: widget.currentUserEmail,
              userName: widget.currentUserName,
            ),
        ],
      ),
    );
  }
}
