import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TopRegionCard extends StatelessWidget {
  final List<MapEntry<String, int>> regions;

  const TopRegionCard({super.key, required this.regions});

  @override
  Widget build(BuildContext context) {
    if (regions.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxCount = regions.first.value;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1421),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Active Regions',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
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
}) {
  final progress = maxCount > 0 ? count / maxCount : 0.0;

  //Rank gets progressively dimmer
  final rankOpacity = rank == 1
      ? 1.0
      : rank == 2
      ? 0.7
      : 0.5;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        SizedBox(
          width: 22,
          child: Text(
            '$rank',
            style: TextStyle(
              color: Colors.white.withValues(alpha: rankOpacity * 1),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),

        //the region name
        SizedBox(
          width: 120,
          child: Text(
            region,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 1),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(width: 10),

        //the progress bar
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.primary.withValues(alpha: 0.7),
              ),
              minHeight: 5,
            ),
          ),
        ),

        const SizedBox(width: 12),

        //the count of events
        Text(
          '$count',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
