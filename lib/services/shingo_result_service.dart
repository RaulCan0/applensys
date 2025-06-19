import '../../screens/shingo_result.dart';

class ShingoResultService {

  static final ShingoResultService _instance = ShingoResultService._internal();
  factory ShingoResultService() => _instance;
  ShingoResultService._internal();

  final Map<String, ShingoResultData> _resultados = {
    for (var label in sheetLabels) label: ShingoResultData(),
  };

  Map<String, ShingoResultData> get resultados => _resultados;

  void guardarResultado(String label, ShingoResultData data) {
    _resultados[label] = data;
  }

  int? getCalificacion(String label) => _resultados[label]?.calificacion;
}