import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CategoryLegend extends StatelessWidget {
  const CategoryLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Earthquakes', AppTheme.earthquakeColor),
      ('Storms', AppTheme.floodStormColor),
      ('Wildfires', AppTheme.wildfireColor),
      ('Disease', AppTheme.diseaseColor),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(right: 22),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing colored dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item.$2,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: item.$2.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.$1,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}