// lib/providers/reservation_provider.dart
import 'dart:async';

import 'package:flutter/material.dart';
import '../models/reservation_model.dart';
import '../services/reservation_service.dart';
import '../utils/date_utils.dart';

class ReservationProvider with ChangeNotifier {
  final ReservationService _reservationService = ReservationService();
  StreamSubscription<List<ReservationModel>>? _vehicleReservationsSub;
  StreamSubscription<List<ReservationModel>>? _activeVehicleReservationsSub;

  List<ReservationModel> _allReservations = [];
  List<ReservationModel> _activeReservations = [];
  List<ReservationModel> _completedReservations = [];
  List<ReservationModel> _cancelledReservations = [];
  ReservationModel? _selectedReservation;
  List<ReservationModel> _vehicleReservations = [];
  List<ReservationModel> _activeVehicleReservations = [];

  // Días bloqueados (solo reservas activas)
  Set<DateTime> _blockedDays = {};

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ReservationModel> get allReservations => _allReservations;
  List<ReservationModel> get activeReservations => _activeReservations;
  List<ReservationModel> get completedReservations => _completedReservations;
  List<ReservationModel> get cancelledReservations => _cancelledReservations;
  ReservationModel? get selectedReservation => _selectedReservation;
  List<ReservationModel> get vehicleReservations => _vehicleReservations;
  List<ReservationModel> get activeVehicleReservations => _activeVehicleReservations;
  Set<DateTime> get blockedDays => _blockedDays;
  bool isDayBlocked(DateTime day) => _blockedDays.contains(AppDateUtils.getDateOnly(day));

  DateTime? get selectedStartDate => _selectedStartDate;
  DateTime? get selectedEndDate => _selectedEndDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Calcular días seleccionados
  int get selectedDays {
    if (_selectedStartDate == null || _selectedEndDate == null) return 0;
    return AppDateUtils.daysBetween(_selectedStartDate!, _selectedEndDate!) + 1;
  }

  // Calcular precio total
  double calculateTotalPrice(double pricePerDay) {
    return selectedDays * pricePerDay;
  }

  // Cargar reservas del usuario
  void loadUserReservations(String userId) {
    _reservationService.getUserReservations(userId).listen(
      (reservations) {
        _allReservations = reservations;
        _categorizeReservations();
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  // Cargar reservas de un vehículo (para admin)
  void loadReservationsForVehicle(String vehicleId) {
    // Cancelar suscripción previa si existe
    _vehicleReservationsSub?.cancel();

    _vehicleReservationsSub =
        _reservationService.getReservationsByVehicleStream(vehicleId).listen(
      (reservations) async {
        try {
          // Filtrar por seguridad
          final filtered =
              reservations.where((r) => r.vehicleId == vehicleId).toList();

          if (filtered.isEmpty) {
            _vehicleReservations = [];
            notifyListeners();
            return;
          }

          // Enriquecer con nombre de usuario
          final futures = filtered.map((r) async {
            final name = await _reservationService.getUserName(r.userId);
            return r.copyWith(userName: name);
          }).toList();

          _vehicleReservations = await Future.wait(futures);

          notifyListeners();
        } catch (e) {
          _errorMessage = e.toString();
          notifyListeners();
        }
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  // Cargar solo reservas activas de un vehículo (pendiente/confirmada)
  void loadActiveReservationsForVehicle(String vehicleId) {
    _activeVehicleReservationsSub?.cancel();

    _activeVehicleReservationsSub =
        _reservationService.getReservationsByVehicleStream(vehicleId).listen(
      (reservations) async {
        try {
          final filtered = reservations
              .where((r) => r.vehicleId == vehicleId)
              .where((r) => r.estado == 'pendiente' || r.estado == 'confirmada')
              .toList();

          if (filtered.isEmpty) {
            _activeVehicleReservations = [];
            _blockedDays = {};
            notifyListeners();
            return;
          }

          final futures = filtered.map((r) async {
            final name = await _reservationService.getUserName(r.userId);
            return r.copyWith(userName: name);
          }).toList();

          _activeVehicleReservations = await Future.wait(futures);

          // Recalcular días bloqueados
          _computeBlockedDays();

          notifyListeners();
        } catch (e) {
          _errorMessage = e.toString();
          notifyListeners();
        }
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  // Calcular días bloqueados a partir de reservas activas
  void _computeBlockedDays() {
    final Set<DateTime> blocked = {};

    for (final r in _activeVehicleReservations) {
      final start = AppDateUtils.getDateOnly(r.fechaInicio);
      final end = AppDateUtils.getDateOnly(r.fechaFin);

      final totalDays = AppDateUtils.daysBetween(start, end);
      for (int i = 0; i <= totalDays; i++) {
        blocked.add(start.add(Duration(days: i)));
      }
    }

    _blockedDays = blocked;
  }

  // Verificar si un rango está libre localmente (sin días bloqueados)
  bool isRangeAvailable(DateTime start, DateTime end) {
    final s = AppDateUtils.getDateOnly(start);
    final e = AppDateUtils.getDateOnly(end);

    var current = s;
    while (!current.isAfter(e)) {
      if (_blockedDays.contains(current)) return false;
      current = current.add(const Duration(days: 1));
    }
    return true;
  }

  @override
  void dispose() {
    _vehicleReservationsSub?.cancel();
    _activeVehicleReservationsSub?.cancel();
    super.dispose();
  }

  // Actualizar estado de una reserva
  Future<bool> updateReservationStatus(
      String reservationId, String newStatus) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _reservationService.updateReservationStatus(
          reservationId, newStatus);

      // Actualizar lista local si existe
      final idx = _vehicleReservations.indexWhere((r) => r.id == reservationId);
      if (idx != -1) {
        _vehicleReservations[idx] =
            _vehicleReservations[idx].copyWith(estado: newStatus);
      }

      // Mantener lista activa sincronizada localmente y recalcular días bloqueados
      _activeVehicleReservations = _vehicleReservations
          .where((r) => r.estado == 'pendiente' || r.estado == 'confirmada')
          .toList();
      _computeBlockedDays();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Categorizar reservas por estado
  void _categorizeReservations() {
    _activeReservations = _allReservations
        .where((r) => r.estado == 'pendiente' || r.estado == 'confirmada')
        .toList();

    _completedReservations =
        _allReservations.where((r) => r.estado == 'completada').toList();

    _cancelledReservations =
        _allReservations.where((r) => r.estado == 'cancelada').toList();
  }

  // Seleccionar fechas
  void selectDates(DateTime? startDate, DateTime? endDate) {
    _selectedStartDate = startDate;
    _selectedEndDate = endDate;
    notifyListeners();
  }

  // Limpiar fechas seleccionadas
  void clearSelectedDates() {
    _selectedStartDate = null;
    _selectedEndDate = null;
    notifyListeners();
  }

  // Verificar disponibilidad
  Future<bool> checkAvailability({
    required String vehicleId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final isAvailable = await _reservationService.checkVehicleAvailability(
        vehicleId: vehicleId,
        fechaInicio: startDate,
        fechaFin: endDate,
      );

      _isLoading = false;
      notifyListeners();

      return isAvailable;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Crear nueva reserva
  Future<bool> createReservation({
    required String userId,
    required String vehicleId,
    required double pricePerDay,
  }) async {
    try {
      if (_selectedStartDate == null || _selectedEndDate == null) {
        _errorMessage = 'Debes seleccionar fechas válidas';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _reservationService.createReservation(
        userId: userId,
        vehicleId: vehicleId,
        fechaInicio: _selectedStartDate!,
        fechaFin: _selectedEndDate!,
        precioPorDia: pricePerDay,
      );

      // Recargar reservas activas del vehículo para actualizar días bloqueados inmediatamente
      loadActiveReservationsForVehicle(vehicleId);

      // Limpiar fechas seleccionadas
      clearSelectedDates();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Seleccionar una reserva
  Future<void> selectReservation(String reservationId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _selectedReservation = await _reservationService
          .getReservationWithVehicleData(reservationId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Limpiar reserva seleccionada
  void clearSelectedReservation() {
    _selectedReservation = null;
    notifyListeners();
  }

  // Cancelar reserva
  Future<bool> cancelReservation(String reservationId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _reservationService.cancelReservation(reservationId);

      // Actualizar listas locales inmediatamente
      final idx = _vehicleReservations.indexWhere((r) => r.id == reservationId);
      if (idx != -1) {
        _vehicleReservations[idx] =
            _vehicleReservations[idx].copyWith(estado: 'cancelada');
      }

      _activeVehicleReservations = _vehicleReservations
          .where((r) => r.estado == 'pendiente' || r.estado == 'confirmada')
          .toList();
      _computeBlockedDays();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Completar reserva
  Future<bool> completeReservation(String reservationId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _reservationService.completeReservation(reservationId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Verificar si el usuario tiene reservas completadas de un vehículo
  Future<bool> hasCompletedReservation({
    required String userId,
    required String vehicleId,
  }) async {
    try {
      return await _reservationService.hasCompletedReservation(
        userId: userId,
        vehicleId: vehicleId,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Limpiar error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Recargar reservas
  void reloadReservations(String userId) {
    loadUserReservations(userId);
  }
}
