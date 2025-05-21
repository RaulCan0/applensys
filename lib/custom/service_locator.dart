import 'package:get_it/get_it.dart';
import '../services/remote/auth_service.dart';
import '../services/domain/empresa_service.dart';
import '../services/domain/asociado_service.dart';
import '../services/domain/evaluacion_service.dart';
import '../services/domain/calificacion_service.dart';
import '../services/remote/storage_service.dart';
import '../services/local/evaluacion_cache_service.dart';

final GetIt locator = GetIt.instance;

/// Registra todos los servicios en el locator
void setupLocator() {
  locator.registerLazySingleton(() => AuthService());
  locator.registerLazySingleton(() => EmpresaService());
  locator.registerLazySingleton(() => AsociadoService());
  locator.registerLazySingleton(() => EvaluacionService());
  locator.registerLazySingleton(() => CalificacionService());
  locator.registerLazySingleton(() => StorageService());
  locator.registerLazySingleton(() => EvaluacionCacheService());
}
