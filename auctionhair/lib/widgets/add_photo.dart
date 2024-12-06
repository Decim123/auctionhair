import 'package:flutter/material.dart';
import 'package:js/js.dart';
import 'dart:js_util';

@JS('selectImages')
external dynamic _selectImages();

class AddPhotoWidget extends StatefulWidget {
  const AddPhotoWidget({Key? key}) : super(key: key);

  @override
  _AddPhotoWidgetState createState() => _AddPhotoWidgetState();
}

class _AddPhotoWidgetState extends State<AddPhotoWidget> {
  List<Image> _images = [];
  String? _errorMessage;

  Future<void> _pickImages() async {
    try {
      final result = await promiseToFuture(_selectImages());
      if (result != null && result is List) {
        List<Image> images = [];
        for (var item in result) {
          // Используем getProperty для доступа к свойствам JavaScript-объекта
          String dataUrl = getProperty<String>(item, 'data');
          images.add(Image.network(dataUrl));
        }
        setState(() {
          _images = images;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Вы не выбрали изображения.';
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
          onPressed: _pickImages,
          child: const Text('Прикрепить изображения'),
        ),
        const SizedBox(height: 10),
        if (_errorMessage != null)
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        if (_images.isEmpty && _errorMessage == null)
          const Text('Нет выбранных изображений.'),
        if (_images.isNotEmpty)
          Expanded(
            child: GridView.builder(
              itemCount: _images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Количество столбцов
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                return _images[index];
              },
            ),
          ),
      ],
    );
  }
}
