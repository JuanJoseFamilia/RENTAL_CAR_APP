//lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String nombre;
  final String telefono;
  final DateTime fechaRegistro;
  final String rol;

  UserModel({
    required this.id,
    required this.email,
    required this.nombre,
    required this.telefono,
    required this.fechaRegistro,
    this.rol = 'cliente',
  });

  // Convertir de Map a UserModel (desde Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      nombre: map['nombre'] ?? '',
      telefono: map['telefono'] ?? '',
      fechaRegistro: (map['fechaRegistro'] as Timestamp).toDate(),
      rol: map['rol'] ?? 'cliente',
    );
  }

  // Convertir de UserModel a Map (para guardar en Firestore)
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'nombre': nombre,
      'telefono': telefono,
      'fechaRegistro': Timestamp.fromDate(fechaRegistro),
      'rol': rol,
    };
  }

  // Crear copia con campos modificados
  UserModel copyWith({
    String? id,
    String? email,
    String? nombre,
    String? telefono,
    DateTime? fechaRegistro,
    String? rol,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      rol: rol ?? this.rol,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, nombre: $nombre, telefono: $telefono, rol: $rol)';
  }
}
