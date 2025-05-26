class DashboardMetrics {
  final Map<String, double> promedioPorDimension;
  final Map<String, int> conteoPorDimension;
  final Map<String, Map<String, double>> principiosPorNivel;
  final Map<String, List<double>> comportamientosPorNivel;
  final Map<String, Map<String, int>> sistemasPorNivel;

  DashboardMetrics({
    required this.promedioPorDimension,
    required this.conteoPorDimension,
    required this.principiosPorNivel,
    required this.comportamientosPorNivel,
    required this.sistemasPorNivel,
  });

  // Puedes agregar métodos adicionales para manipular los datos si es necesario.
}
