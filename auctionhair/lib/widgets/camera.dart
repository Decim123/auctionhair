import 'package:flutter/material.dart';
import '../screens/camera_screen.dart';

class CameraButton extends StatelessWidget {
  final String userID;

  const CameraButton({Key? key, required this.userID}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CameraScreen(name: userID),
          ),
        );
      },
      child: const Text('Открыть камеру'),
    );
  }
}
