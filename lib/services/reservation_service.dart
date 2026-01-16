import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/reservation_model.dart';
import '../models/vehicle_model.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import 'chat_service.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Verificar disponibilidad de un vehículo en fechas específicas
  Future<bool> checkVehicleAvailability({
    required String vehicleId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? excludeReservationId,
  }) async {
    try {
      final fechaInicioSolo = AppDateUtils.getDateOnly(fechaInicio);
      final fechaFinSolo = AppDateUtils.getDateOnly(fechaFin);

      Query query = _firestore
          .collection(FirebaseCollections.reservations)
          .where('vehicleId', isEqualTo: vehicleId)
          .where('estado', whereIn: ['pendiente', 'confirmada']);

      final snapshot = await query.get();

      for (var doc in snapshot.docs) {
        if (excludeReservationId != null && doc.id == excludeReservationId) {
          continue;
        }

        final reservation = ReservationModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
        final resInicio = AppDateUtils.getDateOnly(reservation.fechaInicio);
        final resFin = AppDateUtils.getDateOnly(reservation.fechaFin);

        if (!(fechaFinSolo.isBefore(resInicio) ||
            fechaInicioSolo.isAfter(resFin))) {
          return false;
        }
      }

      return true;
    } catch (e) {
      throw 'Error al verificar disponibilidad: $e';
    }
  }

  // Crear una nueva reserva
  Future<String> createReservation({
    required String userId,
    required String vehicleId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required double precioPorDia,
  }) async {
    try {
      // Normalizar las fechas a mediodía para evitar desfaces por zona horaria al guardar en Firestore
      final normalizedStart = DateTime(
          fechaInicio.year, fechaInicio.month, fechaInicio.day, 12, 0, 0);
      final normalizedEnd = DateTime(
          fechaFin.year, fechaFin.month, fechaFin.day, 12, 0, 0);

      final isAvailable = await checkVehicleAvailability(
        vehicleId: vehicleId,
        fechaInicio: normalizedStart,
        fechaFin: normalizedEnd,
      );

      if (!isAvailable) {
        throw 'El vehículo no está disponible en estas fechas';
      }

      final dias = AppDateUtils.daysBetween(normalizedStart, normalizedEnd) + 1;
      final precioTotal = dias * precioPorDia;

      final reservation = ReservationModel(
        id: '',
        userId: userId,
        vehicleId: vehicleId,
        fechaInicio: normalizedStart,
        fechaFin: normalizedEnd,
        precioTotal: precioTotal,
        estado: ReservationStatus.confirmed,
        fechaReserva: DateTime.now(),
        diasAlquiler: dias,
      );

      final docRef = await _firestore
          .collection(FirebaseCollections.reservations)
          .add(reservation.toMap());

      final reservationId = docRef.id;

      // Crear conversación inicial con mensaje de bienvenida del administrador
      try {
        final convId = await ChatService().ensureConversation(
          reservationId: reservationId,
          vehicleId: vehicleId,
          userId: userId,
          welcomeMessage: 'Reserva creada',
        );

        // Pequeño delay para asegurar que Firestore sincronice si la conversación fue creada por Cloud Function
        await Future.delayed(const Duration(milliseconds: 500));

        // Cargar datos completos de la reservación
        final completeReservation = await getReservationWithFullData(reservationId);
        
        if (completeReservation != null) {
          // Construir nombre completo del vehículo
          final vehicleName = <String>[
            if (completeReservation.vehicleMarca != null && completeReservation.vehicleMarca!.isNotEmpty) completeReservation.vehicleMarca!,
            if (completeReservation.vehicleModelo != null && completeReservation.vehicleModelo!.isNotEmpty) completeReservation.vehicleModelo!,
          ].join(' ');

          // Generar el voucher detallado
          final voucherText = ChatService().generateReservationVoucher(
            reservationId: reservationId,
            clientName: completeReservation.userName ?? userId,
            vehicleName: vehicleName.isNotEmpty ? vehicleName : 'Vehículo confirmado',
            startDate: completeReservation.fechaInicio,
            endDate: completeReservation.fechaFin,
            days: completeReservation.diasAlquiler,
            totalPrice: completeReservation.precioTotal,
            status: completeReservation.estado,
          );

          // Enviar el voucher detallado como mensaje de admin
          // Esto se ejecutará incluso si la Cloud Function ya creó la conversación
          await ChatService().sendMessage(
            conversationId: convId,
            senderId: 'admin',
            senderRole: 'admin',
            text: voucherText,
          );
        }
      } catch (e) {
        // No bloqueamos el flujo principal si la creación de la conversación falla,
        // pero registramos el error para diagnóstico.
        debugPrint('Error creando conversación inicial: $e');
      }

      return reservationId;
    } catch (e) {
      throw 'Error al crear reserva: $e';
    }
  }

  // Obtener reservas de un usuario
  Stream<List<ReservationModel>> getUserReservations(String userId) {
    return _firestore
        .collection(FirebaseCollections.reservations)
        .where('userId', isEqualTo: userId)
        .orderBy('fechaReserva', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReservationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Obtener reservas activas de un usuario
  Stream<List<ReservationModel>> getActiveReservations(String userId) {
    return _firestore
        .collection(FirebaseCollections.reservations)
        .where('userId', isEqualTo: userId)
        .where('estado', whereIn: ['pendiente', 'confirmada'])
        .orderBy('fechaInicio', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReservationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Obtener reservas completadas de un usuario
  Stream<List<ReservationModel>> getCompletedReservations(String userId) {
    return _firestore
        .collection(FirebaseCollections.reservations)
        .where('userId', isEqualTo: userId)
        .where('estado', isEqualTo: ReservationStatus.completed)
        .orderBy('fechaFin', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReservationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ============ NUEVOS MÉTODOS PARA ADMIN ============

  // Obtener TODAS las reservaciones (para admin)
  Stream<List<ReservationModel>> getAllReservations() {
    return _firestore
        .collection(FirebaseCollections.reservations)
        .orderBy('fechaReserva', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReservationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Obtener todas las reservaciones con filtro de estado
  Stream<List<ReservationModel>> getAllReservationsByStatus(String estado) {
    return _firestore
        .collection(FirebaseCollections.reservations)
        .where('estado', isEqualTo: estado)
        .orderBy('fechaReserva', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReservationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Obtener reservación con datos completos (usuario y vehículo)
  Future<ReservationModel?> getReservationWithFullData(
      String reservationId) async {
    try {
      final reservation = await getReservationById(reservationId);
      if (reservation == null) return null;

      // Obtener datos del vehículo
      final vehicleDoc = await _firestore
          .collection(FirebaseCollections.vehicles)
          .doc(reservation.vehicleId)
          .get();

      // Obtener datos del usuario
      final userName = await getUserName(reservation.userId);

      ReservationModel enrichedReservation = reservation;

      if (vehicleDoc.exists) {
        final vehicle = VehicleModel.fromMap(vehicleDoc.data()!, vehicleDoc.id);
        enrichedReservation = enrichedReservation.copyWith(
          vehicleMarca: vehicle.marca,
          vehicleModelo: vehicle.modelo,
          vehicleImagenUrl: vehicle.portada,
        );
      }

      if (userName != null) {
        enrichedReservation = enrichedReservation.copyWith(
          userName: userName,
        );
      }

      return enrichedReservation;
    } catch (e) {
      throw 'Error al obtener reserva con datos completos: $e';
    }
  }

  // Cargar datos de vehículo para una reservación
  Future<ReservationModel> enrichReservationWithVehicleData(
      ReservationModel reservation) async {
    try {
      final vehicleDoc = await _firestore
          .collection(FirebaseCollections.vehicles)
          .doc(reservation.vehicleId)
          .get();

      if (vehicleDoc.exists) {
        final vehicle = VehicleModel.fromMap(vehicleDoc.data()!, vehicleDoc.id);
        return reservation.copyWith(
          vehicleMarca: vehicle.marca,
          vehicleModelo: vehicle.modelo,
          vehicleImagenUrl: vehicle.portada,
        );
      }

      return reservation;
    } catch (e) {
      return reservation;
    }
  }

  // Cargar datos de usuario para una reservación
  Future<ReservationModel> enrichReservationWithUserData(
      ReservationModel reservation) async {
    try {
      final userName = await getUserName(reservation.userId);
      if (userName != null) {
        return reservation.copyWith(userName: userName);
      }
      return reservation;
    } catch (e) {
      return reservation;
    }
  }

  // ============ FIN NUEVOS MÉTODOS ============

  // Obtener una reserva por ID
  Future<ReservationModel?> getReservationById(String reservationId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.reservations)
          .doc(reservationId)
          .get();

      if (!doc.exists) return null;

      return ReservationModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw 'Error al obtener reserva: $e';
    }
  }

  // Obtener reserva con datos del vehículo
  Future<ReservationModel?> getReservationWithVehicleData(
      String reservationId) async {
    try {
      final reservation = await getReservationById(reservationId);
      if (reservation == null) return null;

      final vehicleDoc = await _firestore
          .collection(FirebaseCollections.vehicles)
          .doc(reservation.vehicleId)
          .get();

      if (vehicleDoc.exists) {
        final vehicle = VehicleModel.fromMap(vehicleDoc.data()!, vehicleDoc.id);
        return reservation.copyWith(
          vehicleMarca: vehicle.marca,
          vehicleModelo: vehicle.modelo,
          vehicleImagenUrl: vehicle.portada,
        );
      }

      return reservation;
    } catch (e) {
      throw 'Error al obtener reserva con datos: $e';
    }
  }

  // Cancelar reserva
  Future<void> cancelReservation(String reservationId) async {
    try {
      await _firestore
          .collection(FirebaseCollections.reservations)
          .doc(reservationId)
          .update({'estado': ReservationStatus.cancelled});
    } catch (e) {
      throw 'Error al cancelar reserva: $e';
    }
  }

  // Completar reserva
  Future<void> completeReservation(String reservationId) async {
    try {
      await _firestore
          .collection(FirebaseCollections.reservations)
          .doc(reservationId)
          .update({'estado': ReservationStatus.completed});
    } catch (e) {
      throw 'Error al completar reserva: $e';
    }
  }

  // Actualizar estado de reserva
  Future<void> updateReservationStatus(
      String reservationId, String newStatus) async {
    try {
      await _firestore
          .collection(FirebaseCollections.reservations)
          .doc(reservationId)
          .update({'estado': newStatus});
    } catch (e) {
      throw 'Error al actualizar estado: $e';
    }
  }

  // Obtener todas las reservas de un vehículo
  Future<List<ReservationModel>> getVehicleReservations(
      String vehicleId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.reservations)
          .where('vehicleId', isEqualTo: vehicleId)
          .where('estado', whereIn: ['pendiente', 'confirmada']).get();

      return snapshot.docs
          .map((doc) => ReservationModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw 'Error al obtener reservas del vehículo: $e';
    }
  }

  // Stream de reservas de un vehículo
  Stream<List<ReservationModel>> getReservationsByVehicleStream(
      String vehicleId) {
    return _firestore
        .collection(FirebaseCollections.reservations)
        .where('vehicleId', isEqualTo: vehicleId)
        .orderBy('fechaReserva', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReservationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Obtener el nombre de un usuario por su ID
  Future<String?> getUserName(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return data['nombre'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Verificar si un usuario tiene reservas completadas de un vehículo
  Future<bool> hasCompletedReservation({
    required String userId,
    required String vehicleId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.reservations)
          .where('userId', isEqualTo: userId)
          .where('vehicleId', isEqualTo: vehicleId)
          .where('estado', isEqualTo: ReservationStatus.completed)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw 'Error al verificar reservas: $e';
    }
  }
}
