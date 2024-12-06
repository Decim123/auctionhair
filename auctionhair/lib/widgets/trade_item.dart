// trade_item.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'photo_slider_items.dart';
import '../constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../telegram_controller.dart';
import 'like.dart';

class TradeItem extends StatelessWidget {
  final int number;
  final Function(int) onImageTap; // Добавляем коллбек

  const TradeItem({Key? key, required this.number, required this.onImageTap})
      : super(key: key);

  Future<Map<String, dynamic>> fetchLotShortInfo(int number, int userId) async {
    final url = Uri.parse('$BASE_API_URL/api/get_lot_short_info');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'number': number, 'userId': userId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Не удалось загрузить данные лота');
    }
  }

  @override
  Widget build(BuildContext context) {
    double itemHeight = MediaQuery.of(context).size.height * 0.35;
    double itemWidth = MediaQuery.of(context).size.width * 0.95;
    double borderRadius = 20.0;

    final TelegramController telegramController =
        Get.find<TelegramController>();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.0),
      width: itemWidth,
      height: itemHeight,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: FutureBuilder<Map<String, dynamic>>(
          future: telegramController.userId != null
              ? fetchLotShortInfo(number, telegramController.userId!)
              : Future.error('User ID не найден'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Ошибка загрузки данных: ${snapshot.error}'),
              );
            } else if (snapshot.hasData) {
              final data = snapshot.data!;
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(borderRadius),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: itemHeight * 0.80,
                      child: PhotoSlider(
                        id: number,
                        onImageTap: onImageTap, // Передаём коллбек
                      ),
                    ),
                  ),
                  Container(
                    height: itemHeight * 0.20,
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: [
                              InfoItem(
                                label: data['step'].toString() + '₽',
                                itemHeight: itemHeight,
                              ),
                              InfoItem(
                                label: data['period'].toString(),
                                itemHeight: itemHeight,
                              ),
                              InfoItem(
                                label: data['lot_type'].toString(),
                                itemHeight: itemHeight,
                              ),
                              InfoItem(
                                label: data['status'].toString(),
                                itemHeight: itemHeight,
                              ),
                              InfoItem(
                                label: data['long'].toString() + 'см',
                                itemHeight: itemHeight,
                              ),
                              InfoItem(
                                label: data['weight'].toString() + 'г',
                                itemHeight: itemHeight,
                              ),
                              InfoItem(
                                isViews: true,
                                label: data['views'].toString(),
                                itemHeight: itemHeight,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10),
                        Like(
                          like: data['like'],
                          lotId: number,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return Center(
                child: Text('Нет данных'),
              );
            }
          },
        ),
      ),
    );
  }
}

class InfoItem extends StatelessWidget {
  final String label;
  final bool isViews;
  final double itemHeight;

  const InfoItem({
    Key? key,
    required this.label,
    this.isViews = false,
    required this.itemHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double circleSize = itemHeight * 0.06 / 2;
    double textSize = itemHeight * 0.06;
    Color circleColor = Color.fromARGB(255, 0, 122, 255);
    Color textColor = isViews ? Colors.grey : Colors.black;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isViews)
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
          ),
        if (!isViews) SizedBox(width: 6),
        isViews
            ? Row(
                children: [
                  Icon(
                    Icons.remove_red_eye,
                    color: textColor,
                    size: textSize,
                  ),
                  SizedBox(width: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: textSize,
                    ),
                  ),
                ],
              )
            : Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: textSize,
                ),
              ),
      ],
    );
  }
}
