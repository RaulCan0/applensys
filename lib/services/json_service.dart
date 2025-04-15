import 'dart:convert';
import 'package:flutter/services.dart';

class JsonService {
  static Future<List<dynamic>> cargarJson(String archivo) async {
    final contenido = await rootBundle.loadString('assets/$archivo');
    return json.decode(contenido);
  }
}
