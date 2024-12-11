// photo_video_button.dart

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

    String userAgent = html.window.navigator.userAgent.toLowerCase();
    if (userAgent.contains('android')) {
      isAndroid = true;
    }
  }

  void _pickMedia() {
    try {
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.multiple = true;
      uploadInput.accept = 'image/*,video/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          for (var file in files) {
            final reader = html.FileReader();

            reader.onLoadEnd.listen((e) {
              String fileType =
                  file.type.startsWith('video') ? 'video' : 'image';
              setState(() {
                attachedMedia.add({
                  'file': file,
                  'dataUrl': reader.result,
                  'type': fileType,
                });
                errorMessage = null;
                widget.onMediaSelected(attachedMedia);
              });
            });

            reader.readAsDataUrl(file);
          }
        } else {
          setState(() {
            errorMessage = 'Изображения или видео не были выбраны';
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

  Widget _buildMediaPreview(Map<String, dynamic> media) {
    String type = media['type'];
    String dataUrl = media['dataUrl'];
    html.File file = media['file'];

    if (type == 'image') {
      return Image.network(
        dataUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.error);
        },
      );
    } else if (type == 'video') {
      return Stack(
        children: [
          Container(
            width: 50,
            height: 50,
            color: Colors.black12,
            child: Icon(
              Icons.videocam,
              color: Colors.grey,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white70,
              size: 20,
            ),
          ),
        ],
      );
    } else {
      return Icon(Icons.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isAndroid) {
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
                  String type = fileData['type'];
                  return Row(
                    children: [
                      _buildMediaPreview(fileData),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileData['file'].name,
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
