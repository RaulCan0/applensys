import 'package:applensys/services/dashboard_service.dart';
import 'package:applensys/services/domain/calificacion_service.dart';
import 'package:applensys/services/domain/empresa_service.dart';
import 'package:applensys/services/domain/evaluacion_service.dart';
import 'package:applensys/services/local/evaluacion_cache_service.dart' show EvaluacionCacheService;
import 'package:applensys/services/remote/auth_service.dart' show AuthService;
import 'package:applensys/services/remote/storage_service.dart' show StorageService;
import 'package:get_it/get_it.dart';


final GetIt locator = GetIt.instance;

/// Registra todos los servicios en el locator
void setupLocator() {
  locator.registerLazySingleton(() => AuthService());
  locator.registerLazySingleton(() => EmpresaService());
  locator.registerLazySingleton(() => EvaluacionService());
  locator.registerLazySingleton(() => CalificacionService());
  locator.registerLazySingleton(() => StorageService());
  locator.registerLazySingleton(() => EvaluacionCacheService());

}
