// widgets/hair_color_pick.dart
import 'package:flutter/material.dart';

class HairColorPickWidget extends StatefulWidget {
  final List<String> selectedColors;

  const HairColorPickWidget({
    Key? key,
    required this.selectedColors,
  }) : super(key: key);

  @override
  _HairColorPickWidgetState createState() => _HairColorPickWidgetState();
}

class _HairColorPickWidgetState extends State<HairColorPickWidget> {
  List<String> hairColorOptions = [
    'Брюнет',
    'Шатен',
    'Рыжий',
    'Русый',
    'Блондин',
    'Седой',
  ];

  late List<String> selectedColors;

  @override
  void initState() {
    super.initState();
    selectedColors = List.from(widget.selectedColors);
  }

  @override
  Widget build(BuildContext context) {
    final Color checkboxColor = Color.fromARGB(255, 0, 122, 255);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(selectedColors);
        return true;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Натуральный цвет',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context, selectedColors),
                        child: Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Column(
                    children: hairColorOptions.map((color) {
                      bool isSelected = selectedColors.contains(color);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedColors.remove(color);
                            } else {
                              selectedColors.add(color);
                            }
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 12.0),
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? checkboxColor.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(color, style: TextStyle(fontSize: 16)),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? checkboxColor
                                      : Colors.transparent,
                                  border: Border.all(
                                      color: checkboxColor, width: 2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: isSelected
                                    ? Icon(Icons.check,
                                        color: Colors.white, size: 16)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
