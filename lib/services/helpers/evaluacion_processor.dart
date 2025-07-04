import 'package:applensys/models/dimension.dart';
import 'package:applensys/models/principio.dart';
import 'package:applensys/models/comportamiento.dart';

class EvaluacionProcessor {
  // ignore: unintended_html_in_doc_comment
  /// Convierte raw → List<Dimension>
  static List<Dimension> procesarDimensiones(List<Map<String, dynamic>> raw) {
    final porDim = <String, List<Map<String, dynamic>>>{};
    for (var fila in raw) {
      final id = fila['dimension_id']?.toString() ?? 'Sin dimensión';
      porDim.putIfAbsent(id, () => []).add(fila);
    }
    final dims = <Dimension>[];
    porDim.forEach((dimId, filas) {
      double suma = 0;
      int cnt = 0;
      final principios = <Principio>[];
      // … aquí copia y adapta tu lógica de Principio/Comportamiento …
      // al final:
      final prom = cnt > 0 ? suma / cnt : 0.0;
      dims.add(Dimension(
        id: dimId,
        nombre: dimId,
        promedioGeneral: prom,
        principios: principios,
      ));
    });
    return dims;
  }

  /// Promedio por dimensión y cargo
  static Map<String, Map<String, double>> promedioPorDimensionYCargo(
      List<Map<String, dynamic>> raw) {
    final suma = <String, Map<String, double>>{};
    final cnt = <String, Map<String, int>>{};
    for (var r in raw) {
      final dim = r['dimension_id']?.toString() ?? 'Sin';
      final cr = (r['cargo_raw'] as String?)?.toLowerCase() ?? '';
      final nivel = cr.contains('gerente')
          ? 'Gerente'
          : cr.contains('miembro')
              ? 'Miembro'
              : 'Ejecutivo';
      suma.putIfAbsent(dim, () => {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0});
      cnt.putIfAbsent(dim, () => {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0});
      final v = (r['valor'] as num?)?.toDouble() ?? 0.0;
      suma[dim]![nivel] = suma[dim]![nivel]! + v;
      cnt[dim]![nivel] = cnt[dim]![nivel]! + 1;
    }
    final out = <String, Map<String, double>>{};
    suma.forEach((dim, m) {
      out[dim] = {
        for (var nivel in m.keys)
          nivel: cnt[dim]![nivel]! > 0 ? m[nivel]! / cnt[dim]![nivel]! : 0.0
      };
    });
    return out;
  }

  /// Promedio por sistema y nivel
  static Map<String, Map<String, double>> promedioPorSistemaYNivel(
    List<Map<String, dynamic>> raw,
    List<String> sistemasOrdenados,
  ) {
    final suma = <String, Map<String, double>>{};
    final cnt = <String, Map<String, int>>{};
    for (var s in sistemasOrdenados) {
      suma[s] = {'E': 0, 'G': 0, 'M': 0};
      cnt[s] = {'E': 0, 'G': 0, 'M': 0};
    }
    for (var r in raw) {
      final cr = (r['cargo_raw'] as String?)?.toLowerCase() ?? '';
      String? nivel = cr.contains('gerente')
          ? 'G'
          : cr.contains('miembro')
              ? 'M'
              : cr.contains('ejecutivo')
                  ? 'E'
                  : null;
      if (nivel == null) continue;
      final rawSys = r['sistemas'];
      final lista = <String>[];
      if (rawSys is String) {
        lista.add(rawSys.trim());
      // ignore: curly_braces_in_flow_control_structures
      } else if (rawSys is List) lista.addAll(rawSys.whereType<String>());
      final v = (r['valor'] as num?)?.toDouble() ?? 0.0;
      for (var sys in lista) {
        final key = sistemasOrdenados.firstWhere(
            (x) => x.toLowerCase() == sys.toLowerCase(),
            orElse: () => '');
        if (key.isNotEmpty) {
          suma[key]![nivel] = suma[key]![nivel]! + v;
          cnt[key]![nivel] = cnt[key]![nivel]! + 1;
        }
      }
    }
    final out = <String, Map<String, double>>{};
    suma.forEach((sys, m) {
      out[sys] = {
        for (var nl in ['E', 'G', 'M'])
          nl: cnt[sys]![nl]! > 0 ? m[nl]! / cnt[sys]![nl]! : 0.0
      };
    });
    return out;
  }
}