// trades.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import '../telegram_controller.dart';
import 'sort_by.dart';
import 'trade_item.dart';

class TradesWidget extends StatefulWidget {
  final Function(int, {Map<String, dynamic>? lotData}) switchOption;
  final Map<String, dynamic> parameters;
  final Function(int) onImageTap; // Добавляем коллбек

  const TradesWidget({
    Key? key,
    required this.switchOption,
    this.parameters = const {},
    required this.onImageTap, // Принимаем коллбек
  }) : super(key: key);

  @override
  _TradesWidgetState createState() => _TradesWidgetState();
}

class _TradesWidgetState extends State<TradesWidget>
    with AutomaticKeepAliveClientMixin {
  int activeButtonIndex = 0;
  List<dynamic>? lots;
  bool _hasFetched = false;
  int _currentMax = 10;
  final ScrollController _scrollController = ScrollController();

  final List<String> inactiveIcons = [
    'assets/icons/screp.svg',
    'assets/icons/people.svg',
    'assets/icons/hearth.svg',
    'assets/icons/sort.svg',
  ];

  final List<String> activeIcons = [
    'assets/icons/screp_active.svg',
    'assets/icons/people_active.svg',
    'assets/icons/hearth_active.svg',
    'assets/icons/sort_active.svg',
  ];

  final Color inactiveColor = const Color.fromARGB(255, 236, 242, 255);
  final Color activeColor = const Color.fromARGB(255, 0, 122, 255);

  final TelegramController telegramController = Get.find<TelegramController>();

  String sortBy = 'default';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (telegramController.userId != null) {
      _fetchLots();
    } else {
      telegramController.addListener(_telegramListener);
    }
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    telegramController.removeListener(_telegramListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _telegramListener() {
    if (!_hasFetched && telegramController.userId != null) {
      _fetchLots();
      _hasFetched = true;
      telegramController.removeListener(_telegramListener);
    }
  }

  Future<void> _fetchLots() async {
    Map<String, dynamic> requestParameters = Map.from(widget.parameters);
    requestParameters['tg_id'] = telegramController.userId;
    requestParameters['sort_by'] = sortBy;

    final url = Uri.parse('$BASE_API_URL/api/sort');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestParameters),
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);

        if (data['lots'] != null && data['lots'] is List) {
          List<dynamic> initialLots = data['lots'];
          await _fetchSortedLots(initialLots);
        } else {
          setState(() {
            lots = [];
          });
        }
      } else {
        setState(() {
          lots = [];
        });
      }
    } catch (e) {
      setState(() {
        lots = [];
      });
    }
  }

  Future<void> _fetchSortedLots(List<dynamic> initialLots) async {
    final url = Uri.parse('$BASE_API_URL/api/sort_by');
    Map<String, dynamic> sortByParameters = {
      'sort_by': sortBy,
      'lots': initialLots,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(sortByParameters),
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);

        if (data['lots'] != null && data['lots'] is List) {
          setState(() {
            lots = data['lots'];
          });
        } else {
          setState(() {
            lots = [];
          });
        }
      } else {
        setState(() {
          lots = [];
        });
      }
    } catch (e) {
      setState(() {
        lots = [];
      });
    }
  }

  void _openSortByModal() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SortBy(
          initialSortBy: sortBy,
        );
      },
    );

    if (result != null) {
      setState(() {
        sortBy = result;
        _currentMax = 10;
        _fetchLots();
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        lots != null &&
        _currentMax < lots!.length) {
      setState(() {
        _currentMax += 10;
        if (_currentMax > lots!.length) {
          _currentMax = lots!.length;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final size = MediaQuery.of(context).size;
    final buttonSize = size.width * 0.05;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    activeButtonIndex = 0;
                  });
                  widget.switchOption(2);
                },
                child: Container(
                  width: buttonSize * 2,
                  height: buttonSize * 2,
                  decoration: BoxDecoration(
                    color: activeButtonIndex == 0 ? activeColor : inactiveColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      activeButtonIndex == 0
                          ? activeIcons[0]
                          : inactiveIcons[0],
                      width: 16,
                      height: 16,
                      color:
                          activeButtonIndex == 0 ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        activeButtonIndex = 1;
                      });
                    },
                    child: Container(
                      width: buttonSize * 2,
                      height: buttonSize * 2,
                      decoration: BoxDecoration(
                        color: activeButtonIndex == 1
                            ? activeColor
                            : inactiveColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          activeButtonIndex == 1
                              ? activeIcons[1]
                              : inactiveIcons[1],
                          width: 16,
                          height: 16,
                          color: activeButtonIndex == 1
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        activeButtonIndex = 2;
                      });
                    },
                    child: Container(
                      width: buttonSize * 2,
                      height: buttonSize * 2,
                      decoration: BoxDecoration(
                        color: activeButtonIndex == 2
                            ? activeColor
                            : inactiveColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          activeButtonIndex == 2
                              ? activeIcons[2]
                              : inactiveIcons[2],
                          width: 16,
                          height: 16,
                          color: activeButtonIndex == 2
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    activeButtonIndex = 3;
                  });
                  _openSortByModal();
                },
                child: Container(
                  width: buttonSize * 2,
                  height: buttonSize * 2,
                  decoration: BoxDecoration(
                    color: activeButtonIndex == 3 ? activeColor : inactiveColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      activeButtonIndex == 3
                          ? activeIcons[3]
                          : inactiveIcons[3],
                      width: 16,
                      height: 16,
                      color:
                          activeButtonIndex == 3 ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: lots != null
                ? ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _currentMax <= lots!.length
                        ? _currentMax
                        : lots!.length,
                    itemBuilder: (context, index) {
                      return TradeItem(
                        number: lots![index],
                        onImageTap: widget.onImageTap, // Передаём коллбек
                      );
                    },
                  )
                : telegramController.userId != null
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : Center(
                        child: Text(
                          'tg_id не доступен. Убедитесь, что вы вошли через Telegram.',
                          style: TextStyle(fontSize: 14, color: Colors.red),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
