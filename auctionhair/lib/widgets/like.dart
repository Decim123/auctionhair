// like.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../telegram_controller.dart';
import '../constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Like extends StatefulWidget {
  final int like; // 1 или 0
  final int lotId;

  const Like({Key? key, required this.like, required this.lotId})
      : super(key: key);

  @override
  _LikeState createState() => _LikeState();
}

class _LikeState extends State<Like> {
  late bool isLiked;
  late TelegramController telegramController;

  @override
  void initState() {
    super.initState();
    isLiked = widget.like == 1;
    telegramController = Get.find<TelegramController>();
  }

  Future<void> toggleLike() async {
    if (telegramController.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ID не найден')),
      );
      return;
    }

    final userId = telegramController.userId!;
    final lotId = widget.lotId;
    final url = Uri.parse(
      isLiked ? '$BASE_API_URL/api/unlike' : '$BASE_API_URL/api/like',
    );

    final body = {
      'userId': userId,
      'lot_id': lotId,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        setState(() {
          isLiked = !isLiked;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось обновить статус лайка')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сети: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String iconPath =
        isLiked ? 'assets/icons/like_active.svg' : 'assets/icons/like.svg';

    return GestureDetector(
      onTap: toggleLike,
      child: SvgPicture.asset(
        iconPath,
        width: 24,
        height: 24,
        color: Color.fromARGB(255, 0, 122, 255),
      ),
    );
  }
}
