// gallery_photo_view_wrapper.dart
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../constants.dart';
import 'package:http/http.dart' as http;

class GalleryPhotoViewWrapper extends StatefulWidget {
  final List<String> galleryItems;
  final List<String> imageNames;
  final int initialIndex;

  const GalleryPhotoViewWrapper({
    Key? key,
    required this.galleryItems,
    required this.imageNames,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  _GalleryPhotoViewWrapperState createState() =>
      _GalleryPhotoViewWrapperState();
}

class _GalleryPhotoViewWrapperState extends State<GalleryPhotoViewWrapper> {
  late int currentIndex;
  late PageController pageController;

  @override
  void initState() {
    currentIndex = widget.initialIndex;
    pageController = PageController(initialPage: currentIndex);
    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            itemCount: widget.galleryItems.length,
            pageController: pageController,
            onPageChanged: onPageChanged,
            builder: (BuildContext context, int index) {
              String imageUrl = widget.galleryItems[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(imageUrl),
                initialScale: PhotoViewComputedScale.contained,
                heroAttributes:
                    PhotoViewHeroAttributes(tag: widget.galleryItems[index]),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.imageNames[currentIndex],
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
                '${currentIndex + 1}/${widget.galleryItems.length}',
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
