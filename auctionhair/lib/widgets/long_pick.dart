// widgets/long_pick.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class LongPickWidget extends StatefulWidget {
  final String title;
  final int minValue;
  final int maxValue;
  final int? initialMin;
  final int? initialMax;

  const LongPickWidget({
    Key? key,
    required this.title,
    required this.minValue,
    required this.maxValue,
    this.initialMin,
    this.initialMax,
  }) : super(key: key);

  @override
  _LongPickWidgetState createState() => _LongPickWidgetState();
}

class _LongPickWidgetState extends State<LongPickWidget> {
  late int selectedMin;
  late int selectedMax;

  late FixedExtentScrollController _minScrollController;
  late FixedExtentScrollController _maxScrollController;

  @override
  void initState() {
    super.initState();
    selectedMin = widget.initialMin ?? widget.minValue;
    selectedMax = widget.initialMax ?? widget.maxValue;

    _minScrollController =
        FixedExtentScrollController(initialItem: selectedMin - widget.minValue);
    _maxScrollController =
        FixedExtentScrollController(initialItem: selectedMax - widget.minValue);
  }

  @override
  void dispose() {
    _minScrollController.dispose();
    _maxScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int totalItems = widget.maxValue - widget.minValue + 1;
    final Color checkboxColor = const Color.fromARGB(255, 0, 122, 255);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop([selectedMin, selectedMax]);
        return true;
      },
      child: GestureDetector(
        // Позволяет нажатию вне модалки закрыть ее
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus(); // Закрыть клавиатуру, если открыта
        },
        child: DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Заголовок с кнопкой закрытия
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(widget.title,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          GestureDetector(
                            onTap: () => Navigator.pop(
                                context, [selectedMin, selectedMax]),
                            child: Icon(Icons.close, color: Colors.grey),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Пикеры для выбора диапазона
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Пикер "От"
                          Column(
                            children: [
                              Text('От'),
                              SizedBox(
                                height: 150,
                                width: 100,
                                child: CupertinoPicker(
                                  scrollController: _minScrollController,
                                  itemExtent: 32.0,
                                  onSelectedItemChanged: (int index) {
                                    setState(() {
                                      selectedMin = widget.minValue + index;
                                      if (selectedMin > selectedMax) {
                                        selectedMax = selectedMin;
                                        _maxScrollController.jumpToItem(
                                            selectedMax - widget.minValue);
                                      }
                                    });
                                  },
                                  children: List<Widget>.generate(totalItems,
                                      (int index) {
                                    return Center(
                                        child:
                                            Text('${widget.minValue + index}'));
                                  }),
                                ),
                              ),
                            ],
                          ),
                          // Пикер "До"
                          Column(
                            children: [
                              Text('До'),
                              SizedBox(
                                height: 150,
                                width: 100,
                                child: CupertinoPicker(
                                  scrollController: _maxScrollController,
                                  itemExtent: 32.0,
                                  onSelectedItemChanged: (int index) {
                                    setState(() {
                                      selectedMax = widget.minValue + index;
                                      if (selectedMax < selectedMin) {
                                        selectedMin = selectedMax;
                                        _minScrollController.jumpToItem(
                                            selectedMin - widget.minValue);
                                      }
                                    });
                                  },
                                  children: List<Widget>.generate(totalItems,
                                      (int index) {
                                    return Center(
                                        child:
                                            Text('${widget.minValue + index}'));
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Здесь кнопка "Применить" удалена
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
