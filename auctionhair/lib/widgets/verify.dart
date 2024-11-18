import 'dart:typed_data'; // Для работы с байтами
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../telegram_controller.dart';
import 'package:http_parser/http_parser.dart';

class VerifyWidget extends StatefulWidget {
  @override
  _VerifyWidgetState createState() => _VerifyWidgetState();
}

class _VerifyWidgetState extends State<VerifyWidget> {
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _patronymicController = TextEditingController();

  bool _isButtonEnabled = false;
  XFile? _selectedImage; // Изменено на XFile
  int? _tgId;
  bool _isSubmitted = false;
  Uint8List? _imageBytes; // Для хранения байтов изображения

  final TelegramController _telegramController = Get.put(TelegramController());

  @override
  void initState() {
    super.initState();
    _surnameController.addListener(_validateForm);
    _nameController.addListener(_validateForm);
    _patronymicController.addListener(_validateForm);
    _getTelegramId();
  }

  void _getTelegramId() async {
    // Ждем, пока TelegramController получит данные
    await Future.delayed(Duration(milliseconds: 500));
    setState(() {
      _tgId = _telegramController.userId;
    });
  }

  void _validateForm() {
    setState(() {
      _isButtonEnabled = _surnameController.text.isNotEmpty &&
          _nameController.text.isNotEmpty &&
          _patronymicController.text.isNotEmpty &&
          _selectedImage != null;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _imageBytes = bytes;
      });
      _validateForm();
    }
  }

  Future<void> _submitData() async {
    if (_tgId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Telegram ID не получен')),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Изображение не выбрано')),
      );
      return;
    }

    try {
      var uri = Uri.parse(
          'https://1149-91-188-188-116.ngrok-free.app/api/verify_try');

      var request = http.MultipartRequest('POST', uri)
        ..fields['tg_id'] = _tgId.toString()
        ..fields['name_1'] = _surnameController.text
        ..fields['name_2'] = _nameController.text
        ..fields['name_3'] = _patronymicController.text;

      // Добавляем файл изображения
      var multipartFile = http.MultipartFile.fromBytes(
        'image',
        _imageBytes!,
        filename: 'verify_image.jpg',
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      print('Отправка данных на сервер:');
      print('tg_id: ${_tgId.toString()}');
      print('name_1: ${_surnameController.text}');
      print('name_2: ${_nameController.text}');
      print('name_3: ${_patronymicController.text}');
      print('image name: ${_selectedImage!.name}');

      var streamedResponse = await request.send();

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        setState(() {
          _isSubmitted = true; // Помечаем, что данные отправлены
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при отправке данных')),
        );
        // Выводим тело ответа для отладки
        print('Ошибка: ${response.statusCode}');
        print('Тело ответа: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Произошла ошибка: $e')),
      );
      print('Исключение при отправке данных: $e');
    }
  }

  @override
  void dispose() {
    _surnameController.dispose();
    _nameController.dispose();
    _patronymicController.dispose();
    super.dispose();
  }

  Widget _buildInputField(
      String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(32.0),
          ),
          labelStyle: TextStyle(
            backgroundColor: Colors.white,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmittedContent() {
    final double blockWidth = MediaQuery.of(context).size.width * 0.9;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ваши данные на рассмотрении',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            // Фото пользователя
            Container(
              width: blockWidth * 0.4, // 40% ширины экрана
              height: blockWidth * 0.4, // Высота подстраивается
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: _imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _imageBytes!,
                        width: blockWidth * 0.4,
                        height: blockWidth * 0.4,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.camera_alt,
                      size: 40,
                      color: Colors.grey[700],
                    ),
            ),
            SizedBox(width: 16),
            // Информация о пользователе
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Фамилия', _surnameController.text),
                _buildInfoRow('Имя', _nameController.text),
                _buildInfoRow('Отчество', _patronymicController.text),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double blockWidth = MediaQuery.of(context).size.width * 0.9;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _isSubmitted
          ? _buildSubmittedContent()
          : Column(
              children: [
                Text(
                  'Ваше ФИО',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                _buildInputField(
                    'Фамилия', 'Введите вашу фамилию', _surnameController),
                _buildInputField('Имя', 'Введите ваше имя', _nameController),
                _buildInputField(
                    'Отчество', 'Введите ваше отчество', _patronymicController),
                SizedBox(height: 16),
                Text(
                  'Документ, подтверждающий вашу личность',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Вам нужно сделать фото с паспортом/СНИЛСом так, чтобы ваше лицо было чётко видно',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: blockWidth,
                    height: 200, // Увеличиваем высоту
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _imageBytes!,
                              width: blockWidth,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.grey[700],
                          ),
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: blockWidth,
                  child: ElevatedButton(
                    onPressed: _isButtonEnabled ? _submitData : null,
                    style: ElevatedButton.styleFrom(
                      primary: _isButtonEnabled ? Colors.blue : Colors.grey,
                      onPrimary:
                          _isButtonEnabled ? Colors.white : Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Отправить'),
                  ),
                ),
              ],
            ),
    );
  }
}
