import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/foundation.dart';

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Subir múltiples XFile (desde ImagePicker) y devolver sus URLs públicas.
  /// [pathPrefix] ejemplo: 'vehicles/{vehicleId}' o 'vehicles/tmp'
  Future<List<String>> uploadFiles(List<XFile> files, String pathPrefix) async {
    final List<String> urls = [];
    final List<String> errors = [];

    for (var i = 0; i < files.length; i++) {
      final xfile = files[i];

      try {
        final bytes = await xfile.readAsBytes();
        if (bytes.isEmpty) {
          final msg = '[ImageService] empty bytes for ${xfile.path}';
          debugPrint(msg);
          errors.add(msg);
          continue;
        }

        // Intentar comprimir los bytes (si es posible)
        List<int>? compressedBytes;
        try {
          final result = await FlutterImageCompress.compressWithList(
            bytes,
            quality: 78,
            minWidth: 1024,
            minHeight: 768,
          );
          if (result.isNotEmpty) {
            compressedBytes = result;
          }
        } catch (e) {
          // Si la compresión falla, seguimos con los bytes originales
          debugPrint('[ImageService] compression failed for ${xfile.path}: $e');
        }

        final data = compressedBytes != null ? Uint8List.fromList(compressedBytes) : Uint8List.fromList(bytes);

        final String filename = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final refPath = '$pathPrefix/$filename';
        final ref = _storage.ref().child(refPath);

        debugPrint('[ImageService] Uploading XFile: ${xfile.path} to $refPath');

        final metadata = SettableMetadata(contentType: 'image/jpeg');
        final uploadTask = ref.putData(data, metadata);
        final snapshot = await uploadTask.whenComplete(() {});

        if (snapshot.state != TaskState.success) {
          final msg = '[ImageService] Upload failed for $refPath: state=${snapshot.state}';
          debugPrint(msg);
          errors.add(msg);
          continue;
        }

        // Verificar metadata para confirmar que el objeto existe en Storage
        try {
          final meta = await ref.getMetadata();
          debugPrint('[ImageService] metadata for $refPath: name=${meta.name}, contentType=${meta.contentType}, raw=${meta.toString()}');
        } catch (e) {
          final msg = '[ImageService] getMetadata failed for $refPath: $e';
          debugPrint(msg);
          errors.add(msg);
          // Si no hay metadata, probablemente el objeto no está disponible aún o hubo un problema en la escritura
          continue;
        }

        // Intentar obtener la URL con reintentos
        String? url;
        for (var attempt = 0; attempt < 6; attempt++) {
          try {
            url = await ref.getDownloadURL();
            break;
          } catch (e) {
            final msg = '[ImageService] getDownloadURL attempt ${attempt + 1} failed for $refPath: $e';
            debugPrint(msg);
            if (attempt == 5) {
              errors.add(msg);
              rethrow;
            }
            await Future.delayed(Duration(milliseconds: 700 * (attempt + 1)));
          }
        }

        if (url != null) {
          debugPrint('[ImageService] Uploaded and got URL for $refPath');
          urls.add(url);
        }
      } catch (e, st) {
        final msg = '[ImageService] Error uploading XFile ${xfile.path}: $e';
        debugPrint('$msg\n$st');
        errors.add(msg);
        continue;
      }
    }

    if (urls.isEmpty) {
      throw 'No se pudieron subir las imágenes: ${errors.join(' | ')}';
    }

    return urls;
  }


}
