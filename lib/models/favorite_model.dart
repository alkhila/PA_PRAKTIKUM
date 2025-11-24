import 'package:hive/hive.dart';

part 'favorite_model.g.dart';

@HiveType(typeId: 6)
class FavoriteModel extends HiveObject {
  @HiveField(0)
  late String idMeal;

  @HiveField(1)
  late String strMeal;

  @HiveField(2)
  late String strMealThumb;

  @HiveField(3)
  late String userEmail;

  FavoriteModel({
    required this.idMeal,
    required this.strMeal,
    required this.strMealThumb,
    required this.userEmail,
  });
}
