import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late html.VideoElement videoElement;
  html.MediaStream? cameraStream;
  String debugMessage = 'Инициализация...';

  @override
  void initState() {
    super.initState();
    videoElement = html.VideoElement()
      ..autoplay = true
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.display = 'block'
      ..style.backgroundColor = 'black';

    ui.platformViewRegistry
        .registerViewFactory('videoElement', (int viewId) => videoElement);

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      debugMessage = 'Запрашиваем доступ к камере...';
    });

    try {
      // Запрашиваем доступ к задней камере
      cameraStream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {
          'facingMode': {'exact': 'environment'}
        }
      });

      if (cameraStream != null) {
        setState(() {
          debugMessage =
              'Доступ к камере получен. Инициализация видеопотока...';
        });

        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) {
            videoElement.srcObject = cameraStream;
            videoElement.play().catchError((error) {
              setState(() {
                debugMessage = 'Ошибка воспроизведения: $error';
              });
            });
            setState(() {
              debugMessage = 'Видео поток привязан и воспроизводится.';
            });
          }
        });
      } else {
        setState(() {
          debugMessage = 'Ошибка: Не удалось получить доступ к камере';
        });
      }
    } catch (e) {
      setState(() {
        debugMessage = 'Ошибка доступа к камере: $e';
      });
    }
  }

  void _stopCamera() {
    if (cameraStream != null) {
      cameraStream?.getTracks().forEach((track) => track.stop());
      cameraStream = null;
    }
    videoElement.srcObject = null;
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Камера'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            debugMessage,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: HtmlElementView(viewType: 'videoElement'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _stopCamera();
              Navigator.pop(context);
            },
            child: const Text('Закрыть камеру'),
          ),
        ],
      ),
    );
  }
}
