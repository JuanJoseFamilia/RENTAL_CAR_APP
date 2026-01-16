import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:developer' as developer;

class UpdateService {
  final String githubRepo; // "tu_usuario/RENTAL_CAR_APP"
  final String githubToken; // Opcional, para más requests
  final Dio dio;

  UpdateService({
    required this.githubRepo,
    this.githubToken = '',
  }) : dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  /// Obtiene la versión más reciente de GitHub
  Future<String?> getLatestVersion() async {
    try {
      final response = await dio.get(
        'https://api.github.com/repos/$githubRepo/releases/latest',
        options: Options(
          headers: {
            if (githubToken.isNotEmpty) 'Authorization': 'token $githubToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        final tagName = response.data['tag_name'] as String?;
        return tagName?.replaceFirst('v', ''); // "v1.0.0" -> "1.0.0"
      }
    } catch (e) {
      developer.log('Error obteniendo versión: $e');
    }
    return null;
  }

  /// Obtiene la URL de descarga del APK más reciente
  Future<String?> getDownloadUrl() async {
    try {
      final response = await dio.get(
        'https://api.github.com/repos/$githubRepo/releases/latest',
        options: Options(
          headers: {
            if (githubToken.isNotEmpty) 'Authorization': 'token $githubToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        final assets = response.data['assets'] as List?;
        if (assets != null && assets.isNotEmpty) {
          final apk = assets.firstWhere(
            (asset) => (asset['name'] as String).endsWith('.apk'),
            orElse: () => null,
          );
          return apk?['browser_download_url'] as String?;
        }
      }
    } catch (e) {
      developer.log('Error obteniendo URL: $e');
    }
    return null;
  }

  /// Compara versiones (retorna true si hay actualización disponible)
  bool hasUpdate(String currentVersion, String latestVersion) {
    try {
      final current = _parseVersion(currentVersion);
      final latest = _parseVersion(latestVersion);

      for (int i = 0; i < 3; i++) {
        if (latest[i] > current[i]) return true;
        if (latest[i] < current[i]) return false;
      }
      return false;
    } catch (e) {
      developer.log('Error comparando versiones: $e');
      return false;
    }
  }

  List<int> _parseVersion(String version) {
    try {
      final parts = version.split('.');
      return [
        int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0,
        int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
        int.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0,
      ];
    } catch (e) {
      return [0, 0, 0];
    }
  }

  /// Obtiene versión actual de la app
  Future<String> getCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (e) {
      developer.log('Error obteniendo versión actual: $e');
      return '0.0.0';
    }
  }

  /// Descarga el APK con progreso
  Future<String> downloadApk(
    String downloadUrl, {
    required Function(int received, int total) onProgress,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${appDir.path}/downloads');
      
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final apkPath = '${downloadDir.path}/rental_car_app_update.apk';

      // Eliminar APK anterior si existe
      final oldFile = File(apkPath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }

      await dio.download(
        downloadUrl,
        apkPath,
        onReceiveProgress: (received, total) {
          onProgress(received, total);
        },
      );

      return apkPath;
    } catch (e) {
      developer.log('Error descargando APK: $e');
      rethrow;
    }
  }

  /// Instala el APK usando intent de Android
  Future<void> installApk(String apkPath) async {
    try {
      if (Platform.isAndroid) {
        // Usar intent para abrir el instalador
        const platform = MethodChannel('com.example.rental_car_app/install');
        await platform.invokeMethod('installApk', {'path': apkPath});
      }
    } catch (e) {
      developer.log('Error instalando APK: $e');
      rethrow;
    }
  }
}
