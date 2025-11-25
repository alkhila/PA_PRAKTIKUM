import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/comment_model.dart';

const Color darkPrimaryColor = Color(0xFF703B3B);
const Color secondaryAccentColor = Color(0xFFA18D6D);
const Color lightBackgroundColor = Color(0xFFE1D0B3);
const String APP_FEEDBACK_ITEM_ID = 'APP_FEEDBACK';

class ApplicationCommentPage extends StatefulWidget {
  final String userEmail;
  final String userName;

  const ApplicationCommentPage({
    super.key,
    required this.userEmail,
    required this.userName,
  });

  @override
  State<ApplicationCommentPage> createState() => _ApplicationCommentPageState();
}

class _ApplicationCommentPageState extends State<ApplicationCommentPage> {
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
      itemId: APP_FEEDBACK_ITEM_ID,
    );

    await commentBox.add(newComment);
    _commentController.clear();
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Umpan balik Anda telah dikirim!'),
        backgroundColor: darkPrimaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackgroundColor,
      appBar: AppBar(
        title: const Text('Umpan Balik & Komentar Aplikasi'),
        backgroundColor: darkPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kirim Umpan Balik',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkPrimaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Saran, kritik, atau komentar untuk aplikasi...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: secondaryAccentColor),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _submitComment,
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text(
                      'Kirim',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: secondaryAccentColor),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: commentBox.listenable(),
              builder: (context, Box<CommentModel> box, _) {
                final appComments = box.values
                    .where((c) => c.itemId == APP_FEEDBACK_ITEM_ID)
                    .toList()
                    .reversed
                    .toList();

                if (appComments.isEmpty) {
                  return Center(
                    child: Text(
                      'Belum ada umpan balik.',
                      style: TextStyle(color: darkPrimaryColor),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: appComments.length,
                  itemBuilder: (context, index) {
                    final comment = appComments[index];
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: secondaryAccentColor,
                          child: Text(
                            comment.userName.substring(0, 1).toUpperCase(),
                          ),
                        ),
                        title: Text(
                          comment.userName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkPrimaryColor,
                          ),
                        ),
                        subtitle: Text(comment.content),
                        trailing: Text(
                          DateFormat('dd MMM').format(comment.timestamp),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
