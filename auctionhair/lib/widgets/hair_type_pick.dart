// widgets/hair_type_pick.dart
import 'package:flutter/material.dart';

class HairTypePickWidget extends StatefulWidget {
  final List<String> selectedTypes;

  const HairTypePickWidget({
    Key? key,
    required this.selectedTypes,
  }) : super(key: key);

  @override
  _HairTypePickWidgetState createState() => _HairTypePickWidgetState();
}

class _HairTypePickWidgetState extends State<HairTypePickWidget> {
  List<String> hairTypeOptions = [
    'Прямые',
    'Вьющиеся',
    'Волнистые',
    'Мелкие кудри',
  ];

  late List<String> selectedTypes;

  @override
  void initState() {
    super.initState();
    selectedTypes = List.from(widget.selectedTypes);
  }

  @override
  Widget build(BuildContext context) {
    final Color checkboxColor = Color.fromARGB(255, 0, 122, 255);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(selectedTypes);
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
                      Text('Тип',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context, selectedTypes),
                        child: Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Column(
                    children: hairTypeOptions.map((type) {
                      bool isSelected = selectedTypes.contains(type);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedTypes.remove(type);
                            } else {
                              selectedTypes.add(type);
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
                              Text(type, style: TextStyle(fontSize: 16)),
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
