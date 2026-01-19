import 'package:flutter/material.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateService updateService;
  final String downloadUrl;
  final String? releaseNotes;
  final bool isForced; // true = no se puede cerrar

  const UpdateDialog({
    required this.updateService,
    required this.downloadUrl,
    this.releaseNotes,
    this.isForced = true,
    super.key,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  double _progress = 0;
  bool _isDownloading = false;
  String _statusText = 'Nueva actualización disponible';
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isForced && !_isDownloading,
      onPopInvokedWithResult: (didPop, result) {
        if (widget.isForced && !_isDownloading && !didPop) {
          // Prevenir que se cierre si es forzada
          return;
        }
      },
      child: AlertDialog(
        title: const Text(
          'Actualización disponible',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _statusText,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              // Mostrar notas de cambios si están disponibles
              if (widget.releaseNotes != null && !_isDownloading)
                Container(
                  constraints: const BoxConstraints(
                    maxHeight: 200, // Altura máxima del contenedor
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Novedades:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.releaseNotes!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (widget.releaseNotes != null && !_isDownloading)
                const SizedBox(height: 16),
              if (_isDownloading)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        '${(_progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Algo salió mal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          if (!_isDownloading && !widget.isForced && _errorMessage == null)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Más tarde'),
            ),
          if (_errorMessage != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _progress = 0;
                  _statusText = 'Nueva actualización disponible';
                });
              },
              child: const Text('Reintentar'),
            ),
          ElevatedButton(
            onPressed: _isDownloading ? null : _handleUpdate,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _isDownloading
                    ? 'Descargando...'
                    : _errorMessage != null
                        ? 'Reintentar'
                        : 'Actualizar ahora',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpdate() async {
    setState(() {
      _isDownloading = true;
      _statusText = 'Descargando actualización...';
      _errorMessage = null;
      _progress = 0;
    });

    try {
      final apkPath = await widget.updateService.downloadApk(
        widget.downloadUrl,
        onProgress: (received, total) {
          if (mounted) {
            setState(() {
              _progress = total > 0 ? received / total : 0;
            });
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _statusText = 'Descarga completada. Instalando...';
      });

      // Pequeña pausa para mejorar UX
      await Future.delayed(const Duration(milliseconds: 500));

      await widget.updateService.installApk(apkPath);

      if (mounted) {
        setState(() {
          _statusText = '¡Instalando actualización!';
        });
      }
    } catch (e) {
      if (mounted) {
        String userFriendlyMessage = _getErrorMessage(e);
        setState(() {
          _isDownloading = false;
          _errorMessage = userFriendlyMessage;
          _statusText = 'No se pudo completar la actualización';
        });
      }
    }
  }

  /// Convierte errores técnicos en mensajes amigables para el usuario
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString();

    // Errores de conexión
    if (errorString.contains('Network') ||
        errorString.contains('SocketException') ||
        errorString.contains('TimeoutException') ||
        errorString.contains('Connection') ||
        errorString.contains('host unreachable')) {
      return 'No hay conexión a internet.\n\nVerifica tu conexión WiFi o datos móviles e intenta nuevamente.';
    }

    // Errores de espacio en disco
    if (errorString.contains('No space') || errorString.contains('ENOSPC')) {
      return 'No hay suficiente espacio en el dispositivo.\n\nLibera espacio e intenta de nuevo.';
    }

    // Errores de permisos
    if (errorString.contains('Permission') || errorString.contains('PermissionHandler')) {
      return 'Se necesitan permisos para instalar la actualización.\n\nVerifica los permisos en la configuración del dispositivo.';
    }

    // Errores de descarga
    if (errorString.contains('Download') || errorString.contains('404')) {
      return 'No se pudo descargar la actualización.\n\nIntenta más tarde o contacta con soporte.';
    }

    // Errores de instalación
    if (errorString.contains('Install') || errorString.contains('APK')) {
      return 'Hubo un problema al instalar.\n\nAsegúrate de que el dispositivo permite instalar desde fuentes desconocidas.';
    }

    // Errores de timeout
    if (errorString.contains('timeout')) {
      return 'La descarga tardó demasiado.\n\nIntenta nuevamente con mejor conexión.';
    }

    // Error genérico pero amigable
    return 'Algo salió mal durante la actualización.\n\nIntenta nuevamente en unos momentos.';
  }
}
