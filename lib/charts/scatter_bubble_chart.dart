
import 'package:flutter/material.dart';

class ScatterBubbleChart extends StatelessWidget {
  final List<ScatterBubbleData> data;
  final String title;
  final double minValue;
  final double maxValue;

  const ScatterBubbleChart({
    super.key,
    required this.data,
    required this.title,
    required this.minValue,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: data.isEmpty
              ? const Center(child: Text('Sin datos'))
              : ListView(
                  children: data
                      .map((e) => ListTile(
                            title: Text('X: ${e.x.toStringAsFixed(1)}'),
                            trailing: Text('Y: ${e.y.toStringAsFixed(2)}'),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class ScatterBubbleData {
  final double x;
  final double y;
  ScatterBubbleData({required this.x, required this.y});
}
