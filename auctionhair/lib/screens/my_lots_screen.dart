// my_lots_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/header.dart';
import '../telegram_controller.dart';
import '../widgets/lots.dart';
import '../widgets/lots_verify.dart';
import '../widgets/auctions.dart';
import '../constants.dart';
import '../widgets/auction_creator.dart';
import '../widgets/lot_info.dart';
import '../widgets/asks.dart';
import '../widgets/asks_creator.dart';

class MyLotsScreen extends StatefulWidget {
  final VoidCallback onProceedVerification;

  const MyLotsScreen({Key? key, required this.onProceedVerification})
      : super(key: key);

  @override
  _MyLotsScreenState createState() => _MyLotsScreenState();
}

class _MyLotsScreenState extends State<MyLotsScreen> {
  bool isLoading = true;
  String verificationMessage = '';
  int? userId;
  int option = 1;
  Map<String, dynamic>? selectedLotData;

  @override
  void initState() {
    super.initState();
    TelegramController telegramController = Get.find<TelegramController>();
    userId = telegramController.userId;
    fetchVerificationStatus();
  }

  Future<void> fetchVerificationStatus() async {
    if (userId != null) {
      try {
        var response = await http.post(
          Uri.parse('$BASE_API_URL/api/info'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'tg_id': userId,
            'fields': ['verify', 'city']
          }),
        );

        if (response.statusCode == 200) {
          var data = jsonDecode(utf8.decode(response.bodyBytes));
          String city = data['city'];
          var verify = data['verify'];
          setState(() {
            if (city != 'Не указан') {
              if (verify == 1 || verify == true) {
                verificationMessage = 'Верификация пройдена';
                option = 1;
              } else if (verify == 0) {
                verificationMessage =
                    'Необходимо пройти верификацию для размещения лотов';
                option = 2;
              } else if (verify == 2) {
                verificationMessage = 'Ваши данные проверяются';
                option = 3;
              } else {
                verificationMessage = 'Неизвестный статус верификации';
                option = 5;
              }
            } else {
              verificationMessage = 'Выберите город в профиле';
              option = 4;
            }
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : buildOption(),
    );
  }

  Widget buildOption() {
    switch (option) {
      case 1:
        return buildOption1();
      case 2:
        return buildOption2();
      case 3:
        return buildOption3();
      case 4:
        return buildOption4();
      case 5:
        return buildOption5();
      case 6:
        return buildOption6();
      case 7:
        return buildOption7();
      case 8:
        return buildOption8();
      default:
        return buildOption1();
    }
  }

  Widget buildOption1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Header(text: 'Мои лоты'),
        Expanded(
          child: Lots(
            onFirstButtonPressed: () {
              setState(() {
                option = 4;
              });
            },
            onSecondButtonPressed: () {
              setState(() {
                option = 5;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget buildOption2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Header(text: 'Мои лоты'),
        Expanded(
          child: LotsVerify(
            verificationMessage: verificationMessage,
            onProceedVerification: widget.onProceedVerification,
          ),
        ),
      ],
    );
  }

  Widget buildOption3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Header(text: 'Мои лоты'),
        Expanded(
          child: Center(
            child: Text(verificationMessage),
          ),
        ),
      ],
    );
  }

  Widget buildOption4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Header(text: 'Мои лоты / Запросы предложений'),
        Expanded(
          child: Asks(
            onCreateAsk: () {
              setState(() {
                option = 8;
              });
            },
            onLotSelected: (lotData) {
              setState(() {
                selectedLotData = lotData;
                option = 7;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget buildOption5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Header(text: 'Мои лоты / Аукционы'),
        Expanded(
          child: Auctions(
            onCreateAuction: () {
              setState(() {
                option = 6;
              });
            },
            onLotSelected: (lotData) {
              setState(() {
                selectedLotData = lotData;
                option = 7;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget buildOption6() {
    if (userId == null) {
      return Center(child: Text('User ID not available'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Header(text: 'Мои лоты / Создать аукцион'),
        Expanded(
          child: AuctionCreator(
            tgId: userId!,
            onAuctionCreated: () {
              setState(() {
                option = 5;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget buildOption7() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Header(text: 'Мои лоты / Аукционы / Информация о аукционе'),
        Expanded(
          child: LotInfo(
            lotId: selectedLotData!['id'],
          ),
        ),
      ],
    );
  }

  Widget buildOption8() {
    if (userId == null) {
      return Center(child: Text('User ID not available'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Header(text: 'Мои лоты / Создать запрос предложений'),
        Expanded(
          child: AsksCreator(
            onAskCreated: (data) {
              setState(() {
                option = 4;
              });
            },
          ),
        ),
      ],
    );
  }
}
