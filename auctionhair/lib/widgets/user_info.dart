import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../telegram_controller.dart';
import 'dart:convert';

class UserInfoWidget extends StatefulWidget {
  const UserInfoWidget({Key? key}) : super(key: key);

  @override
  _UserInfoWidgetState createState() => _UserInfoWidgetState();
}

class _UserInfoWidgetState extends State<UserInfoWidget> {
  String? userName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    TelegramController telegramController = Get.find<TelegramController>();
    int? userId = telegramController.userId;

    if (userId != null) {
      var response = await http.post(
        Uri.parse('https://fc87-176-59-162-192.ngrok-free.app/user_info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tg_id': userId, 'function': 'username'}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          userName = data['username'];
          isLoading = false;
        });
      } else {
        setState(() {
          userName = 'Error: ${response.reasonPhrase}';
          isLoading = false;
        });
      }
    } else {
      setState(() {
        userName = 'User ID not available';
        isLoading = false;
      });
    }
  }

  void _showNicknameInput() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        String newNickname = '';
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Введите новый никнейм'),
                onChanged: (value) {
                  newNickname = value;
                },
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Handle nickname change action here
                  Navigator.of(context).pop();
                },
                child: Text('Сохранить'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // User Photo with Blue Plus Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      // TODO: Implement photo change functionality
                    },
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: AssetImage('icons/user.png'),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Implement photo change functionality
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                        ),
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Username
              Text(
                userName ?? 'Unknown User',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              // Change Nickname Text
              GestureDetector(
                onTap: _showNicknameInput,
                child: Text(
                  'Изменить никнейм',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          );
  }
}
