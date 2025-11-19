import 'package:hive/hive.dart';
import 'cart_item_model.dart';

part 'purchase_history_model.g.dart';

@HiveType(typeId: 4)
class PurchaseHistoryModel extends HiveObject {
  @HiveField(0)
  late double finalPrice;

  @HiveField(1)
  late String currency;

  @HiveField(2)
  late DateTime purchaseTime;

  @HiveField(3)
  late List<CartItemModel> items;

  @HiveField(4)
  late String userEmail;

  PurchaseHistoryModel({
    required this.finalPrice,
    required this.currency,
    required this.purchaseTime,
    required this.items,
    required this.userEmail,
  });
}
