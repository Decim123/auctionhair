import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import 'package:get/get.dart';
import 'dart:html' as html;
import 'dart:ui' as ui;

class PhotoSlider extends StatefulWidget {
  final int id;
  final Function(int) onImageTap;

  const PhotoSlider({Key? key, required this.id, required this.onImageTap})
      : super(key: key);

  @override
  _PhotoSliderState createState() => _PhotoSliderState();
}

class _PhotoSliderState extends State<PhotoSlider> {
  List<String> mediaFilenames = [];
  bool isLoading = true;
  String? errorMessage;
  int _currentIndex = 0;
  List<String> mediaUrls = [];
  late PageController _pageController;
  int lot_type = 1;
  final Set<String> _registeredViewTypes = {};

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

    try {
      int id = widget.id;
      var url = Uri.parse('$BASE_API_URL/api/get_auction_photo?id=$id');
      var response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> decoded = jsonDecode(utf8.decode(response.bodyBytes));
        List<String> filenames = decoded.cast<String>();
        if (filenames.isNotEmpty) {
          lot_type = 1;
          mediaFilenames = filenames;
          mediaUrls = filenames
              .map((filename) =>
                  '$BASE_API_URL/static/img/lots/auctions/$filename')
              .toList();
        } else {
          var askUrl = Uri.parse('$BASE_API_URL/api/get_asks_media?id=$id');
          var askResponse = await http.get(askUrl);
          if (askResponse.statusCode == 200) {
            List<dynamic> askDecoded =
                jsonDecode(utf8.decode(askResponse.bodyBytes));
            List<String> askFilenames = askDecoded.cast<String>();
            lot_type = 2;
            mediaFilenames = askFilenames;
            mediaUrls = askFilenames
                .map((filename) =>
                    '$BASE_API_URL/static/img/lots/asks/$filename')
                .toList();
          } else {
            setState(() {
              errorMessage =
                  'Не удалось загрузить фотографии. Код ошибки: ${askResponse.statusCode}';
              isLoading = false;
            });
            return;
          }
        }

        mediaUrls.sort((a, b) {
          bool aVideo = isVideo(a);
          bool bVideo = isVideo(b);
          if (aVideo && !bVideo) return -1;
          if (!aVideo && bVideo) return 1;
          return 0;
        });

        for (var mediaUrl in mediaUrls) {
          if (isVideo(mediaUrl)) {
            String viewType = 'video-$mediaUrl';
            if (!_registeredViewTypes.contains(viewType)) {
              html.VideoElement videoElement = html.VideoElement()
                ..src = mediaUrl
                ..autoplay = true
                ..loop = true
                ..muted = true
                ..controls = false
                ..style.width = '100%'
                ..style.height = '100%'
                ..style.objectFit = 'cover';
              ui.platformViewRegistry.registerViewFactory(
                viewType,
                (int viewId) => videoElement,
              );
              _registeredViewTypes.add(viewType);
            }
          } else {
            precacheImage(NetworkImage(mediaUrl), context);
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

  void _navigateToPage(int index) {
    if (index >= 0 && index < mediaUrls.length) {
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool isVideo(String url) {
    return url.toLowerCase().endsWith('.mp4');
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
    } else if (mediaFilenames.isEmpty) {
      return Center(child: Text('Фотографии отсутствуют.'));
    } else {
      return Container(
        width: double.infinity,
        height: sliderHeight,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: mediaUrls.length,
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                String mediaUrl = mediaUrls[index];
                if (isVideo(mediaUrl)) {
                  String viewType = 'video-$mediaUrl';
                  return Stack(
                    children: [
                      HtmlElementView(viewType: viewType),
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () => widget.onImageTap(widget.id),
                          child: Container(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return GestureDetector(
                    onTap: () => widget.onImageTap(widget.id),
                    child: Image.network(
                      mediaUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(Icons.error),
                        );
                      },
                    ),
                  );
                }
              },
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
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                    ),
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
                  if (_currentIndex < mediaUrls.length - 1) {
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
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
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
                  '${_currentIndex + 1}/${mediaUrls.length}',
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
