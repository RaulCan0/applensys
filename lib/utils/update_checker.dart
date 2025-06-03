// ignore_for_file: use_build_context_synchronously

import 'dart:convert' show json;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateChecker {
  /// URL de tu JSON de versión
  static const String versionUrl = 'https://tudominio.com/version.json';

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(versionUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['current_version'];
        final changelog = data['changelog'] ?? '';
        final urlAndroid = data['download_url_android'];
        final urlWindows = data['download_url_windows'];

        final info = await PackageInfo.fromPlatform();
        final currentVersion = info.version;

        if (currentVersion != latestVersion) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('¡Nueva versión disponible!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Versión actual: $currentVersion'),
                  Text('Nueva versión: $latestVersion'),
                  const SizedBox(height: 10),
                  Text('Novedades:'),
                  Text(changelog),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Actualizar'),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _downloadAndInstallUpdate(context, Platform.isAndroid ? urlAndroid : urlWindows);
                  },
                ),
                TextButton(
                  child: const Text('Más tarde'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Puedes mostrar un error si lo deseas
    }
  }

  static Future<void> _downloadAndInstallUpdate(BuildContext context, String url) async {
    try {
      // Permisos solo para Android
      if (Platform.isAndroid) {
        await Permission.storage.request();
        await Permission.requestInstallPackages.request();
      }
      final dir = Platform.isAndroid
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();
      final fileName = url.split('/').last;
      final filePath = '${dir!.path}/$fileName';
      final dio = Dio();
      // Mostrar progreso opcional
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Descargando actualización...'),
            ],
          ),
        ),
      );
      await dio.download(url, filePath);
      Navigator.pop(context); // Cierra el diálogo de progreso
      // Abrir el archivo descargado
      await launchUrl(Uri.file(filePath));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al descargar actualización: ${e.toString()}')),
      );
    }
  }
}
