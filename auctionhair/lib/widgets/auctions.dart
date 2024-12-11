import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auctions_list.dart';
import '../telegram_controller.dart';

class Auctions extends StatefulWidget {
  final VoidCallback onCreateAuction;
  final Function(Map<String, dynamic> lotData) onLotSelected;

  const Auctions({
    Key? key,
    required this.onCreateAuction,
    required this.onLotSelected,
  }) : super(key: key);

  @override
  _AuctionsState createState() => _AuctionsState();
}

class _AuctionsState extends State<Auctions> {
  String selectedFilter = 'Все';
  final List<String> filters = [
    'Все',
    'Прием ставок',
    'Состоялся',
    'Завершен',
    'Оплачен',
    'Отменен',
  ];

  final TelegramController telegramController = Get.find<TelegramController>();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // Перенаправляем вертикальную прокрутку на горизонтальную
      _scrollController.animateTo(
        _scrollController.offset + event.scrollDelta.dy,
        duration: Duration(milliseconds: 100),
        curve: Curves.linear,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ElevatedButton(
            onPressed: widget.onCreateAuction,
            style: ElevatedButton.styleFrom(
              primary: Color(0xFF007AFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
            child: Text(
              'Создать аукцион',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Listener(
            onPointerSignal: _onPointerSignal,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((filter) {
                  bool isSelected = selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: isSelected ? Colors.white : Color(0xFF007AFF),
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedFilter = filter;
                        });
                      },
                      selectedColor: Color(0xFF007AFF),
                      backgroundColor: Color(0xFFECF2FF),
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        Expanded(
          child: GetBuilder<TelegramController>(
            builder: (controller) {
              if (controller.userId == null) {
                return Center(
                  child: Text(
                    'Не удалось получить ID пользователя Telegram.',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                );
              }
              return AuctionsList(
                tgId: controller.userId!,
                filter: selectedFilter,
                onLotSelected: widget.onLotSelected,
              );
            },
          ),
        ),
      ],
    );
  }
}
