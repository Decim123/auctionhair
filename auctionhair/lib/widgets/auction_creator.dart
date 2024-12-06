// auction_creator.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:auctionhair/constants.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'wallet_ask.dart';
import 'photo_button.dart';
import 'package:get/get.dart';
import '../telegram_controller.dart';

class AuctionCreator extends StatefulWidget {
  final int tgId;
  final VoidCallback onAuctionCreated;

  const AuctionCreator({
    Key? key,
    required this.tgId,
    required this.onAuctionCreated,
  }) : super(key: key);

  @override
  _AuctionCreatorState createState() => _AuctionCreatorState();
}

class _AuctionCreatorState extends State<AuctionCreator> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController lengthController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController priceController = TextEditingController();

  String? naturalColor;
  String? currentColor;
  String? hairType;
  String? auctionDuration;

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
  final List<String> auctionDurations = ['1', '2', '3'];

  List<Map<String, dynamic>> attachedMedia = [];

  bool isFormValid = false;
  bool isAndroid = false;

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    lengthController.addListener(_validateForm);
    ageController.addListener(_validateForm);
    weightController.addListener(_validateForm);
    descriptionController.addListener(_validateForm);
    priceController.addListener(_validateForm);

    // Определяем, является ли платформа Android
    String userAgent = html.window.navigator.userAgent.toLowerCase();
    if (userAgent.contains('android')) {
      isAndroid = true;
    }
  }

  @override
  void dispose() {
    lengthController.dispose();
    ageController.dispose();
    weightController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      if (isAndroid) {
        isFormValid = _formKey.currentState?.validate() == true;
      } else {
        isFormValid = _formKey.currentState?.validate() == true &&
            attachedMedia.isNotEmpty;
      }
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

  String? _validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Обязательное поле';
    }
    if (num.tryParse(value) == null) {
      return 'Введите число';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Обязательное поле';
    }
    if (num.tryParse(value) == null) {
      return 'Введите число';
    }
    return null;
  }

  String? _validateDropdown(String? value) {
    if (value == null || value.isEmpty) {
      return 'Обязательное поле';
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
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        builder: (BuildContext context) {
          return WalletAsk(
            tgId: widget.tgId,
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
      Uri uri;
      if (isAndroid) {
        uri = Uri.parse('$BASE_API_URL/api/lot_without_img');
      } else {
        uri = Uri.parse('$BASE_API_URL/api/auction_create');
      }

      var request = http.MultipartRequest('POST', uri);

      request.fields['tg_id'] = widget.tgId.toString();
      request.fields['amount'] = amount;
      request.fields['length'] = lengthController.text;
      request.fields['age'] = ageController.text;
      request.fields['weight'] = weightController.text;
      request.fields['description'] = descriptionController.text;
      request.fields['price'] = priceController.text;
      request.fields['natural_color'] = naturalColor ?? '';
      request.fields['current_color'] = currentColor ?? '';
      request.fields['hair_type'] = hairType ?? '';
      request.fields['auction_duration'] = auctionDuration ?? '';

      if (!isAndroid && attachedMedia.isNotEmpty) {
        // Обрабатываем прикрепленные медиа
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

      if (response.statusCode == 200) {
        if (isAndroid) {
          // Сворачиваем мини-приложение
          TelegramController.closeWebApp();
        } else {
          widget.onAuctionCreated();
        }
      } else {
        setState(() {
          errorMessage = 'Ошибка сервера: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка при отправке данных на сервер';
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
                // Длина
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
                // Натуральный цвет
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
                      validator: _validateDropdown,
                    ),
                  ),
                ),
                // Текущий цвет
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
                      validator: _validateDropdown,
                    ),
                  ),
                ),
                // Тип
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
                      validator: _validateDropdown,
                    ),
                  ),
                ),
                // Возраст
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
                // Вес
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: TextFormField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Вес',
                        hintText: 'Введите вес (граммы)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      validator: _validateWeight,
                      onChanged: (value) {
                        _validateForm();
                      },
                    ),
                  ),
                ),
                // Свободное описание
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
                        hintText: 'Придумайте описание для своего лота',
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
                // Цена
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Выкупная цена',
                        hintText: 'Введите цену (₽)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      validator: _validatePrice,
                      onChanged: (value) {
                        _validateForm();
                      },
                    ),
                  ),
                ),
                // Срок аукциона
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Срок аукциона',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      value: auctionDuration,
                      items: auctionDurations.map((duration) {
                        return DropdownMenuItem<String>(
                          value: duration,
                          child: Text(duration),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          auctionDuration = value;
                          _validateForm();
                        });
                      },
                      validator: _validateDropdown,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Кнопка "Создать аукцион"
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
                  'Создать аукцион',
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
