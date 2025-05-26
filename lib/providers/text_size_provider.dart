import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider que maneja el tamaño de texto global (en puntos)
final textSizeProvider = StateProvider<double>((ref) => 14.0);
