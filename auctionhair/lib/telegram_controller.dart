// telegram_controller.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:js' as js;

class TelegramController extends GetxController {
  Map<String, dynamic>? telegramData;
  int? userId; // Переменная для хранения Telegram ID пользователя

  @override
  void onInit() {
    super.onInit();
    getTelegramData();
  }

  void getTelegramData() {
    telegramData = initTelegramWebApp();
    if (telegramData != null) {
      debugPrint('Telegram Data: $telegramData');
      userId =
          telegramData?['user']?['id']; // Извлекаем Telegram ID пользователя
      debugPrint('Telegram User ID: $userId');
    } else {
      debugPrint('Telegram data is null. This app is opened outside Telegram');
    }
    update();
  }

  // Функция для инициализации Telegram WebApp
  static Map<String, dynamic>? initTelegramWebApp() {
    final result = js.context.callMethod('initTelegramWebApp');
    if (result != null) {
      // Преобразуем JsObject в JSON-строку, затем парсим в Map
      String jsonString = js.context['JSON'].callMethod('stringify', [result]);
      return jsonDecode(jsonString);
    }
    return null;
  }

  // Функция для отправки данных обратно в Telegram
  static void sendTelegramData(String data) {
    js.context.callMethod('sendTelegramData', [data]);
  }

  // Функция для управления MainButton в Telegram
  static void setMainButton(String text, bool isVisible) {
    js.context.callMethod('setMainButton', [text, isVisible]);
  }
}
