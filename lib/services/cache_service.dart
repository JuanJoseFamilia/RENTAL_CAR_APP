import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/vehicle_model.dart';
import '../models/reservation_model.dart';
import '../models/user_model.dart';

class CacheService {
  static const String vehiclesBox = 'vehicles_cache';
  static const String reservationsBox = 'reservations_cache';
  static const String userBox = 'user_cache';
  static const String metadataBox = 'cache_metadata';

  // Inicializar caché (llamar una sola vez en main.dart)
  static Future<void> initializeCache() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(vehiclesBox);
    await Hive.openBox<String>(reservationsBox);
    await Hive.openBox<String>(userBox);
    await Hive.openBox<Map>(metadataBox);
  }

  // ============ VEHÍCULOS ============

  /// Guardar lista de vehículos en caché
  static Future<void> cacheVehicles(List<VehicleModel> vehicles) async {
    final box = Hive.box<String>(vehiclesBox);
    final jsonList = vehicles.map((v) => jsonEncode(v.toMap())).toList();
    
    await box.clear();
    for (int i = 0; i < jsonList.length; i++) {
      await box.put('vehicle_$i', jsonList[i]);
    }
    
    // Guardar timestamp de cuándo se cacheó
    await _setMetadata('vehicles_timestamp', DateTime.now().millisecondsSinceEpoch);
    await _setMetadata('vehicles_count', vehicles.length);
  }

  /// Obtener vehículos del caché
  static List<VehicleModel>? getCachedVehicles() {
    final box = Hive.box<String>(vehiclesBox);
    if (box.isEmpty) return null;

    try {
      final vehicles = <VehicleModel>[];
      for (var key in box.keys) {
        final jsonString = box.get(key);
        if (jsonString != null) {
          final json = jsonDecode(jsonString);
          vehicles.add(VehicleModel.fromMap(json, key as String));
        }
      }
      return vehicles;
    } catch (e) {
      if (kDebugMode) print('Error al deserializar vehículos: $e');
      return null;
    }
  }

  /// Verificar si caché de vehículos es válido (< 1 hora)
  static bool isVehiclesCacheValid() {
    final timestamp = _getMetadata('vehicles_timestamp');
    if (timestamp == null) return false;

    final cacheAge = DateTime.now().millisecondsSinceEpoch - (timestamp as int);
    final oneHourMs = 60 * 60 * 1000;
    return cacheAge < oneHourMs;
  }

  /// Limpiar caché de vehículos
  static Future<void> clearVehiclesCache() async {
    await Hive.box<String>(vehiclesBox).clear();
    await _removeMetadata('vehicles_timestamp');
  }

  // ============ RESERVACIONES ============

  /// Guardar reservaciones en caché
  static Future<void> cacheReservations(
    String userId,
    List<ReservationModel> reservations,
  ) async {
    final box = Hive.box<String>(reservationsBox);
    final jsonList = reservations.map((r) => jsonEncode(r.toMap())).toList();
    
    // Usar userId como prefijo
    await box.put('${userId}_count', jsonList.length.toString());
    for (int i = 0; i < jsonList.length; i++) {
      await box.put('${userId}_reservation_$i', jsonList[i]);
    }
    
    await _setMetadata('${userId}_reservations_timestamp', 
        DateTime.now().millisecondsSinceEpoch);
  }

  /// Obtener reservaciones del caché
  static List<ReservationModel>? getCachedReservations(String userId) {
    final box = Hive.box<String>(reservationsBox);
    final countStr = box.get('${userId}_count');
    if (countStr == null) return null;

    try {
      final count = int.parse(countStr);
      final reservations = <ReservationModel>[];
      
      for (int i = 0; i < count; i++) {
        final jsonString = box.get('${userId}_reservation_$i');
        if (jsonString != null) {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          reservations.add(ReservationModel.fromMap(json, userId));
        }
      }
      return reservations;
    } catch (e) {
      if (kDebugMode) print('Error al deserializar reservaciones: $e');
      return null;
    }
  }

  /// Verificar si caché de reservaciones es válido (< 30 minutos)
  static bool isReservationsCacheValid(String userId) {
    final timestamp = _getMetadata('${userId}_reservations_timestamp');
    if (timestamp == null) return false;

    final cacheAge = DateTime.now().millisecondsSinceEpoch - (timestamp as int);
    final thirtyMinMs = 30 * 60 * 1000;
    return cacheAge < thirtyMinMs;
  }

  /// Limpiar caché de reservaciones
  static Future<void> clearReservationsCache(String userId) async {
    final box = Hive.box<String>(reservationsBox);
    final countStr = box.get('${userId}_count');
    if (countStr != null) {
      final count = int.parse(countStr);
      for (int i = 0; i < count; i++) {
        await box.delete('${userId}_reservation_$i');
      }
      await box.delete('${userId}_count');
    }
    await _removeMetadata('${userId}_reservations_timestamp');
  }

  // ============ USUARIO ============

  /// Guardar datos de usuario en caché
  static Future<void> cacheUser(UserModel user) async {
    final box = Hive.box<String>(userBox);
    await box.put('current_user', jsonEncode(user.toMap()));
    await box.put('current_user_id', user.id);
    await _setMetadata('user_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  /// Obtener usuario del caché
  static UserModel? getCachedUser() {
    final box = Hive.box<String>(userBox);
    final jsonString = box.get('current_user');
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final userId = box.get('current_user_id') ?? 'cached_user';
      return UserModel.fromMap(json, userId);
    } catch (e) {
      if (kDebugMode) print('Error al deserializar usuario: $e');
      return null;
    }
  }

  /// Limpiar caché de usuario
  static Future<void> clearUserCache() async {
    await Hive.box<String>(userBox).clear();
    await _removeMetadata('user_timestamp');
  }

  // ============ METADATA HELPERS ============

  static dynamic _getMetadata(String key) {
    final box = Hive.box<Map>(metadataBox);
    return box.get(key);
  }

  static Future<void> _setMetadata(String key, dynamic value) async {
    final box = Hive.box<Map>(metadataBox);
    await box.put(key, {'value': value, 'timestamp': DateTime.now()});
  }

  static Future<void> _removeMetadata(String key) async {
    final box = Hive.box<Map>(metadataBox);
    await box.delete(key);
  }

  /// Limpiar todo el caché
  static Future<void> clearAllCache() async {
    await Hive.box<String>(vehiclesBox).clear();
    await Hive.box<String>(reservationsBox).clear();
    await Hive.box<String>(userBox).clear();
    await Hive.box<Map>(metadataBox).clear();
  }

  /// Obtener información de caché (para debugging)
  static Map<String, dynamic> getCacheStats() {
    return {
      'vehicles_cached': Hive.box<String>(vehiclesBox).length,
      'reservations_cached': Hive.box<String>(reservationsBox).length,
      'user_cached': Hive.box<String>(userBox).isNotEmpty,
      'cache_valid': {
        'vehicles': isVehiclesCacheValid(),
        'user': _getMetadata('user_timestamp') != null,
      }
    };
  }
}
