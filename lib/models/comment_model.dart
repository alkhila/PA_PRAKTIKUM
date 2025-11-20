import 'package:hive/hive.dart';

part 'comment_model.g.dart';

@HiveType(typeId: 5)
class CommentModel extends HiveObject {
  @HiveField(0)
  late String userEmail;

  @HiveField(1)
  late String userName;

  @HiveField(2)
  late String content;

  @HiveField(3)
  late DateTime timestamp;

  @HiveField(4)
  late String itemId;

  CommentModel({
    required this.userEmail,
    required this.userName,
    required this.content,
    required this.timestamp,
    required this.itemId,
  });
}
