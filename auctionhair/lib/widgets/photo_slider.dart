// photo_slider.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import 'gallery_photo_view_wrapper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'dart:ui' as ui;

class PhotoSlider extends StatefulWidget {
  final int id;

  const PhotoSlider({Key? key, required this.id}) : super(key: key);

  @override
  _PhotoSliderState createState() => _PhotoSliderState();
}

class _PhotoSliderState extends State<PhotoSlider> {
  List<String> photoFilenames = [];
  bool isLoading = true;
  String? errorMessage;
  int _currentIndex = 0;
  List<String> imageUrls = [];
  late PageController _pageController;
  int lot_type = 0;
  List<String> videoViewIds = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    fetchAuctionPhotos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> fetchAuctionPhotos() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    int id = widget.id;
    try {
      var url = Uri.parse('$BASE_API_URL/api/get_auction_photo?id=$id');
      var response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded.isNotEmpty) {
          lot_type = 0;
          photoFilenames = decoded.cast<String>();
          imageUrls = photoFilenames
              .map((filename) =>
                  '$BASE_API_URL/static/img/lots/auctions/$filename')
              .toList();
        } else {
          var askUrl = Uri.parse('$BASE_API_URL/api/get_asks_media?id=$id');
          var askResponse = await http.get(askUrl);
          if (askResponse.statusCode == 200) {
            List<dynamic> askDecoded =
                jsonDecode(utf8.decode(askResponse.bodyBytes));
            if (askDecoded.isNotEmpty) {
              lot_type = 1;
              photoFilenames = askDecoded.cast<String>();
              imageUrls = photoFilenames
                  .map((filename) =>
                      '$BASE_API_URL/static/img/lots/asks/$filename')
                  .toList();
            } else {
              setState(() {
                errorMessage = 'Фотографии отсутствуют.';
                isLoading = false;
              });
              return;
            }
          } else {
            setState(() {
              errorMessage =
                  'Не удалось загрузить фотографии. Код ошибки: ${askResponse.statusCode}';
              isLoading = false;
            });
            return;
          }
        }
        for (int i = 0; i < imageUrls.length; i++) {
          String url = imageUrls[i];
          if (url.toLowerCase().endsWith('.mp4') && kIsWeb) {
            final String viewId = 'video_$i';
            videoViewIds.add(viewId);
            ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
              final videoElement = html.VideoElement()
                ..src = url
                ..autoplay = true
                ..loop = true
                ..controls = false
                ..style.border = 'none';
              return videoElement;
            });
          }
        }
        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Не удалось загрузить фотографии. Код ошибки: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка при загрузке фотографий: $e';
        isLoading = false;
      });
    }
  }

  void _openGallery(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryPhotoViewWrapper(
          galleryItems: imageUrls,
          initialIndex: initialIndex,
          imageNames: photoFilenames,
        ),
      ),
    );
  }

  void _navigateToPage(int index) {
    if (index >= 0 && index < imageUrls.length) {
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double sliderHeight = MediaQuery.of(context).size.height * 0.6;
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: TextStyle(fontSize: 16, color: Colors.red),
        ),
      );
    } else if (photoFilenames.isEmpty) {
      return Center(child: Text('Фотографии отсутствуют.'));
    } else {
      return Container(
        width: double.infinity,
        height: sliderHeight,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => _openGallery(context, _currentIndex),
              child: PageView.builder(
                itemCount: imageUrls.length,
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  String url = imageUrls[index];
                  if (url.toLowerCase().endsWith('.mp4') && kIsWeb) {
                    final String viewId = 'video_$index';
                    return HtmlElementView(viewType: viewId);
                  } else if (url.toLowerCase().endsWith('.mp4')) {
                    return Container();
                  } else {
                    return Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(child: Icon(Icons.error));
                      },
                    );
                  }
                },
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () {
                  if (_currentIndex > 0) {
                    setState(() {
                      _currentIndex--;
                    });
                    _navigateToPage(_currentIndex);
                  }
                },
                child: Container(
                  width: 50,
                  color: Colors.transparent,
                  child: Center(
                    child: Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () {
                  if (_currentIndex < imageUrls.length - 1) {
                    setState(() {
                      _currentIndex++;
                    });
                    _navigateToPage(_currentIndex);
                  }
                },
                child: Container(
                  width: 50,
                  color: Colors.transparent,
                  child: Center(
                    child: Icon(Icons.arrow_forward_ios, color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: MediaQuery.of(context).size.width / 2 - 30,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(236, 242, 255, 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_currentIndex + 1}/${imageUrls.length}',
                  style: TextStyle(
                    color: Color.fromRGBO(0, 122, 255, 1),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
