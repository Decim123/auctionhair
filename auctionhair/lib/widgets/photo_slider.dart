// photo_slider.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import 'gallery_photo_view_wrapper.dart';

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

  @override
  void initState() {
    super.initState();
    // Инициализируем PageController с начальной страницей
    _pageController = PageController(initialPage: _currentIndex);
    // Запускаем загрузку фотографий
    fetchAuctionPhotos();
  }

  @override
  void dispose() {
    // Освобождаем ресурсы PageController при уничтожении виджета
    _pageController.dispose();
    super.dispose();
  }

  /// Метод для загрузки фотографий аукциона
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
        // Парсим полученные данные
        List<dynamic> decoded = jsonDecode(utf8.decode(response.bodyBytes));
        List<String> filenames = decoded.cast<String>();
        List<String> urls = filenames
            .map((filename) =>
                '$BASE_API_URL/static/img/lots/auctions/$filename')
            .toList();

        // Предзагрузка изображений
        for (var imageUrl in urls) {
          precacheImage(NetworkImage(imageUrl), context);
        }

        setState(() {
          photoFilenames = filenames;
          imageUrls = urls;
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

  /// Метод для открытия галереи с выбранной фотографией
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

  /// Метод для анимированной навигации к определенной странице
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
    // Вычисляем высоту слайдера (60% от высоты экрана)
    double sliderHeight = MediaQuery.of(context).size.height * 0.6;

    if (isLoading) {
      // Отображаем индикатор загрузки
      return Center(child: CircularProgressIndicator());
    } else if (errorMessage != null) {
      // Отображаем сообщение об ошибке
      return Center(
        child: Text(
          errorMessage!,
          style: TextStyle(fontSize: 16, color: Colors.red),
        ),
      );
    } else if (photoFilenames.isEmpty) {
      // Отображаем сообщение, если фотографии отсутствуют
      return Center(child: Text('Фотографии отсутствуют.'));
    } else {
      return Container(
        width: double.infinity,
        height: sliderHeight,
        child: Stack(
          children: [
            // Основной слайдер с изображениями
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
                  String imageUrl = imageUrls[index];
                  return Image.network(
                    imageUrl,
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
                  );
                },
              ),
            ),
            // Левая стрелка для навигации к предыдущему изображению
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
            // Правая стрелка для навигации к следующему изображению
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
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            // Индикатор текущего слайда
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
