// trades_screen.dart

import 'package:flutter/material.dart';
import '../widgets/header.dart';
import '../widgets/trades.dart';
import '../widgets/params.dart';
import '../widgets/trade_detail.dart';
import '../widgets/lot_info.dart'; // Импортируем LotInfo

class TradesScreen extends StatefulWidget {
  final int initialOption;

  const TradesScreen({Key? key, this.initialOption = 1}) : super(key: key);

  @override
  _TradesScreenState createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen> {
  late int option;
  Map<String, dynamic> parameters = {};
  Map<String, dynamic>? selectedLot;

  @override
  void initState() {
    super.initState();
    option = widget.initialOption;
  }

  @override
  Widget build(BuildContext context) {
    switch (option) {
      case 1:
        return buildTradesOption();
      case 2:
        return buildParametersOption();
      case 3:
        return buildTradeDetailOption();
      default:
        return buildTradesOption();
    }
  }

  Widget buildTradesOption() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Header(text: 'Торги'),
          Expanded(
            child: TradesWidget(
              switchOption: switchOption,
              parameters: parameters,
              onImageTap: handleImageTap, // Передаём коллбек
            ),
          ),
        ],
      ),
    );
  }

  Widget buildParametersOption() {
    return ParamsWidget(
      switchOption: switchOption,
      onApply: (params) {
        setState(() {
          parameters = params;
        });
      },
      initialParams: parameters,
    );
  }

  Widget buildTradeDetailOption() {
    if (selectedLot == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Детали лота'),
        ),
        body: Center(
          child: Text('Данные о лоте отсутствуют.'),
        ),
      );
    }
    return TradeDetail(lot: selectedLot!);
  }

  void switchOption(int newOption, {Map<String, dynamic>? lotData}) {
    setState(() {
      option = newOption;
      if (newOption == 3 && lotData != null) {
        selectedLot = lotData;
      }
    });
  }

  /// Функция для обработки нажатия на изображение
  void handleImageTap(int lotId) {
    // Используем Navigator.push для перехода на LotInfo
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LotInfo(lotId: lotId),
      ),
    );
  }
}
