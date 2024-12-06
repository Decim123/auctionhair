// auctions_list.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class AuctionsList extends StatefulWidget {
  final String filter;
  final int tgId;
  final Function(Map<String, dynamic> lotData) onLotSelected;

  const AuctionsList({
    Key? key,
    required this.filter,
    required this.tgId,
    required this.onLotSelected,
  }) : super(key: key);

  @override
  _AuctionsListState createState() => _AuctionsListState();
}

class _AuctionsListState extends State<AuctionsList> {
  List<dynamic> allAuctions = [];
  List<dynamic> filteredAuctions = [];
  bool isLoading = true;
  String? errorMessage;

  final Map<String, List<int>> filterStatusMapping = {
    'Все': [],
    'Прием ставок': [0],
    'Состоялся': [1],
    'Завершен': [2],
    'Оплачен': [3],
    'Отменен': [4],
  };

  @override
  void initState() {
    super.initState();
    fetchAuctions();
  }

  Future<void> fetchAuctions() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      var url = Uri.parse('$BASE_API_URL/api/get_auctions');

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tg_id': widget.tgId}),
      );

      if (response.statusCode == 200) {
        var decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          setState(() {
            allAuctions = decoded;
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
        filteredAuctions = allAuctions;
      } else {
        filteredAuctions = allAuctions.where((auction) {
          int status = auction['status'];
          return statuses.contains(status);
        }).toList();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AuctionsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      applyFilter();
    }
  }

  String getStatusText(int status) {
    Map<int, Map<String, dynamic>> statusList = {
      0: {'text': 'Прием ставок', 'color': Color(0xFF007AFF)},
      1: {'text': 'Состоялся', 'color': Color(0xFF4CD964)},
      2: {'text': 'Завершен', 'color': Color(0xFF34C759)},
      3: {'text': 'Оплачен', 'color': Color(0xFFFF9500)},
      4: {'text': 'Отменен', 'color': Color(0xFFFF3B30)},
    };

    return statusList[status]?['text'] ?? 'Неизвестно';
  }

  Color getStatusColor(int status) {
    Map<int, Map<String, dynamic>> statusList = {
      0: {'text': 'Прием ставок', 'color': Color(0xFF007AFF)},
      1: {'text': 'Состоялся', 'color': Color(0xFF4CD964)},
      2: {'text': 'Завершен', 'color': Color(0xFF34C759)},
      3: {'text': 'Оплачен', 'color': Color(0xFFFF9500)},
      4: {'text': 'Отменен', 'color': Color(0xFFFF3B30)},
    };

    return statusList[status]?['color'] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: TextStyle(fontSize: 16, color: Colors.red),
        ),
      );
    }

    if (filteredAuctions.isEmpty) {
      return Center(
        child: Text('У вас нет аукционов'),
      );
    }

    return ListView.builder(
      itemCount: filteredAuctions.length,
      itemBuilder: (context, index) {
        var auction = filteredAuctions[index];
        int id = auction['id'];
        int status = auction['status'];
        int highPrice = auction['high_price'];
        int period = auction['period'];
        String naturalColor = auction['natural_color'];
        String nowColor = auction['now_color'];
        String type = auction['type'];

        String statusText = getStatusText(status);
        Color statusColor = getStatusColor(status);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: MediaQuery.of(context).size.width * 0.3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      '${BASE_API_URL}/static/img/lots/auctions/${id}_1.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.network(
                          '${BASE_API_URL}/static/img/lots/auctions/${id}_1.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.network(
                              '${BASE_API_URL}/static/img/lots/auctions/placeholder.png',
                              fit: BoxFit.cover,
                            );
                          },
                        );
                      },
                    ),
                  ),
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
                      RichText(
                        text: TextSpan(
                          text: 'До окончания: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          children: [
                            TextSpan(
                              text: '$period',
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
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
