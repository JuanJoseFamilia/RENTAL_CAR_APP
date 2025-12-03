//lib/models/review_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String userId;
  final String vehicleId;
  final String reservationId;
  final int calificacion;
  final String comentario;
  final DateTime fecha;
  final String nombreUsuario;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.reservationId,
    required this.calificacion,
    required this.comentario,
    required this.fecha,
    required this.nombreUsuario,
  });

  // Convertir de Map a ReviewModel (desde Firestore)
  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      userId: map['userId'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      reservationId: map['reservationId'] ?? '',
      calificacion: map['calificacion'] ?? 0,
      comentario: map['comentario'] ?? '',
      fecha: (map['fecha'] as Timestamp).toDate(),
      nombreUsuario: map['nombreUsuario'] ?? 'Usuario',
    );
  }

  // Convertir de ReviewModel a Map (para guardar en Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'vehicleId': vehicleId,
      'reservationId': reservationId,
      'calificacion': calificacion,
      'comentario': comentario,
      'fecha': Timestamp.fromDate(fecha),
      'nombreUsuario': nombreUsuario,
    };
  }

  // Obtener representación en estrellas
  String get estrellasTexto {
    return '⭐' * calificacion;
  }

  // Verificar si tiene comentario
  bool get tieneComentario => comentario.isNotEmpty;

  // Obtener fecha formateada
  String get fechaFormateada {
    final now = DateTime.now();
    final difference = now.difference(fecha);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Justo ahora';
        }
        return 'Hace ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'}';
      }
      return 'Hace ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Hace $weeks ${weeks == 1 ? 'semana' : 'semanas'}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Hace $months ${months == 1 ? 'mes' : 'meses'}';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Hace $years ${years == 1 ? 'año' : 'años'}';
    }
  }

  // Crear copia con campos modificados
  ReviewModel copyWith({
    String? id,
    String? userId,
    String? vehicleId,
    String? reservationId,
    int? calificacion,
    String? comentario,
    DateTime? fecha,
    String? nombreUsuario,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      reservationId: reservationId ?? this.reservationId,
      calificacion: calificacion ?? this.calificacion,
      comentario: comentario ?? this.comentario,
      fecha: fecha ?? this.fecha,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
    );
  }

  @override
  String toString() {
    return 'ReviewModel(id: $id, vehicleId: $vehicleId, calificacion: $calificacion, usuario: $nombreUsuario)';
  }
}
