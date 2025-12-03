import 'package:flutter/material.dart';
import '../models/reservation_model.dart';
import '../services/reservation_service.dart';

class AdminReservationProvider with ChangeNotifier {
  final ReservationService _reservationService = ReservationService();

  List<ReservationModel> _allReservations = [];
  List<ReservationModel> _filteredReservations = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedFilter =
      'todas'; // todas, pendiente, confirmada, completada, cancelada

  // Getters
  List<ReservationModel> get allReservations => _allReservations;
  List<ReservationModel> get filteredReservations => _filteredReservations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedFilter => _selectedFilter;

  // Estadísticas
  int get totalReservations => _allReservations.length;
  int get pendingReservations =>
      _allReservations.where((r) => r.estado == 'pendiente').length;
  int get confirmedReservations =>
      _allReservations.where((r) => r.estado == 'confirmada').length;
  int get completedReservations =>
      _allReservations.where((r) => r.estado == 'completada').length;
  int get cancelledReservations =>
      _allReservations.where((r) => r.estado == 'cancelada').length;

  // Cargar todas las reservaciones
  Future<void> loadAllReservations() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Aquí usamos el stream para obtener datos en tiempo real
      _reservationService.getAllReservations().listen(
        (reservations) async {
          _allReservations = reservations;

          // Enriquecer con datos de vehículos y usuarios
          for (int i = 0; i < _allReservations.length; i++) {
            _allReservations[i] = await _reservationService
                .enrichReservationWithVehicleData(_allReservations[i]);
            _allReservations[i] = await _reservationService
                .enrichReservationWithUserData(_allReservations[i]);
          }

          _applyFilter();
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Aplicar filtro
  void _applyFilter() {
    if (_selectedFilter == 'todas') {
      _filteredReservations = List.from(_allReservations);
    } else {
      _filteredReservations = _allReservations
          .where((reservation) => reservation.estado == _selectedFilter)
          .toList();
    }
  }

  // Cambiar filtro
  void setFilter(String filter) {
    _selectedFilter = filter;
    _applyFilter();
    notifyListeners();
  }

  // Actualizar estado de una reservación
  Future<bool> updateReservationStatus(
      String reservationId, String newStatus) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _reservationService.updateReservationStatus(
          reservationId, newStatus);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Obtener detalles completos de una reservación
  Future<ReservationModel?> getReservationDetails(String reservationId) async {
    try {
      return await _reservationService
          .getReservationWithFullData(reservationId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Limpiar errores
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Buscar reservaciones por nombre de usuario o vehículo
  void searchReservations(String query) {
    if (query.isEmpty) {
      _applyFilter();
      notifyListeners();
      return;
    }

    final lowerQuery = query.toLowerCase();

    List<ReservationModel> baseList = _selectedFilter == 'todas'
        ? _allReservations
        : _allReservations.where((r) => r.estado == _selectedFilter).toList();

    _filteredReservations = baseList.where((reservation) {
      final userName = (reservation.userName ?? '').toLowerCase();
      final vehicleName = reservation.vehicleNombre.toLowerCase();

      return userName.contains(lowerQuery) || vehicleName.contains(lowerQuery);
    }).toList();

    notifyListeners();
  }
}
