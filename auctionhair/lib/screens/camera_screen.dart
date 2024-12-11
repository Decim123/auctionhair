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
  bool isPreviewing = false;
  html.CanvasElement? canvasElement;
  String? capturedImageDataUrl;

  @override
  void initState() {
    super.initState();
    print('Initializing CameraScreen');
    videoElement = html.VideoElement()
      ..autoplay = true
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.display = 'block'
      ..style.backgroundColor = 'black';

    ui.platformViewRegistry.registerViewFactory(
      'videoElement',
      (int viewId) => videoElement,
    );

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    print('Attempting to initialize camera');
    try {
      cameraStream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {
          'facingMode': {'exact': 'user'}
        }
      });

      if (cameraStream != null) {
        print('Camera stream obtained');
        videoElement.srcObject = cameraStream;
        videoElement.play().then((_) {
          print('Video stream playing');
        }).catchError((error) {
          print('Error playing video stream: $error');
        });
      } else {
        print('Failed to obtain camera stream');
      }
    } catch (e) {
      print('Exception during camera initialization: $e');
    }
  }

  void _capturePhoto() {
    print('Capturing photo');
    canvasElement = html.CanvasElement(
      width: videoElement.videoWidth,
      height: videoElement.videoHeight,
    );
    canvasElement!.context2D.drawImage(videoElement, 0, 0);
    capturedImageDataUrl = canvasElement!.toDataUrl('image/png');
    setState(() {
      isPreviewing = true;
    });
    print('Photo captured');
  }

  void _retakePhoto() {
    print('Retaking photo');
    setState(() {
      isPreviewing = false;
      capturedImageDataUrl = null;
    });
    // Ensure the video stream is playing again
    if (cameraStream != null) {
      videoElement.play().then((_) {
        print('Video stream resumed after retake');
      }).catchError((error) {
        print('Error resuming video stream: $error');
      });
    } else {
      print('Camera stream is null, reinitializing camera');
      _initializeCamera();
    }
  }

  void _acceptPhoto() {
    print('Accepting photo');
    Navigator.pop(context, capturedImageDataUrl);
    _stopCamera();
  }

  void _stopCamera() {
    print('Stopping camera');
    if (cameraStream != null) {
      for (var track in cameraStream!.getTracks()) {
        print('Stopping track: ${track.kind}');
        track.stop();
      }
      cameraStream = null;
    }
    videoElement.srcObject = null;
    print('Camera stopped');
  }

  @override
  void dispose() {
    print('Disposing CameraScreen');
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Building CameraScreen');
    return Scaffold(
      body: isPreviewing
          ? Stack(
              children: [
                Positioned.fill(
                  child: capturedImageDataUrl != null
                      ? Image.network(
                          capturedImageDataUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(),
                ),
                Positioned(
                  bottom: 30,
                  left: 50,
                  right: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: _retakePhoto,
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.red,
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _acceptPhoto,
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.green,
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: HtmlElementView(viewType: 'videoElement'),
                ),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _capturePhoto,
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white.withOpacity(0.7),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.black,
                          size: 35,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
