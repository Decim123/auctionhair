// camera_screen.dart

import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  final String name;

  const CameraScreen({Key? key, required this.name}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late html.VideoElement videoElement;
  html.MediaStream? cameraStream;
  String debugMessage = 'Инициализация...';
  bool isPreviewing = false;
  html.CanvasElement? canvasElement;
  String? capturedImageDataUrl;

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

  void _capturePhoto() {
    canvasElement = html.CanvasElement(
        width: videoElement.videoWidth, height: videoElement.videoHeight);
    canvasElement!.context2D.drawImage(videoElement, 0, 0);
    capturedImageDataUrl = canvasElement!.toDataUrl('image/png');
    setState(() {
      isPreviewing = true;
    });
  }

  void _retakePhoto() {
    setState(() {
      isPreviewing = false;
      capturedImageDataUrl = null;
    });
  }

  void _acceptPhoto() {
    Navigator.pop(context, capturedImageDataUrl);
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
        title: Text('Камера - ${widget.name}'),
      ),
      body: isPreviewing
          ? Column(
              children: [
                Expanded(
                  child: capturedImageDataUrl != null
                      ? Image.network(capturedImageDataUrl!)
                      : Container(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _retakePhoto,
                      child: Text('Сделать другое фото'),
                    ),
                    ElevatedButton(
                      onPressed: _acceptPhoto,
                      child: Text('Сохранить фото'),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                Text(
                  debugMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                Expanded(
                  child: HtmlElementView(viewType: 'videoElement'),
                ),
                ElevatedButton(
                  onPressed: _capturePhoto,
                  child: Text('Сделать фото'),
                ),
              ],
            ),
    );
  }
}
