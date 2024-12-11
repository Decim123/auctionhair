// time.dart

import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final String targetTimeString;
  final TextStyle? style; // Параметр для передачи стиля текста

  const CountdownTimer({
    Key? key,
    required this.targetTimeString,
    this.style,
  }) : super(key: key);

  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late DateTime targetTime;
  Timer? _timer;
  Duration? remaining;

  @override
  void initState() {
    super.initState();
    targetTime = _parseDateTime(widget.targetTimeString);
    _startTimer();
  }

  DateTime _parseDateTime(String dateTimeString) {
    try {
      int plusIndex = dateTimeString.indexOf('+');
      if (plusIndex == -1) {
        plusIndex = dateTimeString.indexOf('-');
      }
      if (plusIndex == -1) {
        // Если нет смещения, парсим как UTC
        return DateTime.parse(dateTimeString).toUtc();
      }
      String mainPart = dateTimeString.substring(0, plusIndex).trim();
      String offsetPart = dateTimeString.substring(plusIndex).trim();

      DateTime parsedTime = DateTime.parse(mainPart);

      String cleanOffset = offsetPart.replaceAll(' ', '');

      RegExp regex = RegExp(r'([+-]?)(\d{1,2}):(\d{2})');
      Match? match = regex.firstMatch(cleanOffset);
      if (match != null) {
        String sign = match.group(1) ?? '+';
        int hours = int.parse(match.group(2)!);
        int minutes = int.parse(match.group(3)!);
        Duration offset = Duration(hours: hours, minutes: minutes);
        if (sign == '-') {
          offset = -offset;
        }
        parsedTime = parsedTime.toUtc().add(offset);
      }

      return parsedTime;
    } catch (e) {
      print('Ошибка парсинга даты: $e');
      return DateTime.now().toUtc().add(Duration(hours: 3)); // MSK по умолчанию
    }
  }

  void _startTimer() {
    _updateRemaining();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final nowUtc = DateTime.now().toUtc();
    final nowMsk = nowUtc.add(Duration(hours: 3));
    setState(() {
      remaining = targetTime.difference(nowMsk);
      if (remaining!.isNegative) {
        remaining = Duration.zero;
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);
    return '${hours}ч ${minutes}м ${seconds}с';
  }

  @override
  Widget build(BuildContext context) {
    if (remaining == null) {
      return Text(
        'Загрузка...',
        style: widget.style,
      );
    }

    if (remaining == Duration.zero) {
      return Text(
        'Время истекло',
        style: widget.style?.copyWith(color: Colors.red) ??
            TextStyle(color: Colors.red),
      );
    }

    return Text(
      _formatDuration(remaining!),
      style:
          widget.style ?? TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }
}
