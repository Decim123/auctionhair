import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

// Импортируем необходимые пакеты только для веб-платформы
// Игнорируйте предупреждение об ошибке импорта на мобильных платформах
import 'dart:html' as html;
import 'dart:ui' as ui;

class AttachFilesWidget extends StatefulWidget {
  const AttachFilesWidget({Key? key}) : super(key: key);

  @override
  _AttachFilesWidgetState createState() => _AttachFilesWidgetState();
}

class _AttachFilesWidgetState extends State<AttachFilesWidget> {
  List<Uint8List> _images = [];
  List<Widget> _videoWidgets = [];
  String? _errorMessage;

  Future<void> _pickImages() async {
    try {
      // Открываем диалог выбора изображений
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: true, // Важно для получения данных файла
      );

      if (result != null) {
        // Получаем байты изображений
        List<Uint8List> images = result.files
            .where((file) => file.bytes != null)
            .map((file) => file.bytes!)
            .toList();

        setState(() {
          _images = images;
          _errorMessage = null;
        });
      } else {
        // Пользователь отменил выбор
        setState(() {
          _errorMessage = 'Вы не выбрали изображения.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Произошла ошибка при выборе изображений: $e';
      });
    }
  }

  Future<void> _pickVideos() async {
    try {
      // Открываем диалог выбора видео
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.video,
        withReadStream: true, // Важно для веб-платформы
      );

      if (result != null) {
        List<Widget> videoWidgets = [];
        for (var file in result.files) {
          if (kIsWeb && file.readStream != null) {
            // Читаем данные файла из потока
            List<int> bytes = [];
            await for (var data in file.readStream!) {
              bytes.addAll(data);
            }
            final blob = html.Blob([bytes]);
            final url = html.Url.createObjectUrlFromBlob(blob);

            // Создаем уникальный идентификатор для каждого видео
            String viewType =
                'video_${file.name}_${DateTime.now().millisecondsSinceEpoch}';

            // Регистрируем фабрику представления
            // Игнорируем предупреждение, если оно появляется
            ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
              final videoElement = html.VideoElement()
                ..src = url
                ..controls = true
                ..style.width = '100%'
                ..style.height = 'auto';
              return videoElement;
            });

            // Создаем HtmlElementView для отображения видео
            videoWidgets.add(Container(
              height: 200,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: HtmlElementView(viewType: viewType),
            ));
          } else {
            // Если это не веб или поток недоступен, обработайте по необходимости
            setState(() {
              _errorMessage = 'Не удалось загрузить видео: ${file.name}';
            });
          }
        }

        setState(() {
          _videoWidgets = videoWidgets;
          _errorMessage = null;
        });
      } else {
        // Пользователь отменил выбор
        setState(() {
          _errorMessage = 'Вы не выбрали видео.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Произошла ошибка при выборе видео: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Кнопка для выбора изображений
        ElevatedButton(
          onPressed: _pickImages,
          child: const Text('Прикрепить изображения'),
        ),
        // Кнопка для выбора видео
        ElevatedButton(
          onPressed: _pickVideos,
          child: const Text('Прикрепить видео'),
        ),
        const SizedBox(height: 10),
        // Отображение сообщений об ошибках
        if (_errorMessage != null)
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        // Отображение изображений
        if (_images.isNotEmpty)
          Expanded(
            child: GridView.builder(
              itemCount: _images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Настройте по вашему желанию
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                return Image.memory(
                  _images[index],
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
        // Отображение видео
        if (_videoWidgets.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: _videoWidgets.length,
              itemBuilder: (context, index) {
                return _videoWidgets[index];
              },
            ),
          ),
        // Сообщение, если ничего не выбрано
        if (_images.isEmpty && _videoWidgets.isEmpty && _errorMessage == null)
          const Expanded(
            child: Center(
              child: Text('Нет выбранных файлов'),
            ),
          ),
      ],
    );
  }
}
