import 'package:flutter/material.dart';
import 'package:pa_restoran2/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/user_model.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'models/cart_item_model.dart';
import 'models/purchase_history_model.dart';
import 'models/comment_model.dart'; // NEW: Import CommentModel

const Color accentColor = Color(0xFFFFB300);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(CartItemModelAdapter());
  Hive.registerAdapter(PurchaseHistoryModelAdapter());
  Hive.registerAdapter(CommentModelAdapter()); // NEW: Daftarkan CommentModel

  await Hive.openBox<UserModel>('userBox');
  await Hive.openBox<CartItemModel>('cartBox');
  await Hive.openBox<PurchaseHistoryModel>('historyBox');
  await Hive.openBox<CommentModel>('commentBox'); // NEW: Buka Comment Box

  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FastFood App TA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.brown, fontFamily: 'Roboto'),
      home: FutureBuilder<bool>(
        future: _checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          }
          return snapshot.data == true ? const HomePage() : const LoginPage();
        },
      ),

      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }

  Future<bool> _checkLoginStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userEmailExists = prefs.getString('current_user_email') != null;

    return isLoggedIn && userEmailExists;
  }
}
