// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Applensys';

  @override
  String get close => 'Close';

  @override
  String get validation => 'Validation';

  @override
  String get writeObservation => 'You must write an observation.';

  @override
  String get selectSystem => 'Select at least one system.';

  @override
  String get evidence => 'Evidence';

  @override
  String get imageUploaded => 'Image uploaded successfully.';

  @override
  String get error => 'Error';

  @override
  String imageUploadError(Object error) {
    return 'Could not get the image: $error';
  }

  @override
  String get modifyRatingTitle => 'Modify rating';

  @override
  String get modifyRatingContent =>
      'A rating already exists for this behavior. Do you want to modify it?';

  @override
  String get no => 'No';

  @override
  String get yes => 'Yes';

  @override
  String get drawerHome => 'Home';

  @override
  String get drawerResults => 'Results';

  @override
  String get drawerDetailEvaluation => 'Evaluation Detail';

  @override
  String get drawerHistory => 'History';

  @override
  String get drawerSettings => 'Settings';

  @override
  String get drawerDashboard => 'Dashboard';

  @override
  String get drawerChat => 'Chat';

  @override
  String get drawerMyNotes => 'My Notes';
}
