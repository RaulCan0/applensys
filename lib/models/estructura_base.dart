
import 'dart:convert';
import 'package:flutter/services.dart';

class EstructuraBase {
  final List<Dimension> dimensiones;

  EstructuraBase({required this.dimensiones});

  factory EstructuraBase.fromJson(Map<String, dynamic> json) {
    return EstructuraBase(
      dimensiones: (json['dimensiones'] as List)
          .map((d) => Dimension.fromJson(d))
          .toList(),
    );
  }

  static Future<EstructuraBase> cargarDesdeAssets() async {
    final data = await rootBundle.loadString('assets/estructura_base.json');
    final jsonResult = json.decode(data);
    return EstructuraBase.fromJson(jsonResult);
  }
}

class Dimension {
  final String id;
  final String nombre;
  final List<Principio> principios;

  Dimension({required this.id, required this.nombre, required this.principios});

  factory Dimension.fromJson(Map<String, dynamic> json) {
    return Dimension(
      id: json['id'],
      nombre: json['nombre'],
      principios: (json['principios'] as List)
          .map((p) => Principio.fromJson(p))
          .toList(),
    );
  }
}

class Principio {
  final String nombre;
  final List<String> comportamientos;

  Principio({required this.nombre, required this.comportamientos});

  factory Principio.fromJson(Map<String, dynamic> json) {
    return Principio(
      nombre: json['nombre'],
      comportamientos: List<String>.from(json['comportamientos']),
    );
  }
}
