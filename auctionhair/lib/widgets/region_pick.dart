// widgets/region_pick.dart
import 'package:flutter/material.dart';

class RegionPickWidget extends StatefulWidget {
  final List<String> selectedRegions;

  const RegionPickWidget({
    Key? key,
    required this.selectedRegions,
  }) : super(key: key);

  @override
  _RegionPickWidgetState createState() => _RegionPickWidgetState();
}

class _RegionPickWidgetState extends State<RegionPickWidget> {
  final List<Region> regions = [
    Region(name: 'Все'),
    Region(name: 'Московская область', children: ['Москва', 'Подольск']),
    Region(
        name: 'Брянская область', children: ['Брянск', 'Клинцы', 'Новозыбков']),
  ];

  late Set<String> selectedRegions;

  @override
  void initState() {
    super.initState();
    selectedRegions = widget.selectedRegions.toSet();
  }

  int getTotalSelectable() {
    // Total selectable items: 'Все' + regions + their children
    int total = 1; // 'Все'
    for (var region in regions) {
      total += 1; // The region itself
      total += region.children.length; // Its children
    }
    return total;
  }

  void toggleAllSelection() {
    setState(() {
      if (selectedRegions.contains('Все')) {
        // Deselect all
        selectedRegions.clear();
      } else {
        // Select all
        selectedRegions = regions.expand((region) {
          if (region.name == 'Все') {
            return [region.name];
          } else {
            return [region.name, ...region.children];
          }
        }).toSet();
      }
    });
  }

  void toggleRegion(String regionName) {
    setState(() {
      if (regionName == 'Все') {
        toggleAllSelection();
        return;
      }

      Region region = regions.firstWhere((r) => r.name == regionName);

      if (selectedRegions.contains(regionName)) {
        // Deselect region and its children
        selectedRegions.remove(regionName);
        selectedRegions.removeAll(region.children);
      } else {
        // Select region and its children
        selectedRegions.add(regionName);
        selectedRegions.addAll(region.children);
      }

      // After toggling, check if all are selected to set 'Все'
      if (selectedRegions.length == getTotalSelectable()) {
        selectedRegions.add('Все');
      } else {
        selectedRegions.remove('Все');
      }
    });
  }

  void toggleCity(String regionName, String cityName) {
    setState(() {
      if (selectedRegions.contains(cityName)) {
        // Deselect city
        selectedRegions.remove(cityName);
      } else {
        // Select city
        selectedRegions.add(cityName);
      }

      // Check if all cities in the region are selected
      Region region = regions.firstWhere((r) => r.name == regionName);
      bool allCitiesSelected =
          region.children.every((child) => selectedRegions.contains(child));

      if (allCitiesSelected) {
        // Select the region
        selectedRegions.add(regionName);
      } else {
        // Deselect the region
        selectedRegions.remove(regionName);
      }

      // Handle 'Все'
      if (selectedRegions.length == getTotalSelectable()) {
        selectedRegions.add('Все');
      } else {
        selectedRegions.remove('Все');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color checkboxColor = Color.fromARGB(255, 0, 122, 255);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(selectedRegions.toList());
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
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Регион',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pop(context, selectedRegions.toList()),
                        child: Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Regions List
                  Column(
                    children: regions.map((region) {
                      if (region.name == 'Все') {
                        bool isSelected = selectedRegions.contains('Все');
                        return GestureDetector(
                          onTap: toggleAllSelection,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 12.0),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? checkboxColor.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  region.name,
                                  style: TextStyle(fontSize: 16),
                                ),
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
                      }

                      if (region.children.isEmpty) {
                        bool isSelected = selectedRegions.contains(region.name);
                        return GestureDetector(
                          onTap: () {
                            toggleRegion(region.name);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 12.0),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? checkboxColor.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  region.name,
                                  style: TextStyle(fontSize: 16),
                                ),
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
                      } else {
                        bool isParentSelected =
                            selectedRegions.contains(region.name);
                        return ExpansionTile(
                          key: PageStorageKey<String>(region.name),
                          title: GestureDetector(
                            onTap: () {
                              toggleRegion(region.name);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 12.0),
                              decoration: BoxDecoration(
                                color: isParentSelected
                                    ? checkboxColor.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    region.name,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isParentSelected
                                          ? checkboxColor
                                          : Colors.transparent,
                                      border: Border.all(
                                          color: checkboxColor, width: 2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: isParentSelected
                                        ? Icon(Icons.check,
                                            color: Colors.white, size: 16)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          children: region.children.map((child) {
                            bool isSelected = selectedRegions.contains(child);
                            return GestureDetector(
                              onTap: () {
                                toggleCity(region.name, child);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24.0, vertical: 8.0),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? checkboxColor.withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      child,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Container(
                                      width: 20,
                                      height: 20,
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
                                              color: Colors.white, size: 14)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }
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

class Region {
  final String name;
  final List<String> children;

  Region({required this.name, this.children = const []});
}
