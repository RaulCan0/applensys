import 'package:flutter/material.dart';
import '../models/level_averages.dart';

class BehaviorScrollChart extends StatelessWidget {
  final List<LevelAverages> data;

  const BehaviorScrollChart(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Behavior Scroll Chart Placeholder'),
    );
  }
}