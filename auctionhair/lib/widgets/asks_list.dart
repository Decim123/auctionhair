// asks_list.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import '../widgets/time.dart';
import 'dart:html' as html;
import 'dart:ui' as ui;

// Регистрируем view factory для видео
void registerVideoViewFactory(String viewId, String url) {
  if (!_registeredViewTypes.contains(viewId)) {
    _registeredViewTypes.add(viewId);
    ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final html.VideoElement videoElement = html.VideoElement()
        ..src = url
        ..autoplay = true
        ..loop = true
        ..controls = false
        ..muted = true // Обязательно для автозапуска в браузерах
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'; // Обрезаем видео для заполнения контейнера

      return videoElement;
    });
  }
}

// Статический набор для отслеживания зарегистрированных viewType
final Set<String> _registeredViewTypes = {};

class AsksList extends StatefulWidget {
  final String filter;
  final int tgId;
  final Function(Map<String, dynamic> lotData) onLotSelected;

  const AsksList({
    Key? key,
    required this.filter,
    required this.tgId,
    required this.onLotSelected,
  }) : super(key: key);

  @override
  _AsksListState createState() => _AsksListState();
}

class _AsksListState extends State<AsksList> {
  List<dynamic> allAsks = [];
  List<dynamic> filteredAsks = [];
  bool isLoading = true;
  String? errorMessage;

  final Map<String, List<int>> filterStatusMapping = {
    'Все': [],
    'Прием предложений': [3],
    'Открыт спор': [5],
    'Определение победителя': [4],
    'Состоялся': [1],
    'Оплачен': [6],
    'Отправлен': [7],
    'Получен': [8],
    'Завершен': [2],
    'Отменен': [9],
  };

  final Map<int, Future<MediaType>> mediaTypeCache = {};

  @override
  void initState() {
    super.initState();
    fetchAsks();
  }

  Future<void> fetchAsks() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      var url = Uri.parse('$BASE_API_URL/api/get_asks');

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tg_id': widget.tgId}),
      );

      if (response.statusCode == 200) {
        var decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          setState(() {
            allAsks = decoded;
            isLoading = false;
          });
          applyFilter();
        } else {
          setState(() {
            errorMessage = 'Непредвиденный формат ответа от сервера.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage =
              'Не удалось загрузить аукционы. Код ошибки: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка при загрузке аукционов: $e';
        isLoading = false;
      });
    }
  }

  void applyFilter() {
    List<int>? statuses = filterStatusMapping[widget.filter];

    setState(() {
      if (statuses == null || statuses.isEmpty) {
        filteredAsks = allAsks;
      } else {
        filteredAsks = allAsks.where((auction) {
          int status = auction['status'];
          return statuses.contains(status);
        }).toList();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AsksList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      applyFilter();
    }
  }

  String getStatusText(int status) {
    Map<int, Map<String, dynamic>> statusList = {
      3: {'text': 'Прием предложений', 'color': Color(0xFF007AFF)},
      5: {'text': 'Открыт спор', 'color': Color.fromARGB(255, 217, 179, 76)},
      4: {'text': 'Определение победителя', 'color': Color(0xFF34C759)},
      1: {'text': 'Состоялся', 'color': Color.fromARGB(255, 116, 235, 69)},
      6: {'text': 'Оплачен', 'color': Color.fromARGB(255, 73, 240, 7)},
      7: {'text': 'Отправлен', 'color': Color.fromARGB(255, 230, 243, 50)},
      8: {'text': 'Получен', 'color': Color.fromARGB(255, 62, 233, 196)},
      2: {'text': 'Завершен', 'color': Color.fromARGB(255, 51, 48, 255)},
      9: {'text': 'Отменен', 'color': Color(0xFFFF3B30)},
    };

    return statusList[status]?['text'] ?? 'Неизвестно';
  }

  Color getStatusColor(int status) {
    Map<int, Map<String, dynamic>> statusList = {
      3: {'text': 'Прием предложений', 'color': Color(0xFF007AFF)},
      5: {'text': 'Открыт спор', 'color': Color.fromARGB(255, 217, 179, 76)},
      4: {'text': 'Определение победителя', 'color': Color(0xFF34C759)},
      1: {'text': 'Состоялся', 'color': Color.fromARGB(255, 116, 235, 69)},
      6: {'text': 'Оплачен', 'color': Color.fromARGB(255, 73, 240, 7)},
      7: {'text': 'Отправлен', 'color': Color.fromARGB(255, 230, 243, 50)},
      8: {'text': 'Получен', 'color': Color.fromARGB(255, 62, 233, 196)},
      2: {'text': 'Завершен', 'color': Color.fromARGB(255, 51, 48, 255)},
      9: {'text': 'Отменен', 'color': Color(0xFFFF3B30)},
    };

    return statusList[status]?['color'] ?? Colors.grey;
  }

  Future<MediaType> determineMediaType(int id) async {
    if (mediaTypeCache.containsKey(id)) {
      return mediaTypeCache[id]!;
    } else {
      final jpgUrl = '$BASE_API_URL/static/img/lots/asks/${id}_1.jpg';
      final pngUrl = '$BASE_API_URL/static/img/lots/asks/${id}_1.png';
      final mp4Url = '$BASE_API_URL/static/img/lots/asks/${id}_1.mp4';

      Future<MediaType> future = _checkMedia(jpgUrl, pngUrl, mp4Url);
      mediaTypeCache[id] = future;
      return future;
    }
  }

  Future<MediaType> _checkMedia(
      String jpgUrl, String pngUrl, String mp4Url) async {
    try {
      var jpgResponse = await http.head(Uri.parse(jpgUrl));
      if (jpgResponse.statusCode == 200) {
        return MediaType.image;
      }
    } catch (_) {}

    try {
      var pngResponse = await http.head(Uri.parse(pngUrl));
      if (pngResponse.statusCode == 200) {
        return MediaType.image;
      }
    } catch (_) {}

    try {
      var mp4Response = await http.head(Uri.parse(mp4Url));
      if (mp4Response.statusCode == 200) {
        return MediaType.video;
      }
    } catch (_) {}

    return MediaType.placeholder;
  }

  @override
  Widget build(BuildContext context) {
    // Определяем размер квадратика (можно настроить по необходимости)
    double mediaSize = MediaQuery.of(context).size.width * 0.3;

    return isLoading
        ? Center(
            child: CircularProgressIndicator(),
          )
        : errorMessage != null
            ? Center(
                child: Text(
                  errorMessage!,
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
              )
            : filteredAsks.isEmpty
                ? Center(
                    child: Text('У вас нет запросов предложений'),
                  )
                : ListView.builder(
                    itemCount: filteredAsks.length,
                    itemBuilder: (context, index) {
                      var auction = filteredAsks[index];
                      int id = auction['id'];
                      int status = auction['status'];
                      int highPrice = auction['high_price'];
                      String period = auction['period'];
                      String naturalColor = auction['natural_color'];
                      String nowColor = auction['now_color'];
                      String type = auction['type'];

                      String statusText = getStatusText(status);
                      Color statusColor = getStatusColor(status);

                      String mp4Url =
                          '$BASE_API_URL/static/img/lots/asks/${id}_1.mp4';

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<MediaType>(
                                future: determineMediaType(id),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Container(
                                      width: mediaSize,
                                      height: mediaSize,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        color: Colors.grey[200],
                                      ),
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    );
                                  } else {
                                    if (snapshot.hasData) {
                                      if (snapshot.data == MediaType.image) {
                                        return Container(
                                          width: mediaSize,
                                          height: mediaSize,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            color: Colors.grey[200],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: Image.network(
                                              '$BASE_API_URL/static/img/lots/asks/${id}_1.jpg',
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Image.network(
                                                  '$BASE_API_URL/static/img/lots/asks/${id}_1.png',
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Image.network(
                                                      '$BASE_API_URL/static/img/lots/asks/placeholder.png',
                                                      fit: BoxFit.cover,
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      } else if (snapshot.data ==
                                          MediaType.video) {
                                        // Генерируем уникальный viewId для видео
                                        final String viewId = 'video-$id';

                                        // Регистрируем фабрику для видео
                                        registerVideoViewFactory(
                                            viewId, mp4Url);

                                        return Container(
                                          width: mediaSize,
                                          height: mediaSize,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            color: Colors.grey[200],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: HtmlElementView(
                                                viewType: viewId),
                                          ),
                                        );
                                      } else {
                                        return Container(
                                          width: mediaSize,
                                          height: mediaSize,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            color: Colors.grey[200],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: Image.network(
                                              '$BASE_API_URL/static/img/lots/asks/placeholder.png',
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        );
                                      }
                                    } else {
                                      return Container(
                                        width: mediaSize,
                                        height: mediaSize,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          color: Colors.grey[200],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: Image.network(
                                            '$BASE_API_URL/static/img/lots/asks/placeholder.png',
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                              SizedBox(width: 16.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Лот $id',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 4.0),
                                    Text(
                                      'Статус: $statusText',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: statusColor,
                                      ),
                                    ),
                                    SizedBox(height: 4.0),
                                    RichText(
                                      text: TextSpan(
                                        text: 'Высшая цена: ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '$highPrice',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 4.0),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'До окончания: ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Flexible(
                                          child: CountdownTimer(
                                            targetTimeString: period,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4.0),
                                    RichText(
                                      text: TextSpan(
                                        text: 'Естественный цвет: ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '$naturalColor',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 4.0),
                                    RichText(
                                      text: TextSpan(
                                        text: 'Новый цвет: ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '$nowColor',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 4.0),
                                    RichText(
                                      text: TextSpan(
                                        text: 'Тип: ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '$type',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 8.0),
                                    ElevatedButton(
                                      onPressed: () {
                                        widget.onLotSelected(auction);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        primary: Color(0xFF007AFF),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 16),
                                      ),
                                      child: Text(
                                        'Подробнее',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
  }
}

enum MediaType { image, video, placeholder }

// Пример виджета CountdownTimer
class CountdownTimer extends StatelessWidget {
  final String targetTimeString;
  final TextStyle style;

  const CountdownTimer({
    Key? key,
    required this.targetTimeString,
    required this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Реализуйте логику обратного отсчёта по необходимости
    return Text(
      '00:00:00', // Заглушка
      style: style,
    );
  }
}
