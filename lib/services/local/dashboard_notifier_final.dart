import 'package:applensys/services/dashboard_service_final.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardNotifier extends StateNotifier<DashboardMetrics> {
  final DashboardService dashboardService;

  // Constructor que inicializa el estado con valores vacíos
  DashboardNotifier(this.dashboardService) 
      : super(DashboardMetrics(
          promedioPorDimension: {},
          conteoPorDimension: {},
          principiosPorNivel: {},
          comportamientosPorNivel: {},
          sistemasPorNivel: {},
        ));

  // Método para iniciar la actualización de los datos
  Future<void> startDashboard() async {
    await dashboardService.start((metrics) {
      state = metrics;  // Actualiza el estado con los nuevos datos
    });
  }

  // Detener la actualización periódica
  void stopDashboard() {
    dashboardService.dispose();
  }
}

// Provider para dashboard graficos, recibe empresaId
final dashboardGraficosProvider = StateNotifierProvider.family<DashboardNotifier, DashboardMetrics, String>(
  (ref, empresaId) {
    final service = DashboardService(empresaId);
    final notifier = DashboardNotifier(service);
    // Inicia la suscripción a datos
    notifier.startDashboard();
    // Al desechar, detiene el servicio
    ref.onDispose(() {
      notifier.stopDashboard();
    });
    return notifier;
  },
);
