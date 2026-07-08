import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

//this widget is built to build the clusters on the map screen in the flutter app.

class ClusterBadge extends StatelessWidget{
  final int count;

  const ClusterBadge({super.key, required this.count});

  @override

  Widget build(BuildContext context){
    final size = _clusterSize(count);

    return SizedBox(
      width: size,
      height: size,
      child: Container(         // for the outer circle
      decoration: BoxDecoration(
        shape :BoxShape.circle,
        color: _clusterColor(count).withValues(alpha: 0.2),
        border: Border.all(
          width: 2,
          color: _clusterColor(count),
        ),
      ),
      child: Center(
        child: Container(          // for the inner circle
          width: size * 0.7, 
          height: size * 0.7,
          decoration: BoxDecoration(
            shape :BoxShape.circle,
            color: _clusterColor(count).withValues(alpha: 0.85)
          ),
        
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
          ),
        ),
        ),
        ),
      ),
    ),
    );
  }

  Color _clusterColor(int count){
    if (count < 10) return Colors.green;
    if (count < 50) return Colors.yellow;
    if (count < 100) return Colors.deepOrange;
    return Colors.red;
  }

  double _clusterSize(int count){
    if (count < 10) return 40;
    if (count < 50) return 50;
    if (count < 100) return 60;
    return 80;
  }
}