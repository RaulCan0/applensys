import 'package:flutter/material.dart';

Color _customcolor = Colors.indigo[900]!;

List<Color> _colorThemes = [
  _customcolor,
  Colors.blue,
  Colors.red,
  Colors.white,
  Colors.black,
  Colors.purple,
  Colors.green,
  Colors.orange,
  Colors.yellow,
  Colors.brown,
  Colors.cyan,
  Colors.teal,
  Colors.pink,
  Colors.lime,
  Colors.amber,
  Colors.grey,
  Colors.indigo,
  Colors.deepOrange,
  Colors.deepPurple,
  Colors.lightBlue,
  Colors.lightGreen,
];

class Theme {
  final int selectedColor;
  Theme({this.selectedColor = 0});
  ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _colorThemes[selectedColor],
    );
  }
}
