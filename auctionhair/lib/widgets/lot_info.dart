// lot_info.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart'; // Предполагается, что здесь определен BASE_API_URL
import 'photo_slider.dart';

class LotInfo extends StatefulWidget {
  final int lotId;

  const LotInfo({Key? key, required this.lotId}) : super(key: key);

  @override
  _LotInfoState createState() => _LotInfoState();
}

class _LotInfoState extends State<LotInfo> {
  Map<String, dynamic>? lotData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchLotData();
  }

  // Функция для получения данных о лоте из API
  Future<void> fetchLotData() async {
    final url = Uri.parse('$BASE_API_URL/api/get_lot_data_by_id');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'lot_id': widget.lotId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          lotData = data;
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          errorMessage = 'Лот не найден.';
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Произошла ошибка: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка подключения: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Пока идет загрузка данных
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Детали лота'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Если произошла ошибка
    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Детали лота'),
        ),
        body: Center(
          child: Text(
            errorMessage!,
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    // Если данные успешно получены
    return Scaffold(
      appBar: AppBar(
        title: Text('Детали лота'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Используем виджет PhotoSlider, передавая id лота
            PhotoSlider(id: lotData!['id']),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Статус и другие детали
                  _buildDetailRow(
                      'Статус', lotData!['status']?.toString() ?? 'нет данных'),
                  SizedBox(height: 4),
                  _buildDetailRow('Город', lotData!['city'] ?? 'нет данных'),
                  SizedBox(height: 4),
                  _buildDetailRow('До окончания',
                      lotData!['period']?.toString() ?? 'нет данных'),
                  SizedBox(height: 4),
                  _buildDetailRow('Победитель будет определен не позднее',
                      lotData!['winner_deadline'] ?? 'нет данных'),
                  SizedBox(height: 16),
                  Divider(color: Colors.grey),
                  SizedBox(height: 16),
                  _buildDetailRow(
                      'Длина', lotData!['long']?.toString() ?? 'нет данных'),
                  SizedBox(height: 4),
                  _buildDetailRow('Натуральный цвет',
                      lotData!['natural_color'] ?? 'нет данных'),
                  SizedBox(height: 4),
                  _buildDetailRow(
                      'Текущий цвет', lotData!['now_color'] ?? 'нет данных'),
                  SizedBox(height: 4),
                  _buildDetailRow('Тип', lotData!['type'] ?? 'нет данных'),
                  SizedBox(height: 4),
                  _buildDetailRow('Возраст донора',
                      lotData!['age']?.toString() ?? 'нет данных'),
                  SizedBox(height: 16),
                  Text(
                    '${lotData!['description'] ?? ''}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Вспомогательный виджет для отображения строки с деталями
  Widget _buildDetailRow(String title, String value) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$title: ',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: value,
            style: TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }
}
