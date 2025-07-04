import 'package:flutter_test/flutter_test.dart';
import 'package:applensys/services/helpers/evaluacion_processor.dart';

void main() {
  test('promedioPorDimensionYCargo calcula bien para datos de muestra', () {
    final raw = [
      {'dimension_id': '1', 'cargo_raw': 'Ejecutivo', 'valor': 4},
      {'dimension_id': '1', 'cargo_raw': 'Gerente',    'valor': 2},
      {'dimension_id': '1', 'cargo_raw': 'Miembro',    'valor': 3},
      {'dimension_id': '1', 'cargo_raw': 'Ejecutivo', 'valor': 2},
    ];
    final res = EvaluacionProcessor.promedioPorDimensionYCargo(raw);
    expect(res['1']?['Ejecutivo'], equals(3)); // (4+2)/2
    expect(res['1']?['Gerente'],    equals(2));
    expect(res['1']?['Miembro'],    equals(3));
  });
}