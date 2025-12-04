//lib/models/reservation_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel {
  final String id;
  final String userId;
  final String vehicleId;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final double precioTotal;
  final String estado;
  final DateTime fechaReserva;
  final int diasAlquiler;

  // Datos adicionales que se cargan después
  String? vehicleMarca;
  String? vehicleModelo;
  String? vehicleImagenUrl;
  String? userName;

  ReservationModel({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.fechaInicio,
    required this.fechaFin,
    required this.precioTotal,
    required this.estado,
    required this.fechaReserva,
    required this.diasAlquiler,
    this.vehicleMarca,
    this.vehicleModelo,
    this.vehicleImagenUrl,
    this.userName,
  });

  // Convertir de Map a ReservationModel
  factory ReservationModel.fromMap(Map<String, dynamic> map, String id) {
    return ReservationModel(
      id: id,
      userId: map['userId'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      fechaInicio: (map['fechaInicio'] as Timestamp).toDate(),
      fechaFin: (map['fechaFin'] as Timestamp).toDate(),
      precioTotal: (map['precioTotal'] ?? 0).toDouble(),
      estado: map['estado'] ?? 'pendiente',
      fechaReserva: (map['fechaReserva'] as Timestamp).toDate(),
      diasAlquiler: map['diasAlquiler'] ?? 0,
    );
  }

  // Convertir de ReservationModel a Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'vehicleId': vehicleId,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': Timestamp.fromDate(fechaFin),
      'precioTotal': precioTotal,
      'estado': estado,
      'fechaReserva': Timestamp.fromDate(fechaReserva),
      'diasAlquiler': diasAlquiler,
    };
  }

  // Verificar si la reserva está activa
  bool get isActive => estado == 'confirmada' || estado == 'pendiente';

  // Verificar si la reserva está completada
  bool get isCompleted => estado == 'completada';

  // Verificar si la reserva está cancelada
  bool get isCancelled => estado == 'cancelada';

  // Verificar si la reserva puede ser cancelada
  bool get canBeCancelled {
    if (estado != 'pendiente' && estado != 'confirmada') {
      return false;
    }
    // Solo se puede cancelar si la fecha de inicio es en el futuro
    return fechaInicio.isAfter(DateTime.now());
  }

  // Verificar si se puede dejar reseña
  bool get canBeReviewed => estado == 'completada';

  // Obtener nombre del vehículo
  String get vehicleNombre {
    if (vehicleMarca != null && vehicleModelo != null) {
      return '$vehicleMarca $vehicleModelo';
    }
    return 'Vehículo';
  }

  // Obtener color según el estado
  String get estadoColor {
    switch (estado) {
      case 'confirmada':
        return 'success';
      case 'completada':
        return 'info';
      case 'cancelada':
        return 'error';
      default:
        return 'warning';
    }
  }

  // Obtener texto del estado
  String get estadoTexto {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'confirmada':
        return 'Confirmada';
      case 'completada':
        return 'Completada';
      case 'cancelada':
        return 'Cancelada';
      default:
        return estado;
    }
  }

  // Crear copia con campos modificados
  ReservationModel copyWith({
    String? id,
    String? userId,
    String? vehicleId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    double? precioTotal,
    String? estado,
    DateTime? fechaReserva,
    int? diasAlquiler,
    String? vehicleMarca,
    String? vehicleModelo,
    String? vehicleImagenUrl,
    String? userName,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      precioTotal: precioTotal ?? this.precioTotal,
      estado: estado ?? this.estado,
      fechaReserva: fechaReserva ?? this.fechaReserva,
      diasAlquiler: diasAlquiler ?? this.diasAlquiler,
      vehicleMarca: vehicleMarca ?? this.vehicleMarca,
      vehicleModelo: vehicleModelo ?? this.vehicleModelo,
      vehicleImagenUrl: vehicleImagenUrl ?? this.vehicleImagenUrl,
      userName: userName ?? this.userName,
    );
  }

  @override
  String toString() {
    return 'ReservationModel(id: $id, vehicleId: $vehicleId, estado: $estado, dias: $diasAlquiler)';
  }
}
