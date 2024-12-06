import 'package:flutter/material.dart';
import 'package:js/js.dart';
import 'dart:js_util';
import 'dart:html' as html;
import 'dart:ui' as ui;

@JS('selectImagesAndVideos')
external dynamic _selectImagesAndVideos();

class AddPhotoVideoWidget extends StatefulWidget {
  const AddPhotoVideoWidget({Key? key}) : super(key: key);

  @override
  _AddPhotoVideoWidgetState createState() => _AddPhotoVideoWidgetState();
}

class _AddPhotoVideoWidgetState extends State<AddPhotoVideoWidget> {
  List<Widget> _mediaWidgets = [];
  String? _errorMessage;

  Future<void> _pickMedia() async {
    try {
      final result = await promiseToFuture(_selectImagesAndVideos());
      if (result != null && result is List) {
        List<Widget> mediaWidgets = [];
        for (var item in result) {
          String dataUrl = getProperty<String>(item, 'data');
          String type = getProperty<String>(item, 'type');
          String name = getProperty<String>(item, 'name');

          if (type.startsWith('image/')) {
            mediaWidgets.add(Image.network(dataUrl));
          } else if (type.startsWith('video/')) {
            final uid =
                'video_${name}_${DateTime.now().millisecondsSinceEpoch}';

            final videoElement = html.VideoElement()
              ..src = dataUrl
              ..controls = true
              ..style.width = '100%'
              ..style.height = 'auto';

            // Регистрируем view factory
            ui.platformViewRegistry.registerViewFactory(
              uid,
              (int viewId) => videoElement,
            );

            final videoWidget = HtmlElementView(viewType: uid);

            mediaWidgets.add(Container(
              width: double.infinity,
              height: 200,
              child: videoWidget,
            ));
          }
        }
        setState(() {
          _mediaWidgets = mediaWidgets;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Вы не выбрали файлы.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Произошла ошибка: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _pickMedia,
          child: const Text('Прикрепить изображения и видео'),
        ),
        const SizedBox(height: 10),
        if (_errorMessage != null)
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        if (_mediaWidgets.isEmpty && _errorMessage == null)
          const Text('Нет выбранных файлов.'),
        if (_mediaWidgets.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: _mediaWidgets.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: _mediaWidgets[index],
                );
              },
            ),
          ),
      ],
    );
  }
}
