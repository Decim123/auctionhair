// photo_button.dart

import 'dart:html' as html;
import 'package:flutter/material.dart';

class PhotoButton extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onMediaSelected;
  final List<Map<String, dynamic>> attachedMedia;

  const PhotoButton({
    Key? key,
    required this.onMediaSelected,
    required this.attachedMedia,
  }) : super(key: key);

  @override
  _PhotoButtonState createState() => _PhotoButtonState();
}

class _PhotoButtonState extends State<PhotoButton> {
  List<Map<String, dynamic>> attachedMedia = [];
  String? errorMessage;
  bool isAndroid = false;

  @override
  void initState() {
    super.initState();
    attachedMedia = widget.attachedMedia;

    // Detect if the platform is Android
    String userAgent = html.window.navigator.userAgent.toLowerCase();
    if (userAgent.contains('android')) {
      isAndroid = true;
    }
  }

  void _pickMedia() {
    try {
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.multiple = true;
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          for (var file in files) {
            final reader = html.FileReader();

            reader.onLoadEnd.listen((e) {
              setState(() {
                attachedMedia.add({'file': file, 'dataUrl': reader.result});
                errorMessage = null;
                widget.onMediaSelected(attachedMedia);
              });
            });

            reader.readAsDataUrl(file);
          }
        } else {
          setState(() {
            errorMessage = 'Изображения не были выбраны';
          });
        }
      });

      uploadInput.onError.listen((e) {
        setState(() {
          errorMessage = 'Ошибка при выборе файлов';
        });
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Произошла ошибка при выборе файлов';
      });
    }
  }

  void _removeMedia(int index) {
    setState(() {
      attachedMedia.removeAt(index);
      widget.onMediaSelected(attachedMedia);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isAndroid) {
      // If platform is Android, display centered text
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Вы сможете прикрепить медиа позже, продолжайте создание',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    } else {
      // If platform is not Android, display the usual UI
      return Column(
        children: [
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: ElevatedButton(
                onPressed: _pickMedia,
                style: ElevatedButton.styleFrom(
                  primary: Color(0xFFECF2FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 20),
                ),
                child: Text(
                  attachedMedia.isNotEmpty
                      ? 'Прикрепить еще медиа'
                      : 'Прикрепить медиа',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF067DFF),
                  ),
                ),
              ),
            ),
          ),
          if (attachedMedia.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: attachedMedia.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var fileData = entry.value;
                  html.File file = fileData['file'];
                  String dataUrl = fileData['dataUrl'];
                  return Row(
                    children: [
                      Image.network(
                        dataUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.error);
                        },
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          file.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey),
                        onPressed: () => _removeMedia(idx),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      );
    }
  }
}
