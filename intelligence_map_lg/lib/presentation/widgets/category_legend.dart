import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';


class CategoryLegend extends StatelessWidget {
  const CategoryLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 12,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.earthquakeColor,
            ),
          ),
          
          Text(
            "Earthquakes",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 222, 222, 222),
              fontSize: 15,
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.floodStormColor,
            ),
          ),
          
          Text(
            "Storms",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 222, 222, 222),
              fontSize: 15,

            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.wildfireColor,
            ),
          ),
          
          Text(
            "Wildfires",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 222, 222, 222),
              fontSize: 15,

            ),
          ),

          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.diseaseColor,
            ),
          ),
          
          Text(
            "Diseases",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 222, 222, 222),
              fontSize: 15,

            ),
          ),
        ],
      ),
    );
    
  }
}