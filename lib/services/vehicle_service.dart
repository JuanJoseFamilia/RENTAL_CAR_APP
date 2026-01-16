//lib/services/vehicle_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle_model.dart';
import '../utils/constants.dart';
import 'cache_service.dart';

class VehicleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int pageSize = 20; // Cantidad de vehículos por página

  // ✅ OPTIMIZADO: Obtener todos los vehículos con caché
  Stream<List<VehicleModel>> getAllVehicles() {
    // Primero, retornar caché si disponible
    final cached = CacheService.getCachedVehicles();
    if (cached != null && CacheService.isVehiclesCacheValid()) {
      return Stream.value(cached).asBroadcastStream();
    }

    return _firestore
        .collection(FirebaseCollections.vehicles)
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) {
      final vehicles = snapshot.docs
          .map((doc) => VehicleModel.fromMap(doc.data(), doc.id))
          .toList();
      
      // Guardar en caché después de obtener
      CacheService.cacheVehicles(vehicles).catchError((_) {});
      
      return vehicles;
    });
  }

  // ✅ OPTIMIZADO: Obtener solo vehículos disponibles (con límite)
  Stream<List<VehicleModel>> getAvailableVehicles() {
    return _firestore
        .collection(FirebaseCollections.vehicles)
        .where('disponible', isEqualTo: true)
        .orderBy('fechaCreacion', descending: true)
        .limit(pageSize) // ✅ LÍMITE: evita descargar todos
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VehicleModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ✅ NUEVO: Obtener página siguiente de vehículos disponibles
  Future<List<VehicleModel>> getAvailableVehiclesPage(
    int pageNumber, {
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection(FirebaseCollections.vehicles)
          .where('disponible', isEqualTo: true)
          .orderBy('fechaCreacion', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.limit(pageSize).get();

      return snapshot.docs
          .map((doc) => VehicleModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw 'Error al obtener página de vehículos: $e';
    }
  }

  // Obtener un vehículo por ID
  Future<VehicleModel?> getVehicleById(String vehicleId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.vehicles)
          .doc(vehicleId)
          .get();

      if (!doc.exists) return null;

      return VehicleModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw 'Error al obtener vehículo: $e';
    }
  }

  // ✅ OPTIMIZADO: Buscar vehículos con texto (ahora filtra en Firestore si es posible)
  Future<List<VehicleModel>> searchVehicles(String query) async {
    try {
      if (query.isEmpty) {
        final snapshot = await _firestore
            .collection(FirebaseCollections.vehicles)
            .where('disponible', isEqualTo: true)
            .limit(pageSize)
            .get();

        return snapshot.docs
            .map((doc) => VehicleModel.fromMap(doc.data(), doc.id))
            .toList();
      }

      final queryLower = query.toLowerCase();

      // ✅ MEJORA: Obtener con límite y filtrar en cliente
      // (Firestore no soporta búsqueda por texto completo directamente)
      final snapshot = await _firestore
          .collection(FirebaseCollections.vehicles)
          .where('disponible', isEqualTo: true)
          .limit(pageSize * 3) // Obtener más para mejorar resultados de búsqueda
          .get();

      return snapshot.docs
          .map((doc) => VehicleModel.fromMap(doc.data(), doc.id))
          .where((vehicle) =>
              vehicle.marca.toLowerCase().contains(queryLower) ||
              vehicle.modelo.toLowerCase().contains(queryLower))
          .toList()
          .take(pageSize) // Limitar resultados finales
          .toList();
    } catch (e) {
      throw 'Error al buscar vehículos: $e';
    }
  }

  // Filtrar vehículos por tipo
  Stream<List<VehicleModel>> getVehiclesByType(String tipo) {
    return _firestore
        .collection(FirebaseCollections.vehicles)
        .where('tipo', isEqualTo: tipo)
        .where('disponible', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VehicleModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Filtrar vehículos por rango de precio
  Future<List<VehicleModel>> getVehiclesByPriceRange({
    required double minPrice,
    required double maxPrice,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.vehicles)
          .where('disponible', isEqualTo: true)
          .where('precioPorDia', isGreaterThanOrEqualTo: minPrice)
          .where('precioPorDia', isLessThanOrEqualTo: maxPrice)
          .get();

      return snapshot.docs
          .map((doc) => VehicleModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw 'Error al filtrar por precio: $e';
    }
  }

  // Actualizar calificación del vehículo
  Future<void> updateVehicleRating({
    required String vehicleId,
    required double newRating,
  }) async {
    try {
      final vehicleDoc = await _firestore
          .collection(FirebaseCollections.vehicles)
          .doc(vehicleId)
          .get();

      if (!vehicleDoc.exists) {
        throw 'Vehículo no encontrado';
      }

      final vehicle = VehicleModel.fromMap(vehicleDoc.data()!, vehicleDoc.id);

      final totalCalificaciones = vehicle.totalCalificaciones + 1;
      final sumaCalificaciones =
          (vehicle.calificacionPromedio * vehicle.totalCalificaciones) +
              newRating;
      final nuevoPromedio = sumaCalificaciones / totalCalificaciones;

      await _firestore
          .collection(FirebaseCollections.vehicles)
          .doc(vehicleId)
          .update({
        'calificacionPromedio': nuevoPromedio,
        'totalCalificaciones': totalCalificaciones,
      });
    } catch (e) {
      throw 'Error al actualizar calificación: $e';
    }
  }

  // Generar un nuevo ID para un vehículo (no crea el documento)
  String newVehicleId() {
    return _firestore.collection(FirebaseCollections.vehicles).doc().id;
  }

  // Crear nuevo vehículo (solo admin). Si se provee `id`, se usará ese ID en lugar de add().
  Future<String> createVehicle(VehicleModel vehicle, {String? id}) async {
    try {
      if (id == null) {
        final docRef = await _firestore
            .collection(FirebaseCollections.vehicles)
            .add(vehicle.toMap());
        return docRef.id;
      } else {
        await _firestore
            .collection(FirebaseCollections.vehicles)
            .doc(id)
            .set(vehicle.toMap());
        return id;
      }
    } catch (e) {
      throw 'Error al crear vehículo: $e';
    }
  }

  // Actualizar vehículo (solo admin)
  Future<void> updateVehicle(
      String vehicleId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(FirebaseCollections.vehicles)
          .doc(vehicleId)
          .update(data);
    } catch (e) {
      throw 'Error al actualizar vehículo: $e';
    }
  }

  // Eliminar vehículo (solo admin)
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await _firestore
          .collection(FirebaseCollections.vehicles)
          .doc(vehicleId)
          .delete();
    } catch (e) {
      throw 'Error al eliminar vehículo: $e';
    }
  }

  // Cambiar disponibilidad del vehículo
  Future<void> toggleVehicleAvailability(
      String vehicleId, bool disponible) async {
    try {
      await _firestore
          .collection(FirebaseCollections.vehicles)
          .doc(vehicleId)
          .update({'disponible': disponible});
    } catch (e) {
      throw 'Error al cambiar disponibilidad: $e';
    }
  }
}
