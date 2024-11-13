import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/trades_screen.dart';
import '../screens/my_lots_screen.dart';
import '../screens/chats_screen.dart';
import '../screens/wallet_screen.dart';
import '../screens/profile_screen.dart';

class NavBar extends StatefulWidget {
  const NavBar({Key? key}) : super(key: key);

  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _selectedIndex = 0;
  int profileInitialOption = 1; // Добавлено: для хранения initialOption

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Сбрасываем profileInitialOption при переключении на другой экран
      if (index != 4) {
        profileInitialOption = 1;
      }
    });
  }

  // Обновляем метод для построения текущего экрана
  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return TradesScreen();
      case 1:
        return MyLotsScreen(
          onProceedVerification: () {
            setState(() {
              _selectedIndex = 4; // Переключаемся на ProfileScreen
              profileInitialOption = 5; // Устанавливаем опцию 5
            });
          },
        );
      case 2:
        return ChatsScreen();
      case 3:
        return WalletScreen();
      case 4:
        return ProfileScreen(initialOption: profileInitialOption);
      default:
        return TradesScreen();
    }
  }

  Widget _buildIcon(String activeIconPath, String inactiveIconPath, int index) {
    return SvgPicture.asset(
      _selectedIndex == index ? activeIconPath : inactiveIconPath,
      height: 32,
      width: 32,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: SizedBox(
        height: 80,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFFFFFFF), // Устанавливаем белый фон
          items: [
            BottomNavigationBarItem(
              icon: _buildIcon('assets/icons/trades_active.svg',
                  'assets/icons/trades.svg', 0),
              label: 'Торги',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(
                  'assets/icons/lots_active.svg', 'assets/icons/lots.svg', 1),
              label: 'Мои лоты',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(
                  'assets/icons/chats_active.svg', 'assets/icons/chats.svg', 2),
              label: 'Чаты',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon('assets/icons/wallet_active.svg',
                  'assets/icons/wallet.svg', 3),
              label: 'Кошелек',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/vite.svg',
                height: 32,
                width: 32,
              ),
              label: 'Профиль',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedLabelStyle: const TextStyle(fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          selectedFontSize: 14,
          unselectedFontSize: 14,
        ),
      ),
    );
  }
}
