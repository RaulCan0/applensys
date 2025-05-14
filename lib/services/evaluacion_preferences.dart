// lib/services/evaluacion_preferences.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:applensys/services/supabase_service.dart';
import 'package:applensys/models/calificacion.dart';

class EvaluacionPreferences {
  static final EvaluacionPreferences _instance = EvaluacionPreferences._internal();
  factory EvaluacionPreferences() => _instance;
  EvaluacionPreferences._internal();

  SharedPreferences? _prefs;
  final SupabaseService _supabase = SupabaseService();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Si detecta Wi-Fi en cualquier momento, intenta sincronizar
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.wifi)) {
        syncPending();
      }
    });
    // Al iniciar la app, intenta sincronizar si ya hay Wi-Fi
    final current = await _connectivity.checkConnectivity();
    if (current.contains(ConnectivityResult.wifi)) syncPending();
  }

  Future<void> savePending(Calificacion cal) async {
    final list = _prefs?.getStringList('pending_calificaciones') ?? [];
    list.add(cal.toJson()); // Usar el método toJson
    await _prefs?.setStringList('pending_calificaciones', list);
  }

  Future<void> syncPending() async {
    final list = _prefs?.getStringList('pending_calificaciones') ?? [];
    final success = <String>[];
    for (final json in list) {
      final cal = Calificacion.fromJson(json); // Usar el método fromJson
      try {
        await _supabase.addCalificacion(
          cal,
          id: cal.evaluacionId,
          idAsociado: cal.idAsociado,
        );
        success.add(json);
      } catch (_) {
        // Si falla, lo dejamos pendiente
      }
    }
    if (success.isNotEmpty) {
      list.removeWhere(success.contains);
      await _prefs?.setStringList('pending_calificaciones', list);
    }
  }

  void dispose() => _subscription?.cancel();
}

