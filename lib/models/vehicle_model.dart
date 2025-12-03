//lib/models/vehicle_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleModel {
  final String id;
  final String marca;
  final String modelo;
  final int anio;
  final String tipo;
  final double precioPorDia;
  final String imagenUrl;
  final String descripcion;
  final bool disponible;
  final int capacidad;
  final String transmision;
  final double calificacionPromedio;
  final int totalCalificaciones;
  final DateTime fechaCreacion;

  VehicleModel({
    required this.id,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.tipo,
    required this.precioPorDia,
    required this.imagenUrl,
    required this.descripcion,
    this.disponible = true,
    required this.capacidad,
    required this.transmision,
    this.calificacionPromedio = 0.0,
    this.totalCalificaciones = 0,
    required this.fechaCreacion,
  });

  // Convertir de Map a VehicleModel (desde Firestore)
  factory VehicleModel.fromMap(Map<String, dynamic> map, String id) {
    return VehicleModel(
      id: id,
      marca: map['marca'] ?? '',
      modelo: map['modelo'] ?? '',
      anio: map['anio'] ?? 0,
      tipo: map['tipo'] ?? '',
      precioPorDia: (map['precioPorDia'] ?? 0).toDouble(),
      imagenUrl: map['imagenUrl'] ?? '',
      descripcion: map['descripcion'] ?? '',
      disponible: map['disponible'] ?? true,
      capacidad: map['capacidad'] ?? 0,
      transmision: map['transmision'] ?? '',
      calificacionPromedio: (map['calificacionPromedio'] ?? 0).toDouble(),
      totalCalificaciones: map['totalCalificaciones'] ?? 0,
      fechaCreacion: (map['fechaCreacion'] as Timestamp).toDate(),
    );
  }

  // Convertir de VehicleModel a Map (para guardar en Firestore)
  Map<String, dynamic> toMap() {
    return {
      'marca': marca,
      'modelo': modelo,
      'anio': anio,
      'tipo': tipo,
      'precioPorDia': precioPorDia,
      'imagenUrl': imagenUrl,
      'descripcion': descripcion,
      'disponible': disponible,
      'capacidad': capacidad,
      'transmision': transmision,
      'calificacionPromedio': calificacionPromedio,
      'totalCalificaciones': totalCalificaciones,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
    };
  }

  // Nombre completo del vehículo
  String get nombreCompleto => '$marca $modelo ($anio)';

  // Obtener calificación en formato de texto
  String get calificacionTexto {
    if (totalCalificaciones == 0) {
      return 'Sin calificaciones';
    }
    return '${calificacionPromedio.toStringAsFixed(1)} (${totalCalificaciones} ${totalCalificaciones == 1 ? 'reseña' : 'reseñas'})';
  }

  // Crear copia con campos modificados
  VehicleModel copyWith({
    String? id,
    String? marca,
    String? modelo,
    int? anio,
    String? tipo,
    double? precioPorDia,
    String? imagenUrl,
    String? descripcion,
    bool? disponible,
    int? capacidad,
    String? transmision,
    double? calificacionPromedio,
    int? totalCalificaciones,
    DateTime? fechaCreacion,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      anio: anio ?? this.anio,
      tipo: tipo ?? this.tipo,
      precioPorDia: precioPorDia ?? this.precioPorDia,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      descripcion: descripcion ?? this.descripcion,
      disponible: disponible ?? this.disponible,
      capacidad: capacidad ?? this.capacidad,
      transmision: transmision ?? this.transmision,
      calificacionPromedio: calificacionPromedio ?? this.calificacionPromedio,
      totalCalificaciones: totalCalificaciones ?? this.totalCalificaciones,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  @override
  String toString() {
    return 'VehicleModel(id: $id, nombreCompleto: $nombreCompleto, precio: \$$precioPorDia/día)';
  }
}
