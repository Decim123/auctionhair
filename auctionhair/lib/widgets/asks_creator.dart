// asks_creator.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:get/get.dart';
import '../constants.dart';
import 'photo_video_button.dart';
import '../telegram_controller.dart';
import 'wallet_ask.dart';

class AsksCreator extends StatefulWidget {
  final Function(Map<String, dynamic> askData) onAskCreated;

  const AsksCreator({Key? key, required this.onAskCreated}) : super(key: key);

  @override
  _AsksCreatorState createState() => _AsksCreatorState();
}

class _AsksCreatorState extends State<AsksCreator> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController lengthController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  String? naturalColor;
  String? currentColor;
  String? hairType;

  final List<String> colors = [
    'Брюнет',
    'Шатен',
    'Рыжий',
    'Русый',
    'Блондин',
    'Седой'
  ];
  final List<String> hairTypes = [
    'Прямые',
    'Вьющиеся',
    'Волнистые',
    'Мелкие кудри'
  ];

  List<Map<String, dynamic>> attachedMedia = [];

  bool isFormValid = false;

  String? errorMessage;

  late TelegramController telegramController;
  int? tgId;

  @override
  void initState() {
    super.initState();
    telegramController = Get.find<TelegramController>();
    tgId = telegramController.userId;
    lengthController.addListener(_validateForm);
    ageController.addListener(_validateForm);
    descriptionController.addListener(_validateForm);
  }

  @override
  void dispose() {
    lengthController.dispose();
    ageController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      isFormValid = _formKey.currentState?.validate() == true &&
          naturalColor != null &&
          currentColor != null &&
          hairType != null &&
          attachedMedia.isNotEmpty;
    });
  }

  String? _validateLength(String? value) {
    if (value == null || value.isEmpty) {
      return 'Обязательное поле';
    }
    final num? length = num.tryParse(value);
    if (length == null || length < 35 || length > 150) {
      return 'Введите число от 35 до 150';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Обязательное поле';
    }
    final num? age = num.tryParse(value);
    if (age == null || age < 6 || age > 75) {
      return 'Введите число от 6 до 75';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Обязательное поле';
    }
    return null;
  }

  void _submitForm() {
    if (isFormValid) {
      setState(() {
        errorMessage = null;
      });
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        builder: (BuildContext context) {
          return WalletAsk(
            tgId: tgId!,
            onConfirm: (amount) {
              _sendDataToServer(amount);
            },
          );
        },
      );
    } else {
      setState(() {
        errorMessage = 'Форма не валидна';
      });
    }
  }

  void _sendDataToServer(String amount) async {
    try {
      Uri uri = Uri.parse('$BASE_API_URL/api/ask_create');
      var request = http.MultipartRequest('POST', uri);

      request.fields['tg_id'] = tgId.toString();
      request.fields['amount'] = amount;
      request.fields['length'] = lengthController.text;
      request.fields['age'] = ageController.text;
      request.fields['description'] = descriptionController.text;
      request.fields['natural_color'] = naturalColor ?? '';
      request.fields['current_color'] = currentColor ?? '';
      request.fields['hair_type'] = hairType ?? '';

      if (attachedMedia.isNotEmpty) {
        List<Future> fileReadFutures = [];

        for (var fileData in attachedMedia) {
          html.File file = fileData['file'];
          var reader = html.FileReader();

          var completer = Completer<void>();

          reader.onLoadEnd.listen((e) {
            var data = reader.result as Uint8List;
            request.files.add(
              http.MultipartFile.fromBytes(
                'images',
                data,
                filename: file.name,
              ),
            );
            completer.complete();
          });

          reader.onError.listen((e) {
            setState(() {
              errorMessage = 'Ошибка при чтении файла: ${file.name}';
            });
            completer.completeError(e);
          });

          reader.readAsArrayBuffer(file);
          fileReadFutures.add(completer.future);
        }

        await Future.wait(fileReadFutures);
      }

      var response = await request.send();

      if (response.statusCode == 201) {
        var responseData = await http.Response.fromStream(response);
        var data = jsonDecode(utf8.decode(responseData.bodyBytes));
        widget.onAskCreated(data);
        Navigator.of(context).pop();
      } else {
        setState(() {
          errorMessage = 'Ошибка создания запроса: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка подключения: $e';
      });
    }
  }

  void _onMediaSelected(List<Map<String, dynamic>> media) {
    setState(() {
      attachedMedia = media;
      _validateForm();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ),
          PhotoButton(
            onMediaSelected: _onMediaSelected,
            attachedMedia: attachedMedia,
          ),
          SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: TextFormField(
                      controller: lengthController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Длина',
                        hintText: 'Введите длину (см)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      validator: _validateLength,
                      onChanged: (value) {
                        _validateForm();
                      },
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Натуральный цвет',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      value: naturalColor,
                      items: colors.map((color) {
                        return DropdownMenuItem<String>(
                          value: color,
                          child: Text(color),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          naturalColor = value;
                          _validateForm();
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Выберите категорию';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Текущий цвет',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      value: currentColor,
                      items: colors.map((color) {
                        return DropdownMenuItem<String>(
                          value: color,
                          child: Text(color),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          currentColor = value;
                          _validateForm();
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Выберите категорию';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Тип',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      value: hairType,
                      items: hairTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          hairType = value;
                          _validateForm();
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Выберите категорию';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: TextFormField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Возраст донора',
                        hintText: 'Введите возраст',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      validator: _validateAge,
                      onChanged: (value) {
                        _validateForm();
                      },
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: TextFormField(
                      controller: descriptionController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        labelText: 'Свободное описание',
                        hintText: 'Придумайте описание для своего запроса',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      validator: _validateDescription,
                      onChanged: (value) {
                        _validateForm();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: ElevatedButton(
                onPressed: isFormValid ? _submitForm : null,
                style: ElevatedButton.styleFrom(
                  primary: isFormValid ? Color(0xFF007AFF) : Color(0xFFF5F5F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 20),
                ),
                child: Text(
                  'Создать запрос',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isFormValid ? Colors.white : Color(0xFFBAC1C4),
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
