import 'package:flutter/material.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateService updateService;
  final String downloadUrl;
  final bool isForced; // true = no se puede cerrar

  const UpdateDialog({
    required this.updateService,
    required this.downloadUrl,
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
              const SizedBox(height: 20),
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
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                    ),
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
        setState(() {
          _isDownloading = false;
          _errorMessage = 'Error: ${e.toString()}';
          _statusText = 'Hubo un problema al descargar';
        });
      }
    }
  }
}
