// lot_info.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart'; // Предполагается, что здесь определен BASE_API_URL
import 'photo_slider.dart';
import '../widgets/time.dart'; // Импорт CountdownTimer

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

  final Map<int, Map<String, dynamic>> statusList = {
    0: {'text': 'Прием ставок', 'color': Color(0xFF007AFF)},
    1: {'text': 'Состоялся', 'color': Color(0xFF4CD964)},
    2: {'text': 'Завершен', 'color': Color(0xFF34C759)},
    3: {'text': 'Прием предложений', 'color': Color(0xFFFF9500)},
    4: {'text': 'Определение победителя', 'color': Color(0xFFFF3B30)},
  };

  @override
  void initState() {
    super.initState();
    fetchLotData();
  }

  Future<void> fetchLotData() async {
    final url = Uri.parse('$BASE_API_URL/api/get_lot_data_by_id');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'lot_id': widget.lotId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
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
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.red, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhotoSlider(id: lotData!['id']),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  'Статус',
                  getStatusText(lotData!['status']),
                  getStatusColor(lotData!['status']),
                ),
                const SizedBox(height: 4),
                _buildDetailRow('Город', lotData!['city'] ?? 'нет данных'),
                const SizedBox(height: 4),
                _buildDetailRowWithTimer(
                  'До окончания',
                  lotData!['period']?.toString() ?? 'нет данных',
                ),
                const SizedBox(height: 4),
                _buildDetailRow(
                  'Победитель будет определен не позднее',
                  lotData!['winner_deadline'] ?? 'нет данных',
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.grey),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Длина',
                  lotData!['long']?.toString() ?? 'нет данных',
                ),
                const SizedBox(height: 4),
                _buildDetailRow(
                  'Натуральный цвет',
                  lotData!['natural_color'] ?? 'нет данных',
                ),
                const SizedBox(height: 4),
                _buildDetailRow(
                  'Текущий цвет',
                  lotData!['now_color'] ?? 'нет данных',
                ),
                const SizedBox(height: 4),
                _buildDetailRow(
                  'Тип',
                  lotData!['type'] ?? 'нет данных',
                ),
                const SizedBox(height: 4),
                _buildDetailRow(
                  'Возраст донора',
                  lotData!['age']?.toString() ?? 'нет данных',
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  '${lotData!['description'] ?? ''}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.grey),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, [Color? valueColor]) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$title: ',
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: valueColor ?? Colors.black,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithTimer(String title, String period) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$title: ',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        Flexible(
          child: CountdownTimer(
            targetTimeString: period,
            style: const TextStyle(
              fontSize: 14, // Соответствует размеру остального текста
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  String getStatusText(int status) {
    return statusList[status]?['text'] ?? 'Неизвестно';
  }

  Color getStatusColor(int status) {
    return statusList[status]?['color'] ?? Colors.grey;
  }
}
