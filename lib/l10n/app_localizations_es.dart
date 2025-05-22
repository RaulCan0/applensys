// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Applensys';

  @override
  String get close => 'Cerrar';

  @override
  String get validation => 'Validación';

  @override
  String get writeObservation => 'Debes escribir una observación.';

  @override
  String get selectSystem => 'Selecciona al menos un sistema.';

  @override
  String get evidence => 'Evidencia';

  @override
  String get imageUploaded => 'Imagen subida correctamente.';

  @override
  String get error => 'Error';

  @override
  String imageUploadError(Object error) {
    return 'No se pudo obtener la imagen: $error';
  }

  @override
  String get modifyRatingTitle => 'Modificar calificación';

  @override
  String get modifyRatingContent =>
      'Ya existe una calificación para este comportamiento. ¿Deseas modificarla?';

  @override
  String get no => 'No';

  @override
  String get yes => 'Sí';

  @override
  String get drawerHome => 'Inicio';

  @override
  String get drawerResults => 'Resultados';

  @override
  String get drawerDetailEvaluation => 'Detalle Evaluación';

  @override
  String get drawerHistory => 'Historial';

  @override
  String get drawerSettings => 'Configuración';

  @override
  String get drawerDashboard => 'Dashboard';

  @override
  String get drawerChat => 'Chat';

  @override
  String get drawerMyNotes => 'Mis Anotaciones';
}
