import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TopRegionCard extends StatelessWidget{
  final List<MapEntry<String, int>> regions;

  const TopRegionCard({super.key, required this.regions});

  @override
  Widget build(BuildContext context){
    if(regions.isEmpty){
      return const SizedBox.shrink();
    }

    final maxCount = regions.first.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
      color: AppTheme.cardColor,         
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Top Active Regions",
            style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 2,
            ),
          ),
          for (int i = 0; i < regions.length; i++)
            _buildActiveRegionRow(
              rank: i + 1,
              region: regions[i].key,
              count: regions[i].value,
              maxCount: maxCount,
            ),
        ],
      ),
    );
  }
}



Widget _buildActiveRegionRow({
  required int rank,
  required String region,
  required int count,
  required int maxCount,
}){
  final progress = maxCount > 0 ? count / maxCount : 0.0;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        //the rank of the region
        SizedBox(
          width: 20,
          height: 20,
          child: Text(
            '$rank',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 10),

        //the region name
        SizedBox(
          width: 130,
          child: Text(
            region,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        
        const SizedBox(width: 10),

        // the progress bar
        Expanded(
          child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withValues(alpha:0.1),
          color: Colors.white,
          minHeight: 8,
          
          ),
        ),

        const SizedBox(width: 32),

        //the count of events
        SizedBox(
          width: 20,
          height: 20,
          child: Text(
            "$count",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}