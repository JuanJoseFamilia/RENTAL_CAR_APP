//lib/services/review_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';
import '../utils/constants.dart';
import 'vehicle_service.dart';
import 'reservation_service.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final VehicleService _vehicleService = VehicleService();
  final ReservationService _reservationService = ReservationService();

  // Verificar si un usuario puede dejar reseña para una reserva
  Future<bool> canUserReview({
    required String userId,
    required String reservationId,
  }) async {
    try {
      // Obtener la reserva
      final reservation =
          await _reservationService.getReservationById(reservationId);

      if (reservation == null) {
        return false;
      }

      // Verificar que la reserva pertenezca al usuario
      if (reservation.userId != userId) {
        return false;
      }

      // Verificar que la reserva esté completada
      if (reservation.estado != ReservationStatus.completed) {
        return false;
      }

      // Verificar que no haya dejado reseña previamente
      final existingReview = await _firestore
          .collection(FirebaseCollections.reviews)
          .where('userId', isEqualTo: userId)
          .where('reservationId', isEqualTo: reservationId)
          .limit(1)
          .get();

      return existingReview.docs.isEmpty;
    } catch (e) {
      throw 'Error al verificar permisos de reseña: $e';
    }
  }

  // Crear una nueva reseña
  Future<String> createReview({
    required String userId,
    required String vehicleId,
    required String reservationId,
    required int calificacion,
    required String comentario,
    required String nombreUsuario,
  }) async {
    try {
      // Verificar que el usuario pueda dejar reseña
      final canReview = await canUserReview(
        userId: userId,
        reservationId: reservationId,
      );

      if (!canReview) {
        throw 'No tienes permiso para dejar esta reseña';
      }

      // Crear reseña
      final review = ReviewModel(
        id: '',
        userId: userId,
        vehicleId: vehicleId,
        reservationId: reservationId,
        calificacion: calificacion,
        comentario: comentario,
        fecha: DateTime.now(),
        nombreUsuario: nombreUsuario,
      );

      final docRef = await _firestore
          .collection(FirebaseCollections.reviews)
          .add(review.toMap());

      // Actualizar calificación promedio del vehículo
      await _vehicleService.updateVehicleRating(
        vehicleId: vehicleId,
        newRating: calificacion.toDouble(),
      );

      return docRef.id;
    } catch (e) {
      throw 'Error al crear reseña: $e';
    }
  }

  // Obtener reseñas de un vehículo
  Stream<List<ReviewModel>> getVehicleReviews(String vehicleId) {
    return _firestore
        .collection(FirebaseCollections.reviews)
        .where('vehicleId', isEqualTo: vehicleId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Obtener reseñas de un usuario
  Stream<List<ReviewModel>> getUserReviews(String userId) {
    return _firestore
        .collection(FirebaseCollections.reviews)
        .where('userId', isEqualTo: userId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Obtener una reseña por ID
  Future<ReviewModel?> getReviewById(String reviewId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.reviews)
          .doc(reviewId)
          .get();

      if (!doc.exists) return null;

      return ReviewModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw 'Error al obtener reseña: $e';
    }
  }

  // Verificar si existe una reseña para una reserva
  Future<ReviewModel?> getReviewByReservation(String reservationId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.reviews)
          .where('reservationId', isEqualTo: reservationId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return ReviewModel.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    } catch (e) {
      throw 'Error al buscar reseña: $e';
    }
  }

  // Actualizar reseña (deshabilitado): las reseñas no se pueden editar una vez creadas.
  // Si se requiere edición por parte de un admin, implementar un método separado con comprobaciones de permisos.
  Future<void> updateReview({
    required String reviewId,
    required int calificacion,
    required String comentario,
  }) async {
    // Rechazamos cualquier intento de edición desde la app cliente.
    throw 'Edición de reseñas no permitida';
  }

  // Eliminar reseña
  Future<void> deleteReview(String reviewId) async {
    try {
      await _firestore
          .collection(FirebaseCollections.reviews)
          .doc(reviewId)
          .delete();
    } catch (e) {
      throw 'Error al eliminar reseña: $e';
    }
  }

  // Obtener estadísticas de reseñas de un vehículo
  Future<Map<String, dynamic>> getVehicleReviewStats(String vehicleId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.reviews)
          .where('vehicleId', isEqualTo: vehicleId)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'total': 0,
          'promedio': 0.0,
          'distribución': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        };
      }

      final reviews = snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
          .toList();

      final total = reviews.length;
      final suma = reviews.fold(0, (acc, review) => acc + review.calificacion);
      final promedio = suma / total;

      final distribucion = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      for (var review in reviews) {
        distribucion[review.calificacion] =
            distribucion[review.calificacion]! + 1;
      }

      return {
        'total': total,
        'promedio': promedio,
        'distribución': distribucion,
      };
    } catch (e) {
      throw 'Error al obtener estadísticas: $e';
    }
  }
}
