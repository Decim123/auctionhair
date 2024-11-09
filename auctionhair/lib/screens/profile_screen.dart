import 'package:flutter/material.dart';
import '../widgets/user_info.dart';
import '../widgets/header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Header(text: 'Профиль'),
          Expanded(
            child: Center(
              child: UserInfoWidget(),
            ),
          ),
        ],
      ),
    );
  }
}
