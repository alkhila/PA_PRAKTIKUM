import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  late String email;

  @HiveField(1)
  late String password;

  @HiveField(2)
  late String username;

  UserModel({
    required this.email,
    required this.password,
    required this.username,
  });
}
