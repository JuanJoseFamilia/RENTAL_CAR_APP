//lib/providers/vehicle_provider.dart
import 'package:flutter/material.dart';
import '../models/vehicle_model.dart';
import '../services/vehicle_service.dart';

class VehicleProvider with ChangeNotifier {
  final VehicleService _vehicleService = VehicleService();

  List<VehicleModel> _vehicles = [];
  List<VehicleModel> _filteredVehicles = [];
  VehicleModel? _selectedVehicle;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedType;
  double? _minPrice;
  double? _maxPrice;

  // Getters
  List<VehicleModel> get vehicles =>
      _filteredVehicles.isEmpty && _searchQuery.isEmpty && _selectedType == null
          ? _vehicles
          : _filteredVehicles;
  VehicleModel? get selectedVehicle => _selectedVehicle;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedType => _selectedType;

  // Cargar todos los vehículos disponibles
  void loadVehicles() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _vehicleService.getAvailableVehicles().listen(
      (vehiclesList) {
        _vehicles = vehiclesList;
        _isLoading = false;
        _errorMessage = null;
        _applyFilters();
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = 'Error al cargar vehículos: $error';
        print('Error en loadVehicles: $error'); // Para debug
        notifyListeners();
      },
    );
  }

  // Buscar vehículos
  Future<void> searchVehicles(String query) async {
    try {
      _searchQuery = query;
      _isLoading = true;
      notifyListeners();

      if (query.isEmpty) {
        _filteredVehicles = _vehicles;
      } else {
        final results = await _vehicleService.searchVehicles(query);
        _filteredVehicles = results;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Filtrar por tipo
  void filterByType(String? tipo) {
    _selectedType = tipo;
    _applyFilters();
    notifyListeners();
  }

  // Filtrar por rango de precio
  Future<void> filterByPrice({double? minPrice, double? maxPrice}) async {
    try {
      _minPrice = minPrice;
      _maxPrice = maxPrice;
      _isLoading = true;
      notifyListeners();

      if (minPrice != null && maxPrice != null) {
        final results = await _vehicleService.getVehiclesByPriceRange(
          minPrice: minPrice,
          maxPrice: maxPrice,
        );
        _filteredVehicles = results;
      } else {
        _filteredVehicles = _vehicles;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Aplicar filtros
  void _applyFilters() {
    _filteredVehicles = _vehicles;

    // Filtrar por tipo
    if (_selectedType != null && _selectedType!.isNotEmpty) {
      _filteredVehicles = _filteredVehicles
          .where((vehicle) => vehicle.tipo == _selectedType)
          .toList();
    }

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      _filteredVehicles = _filteredVehicles
          .where((vehicle) =>
              vehicle.marca.toLowerCase().contains(queryLower) ||
              vehicle.modelo.toLowerCase().contains(queryLower))
          .toList();
    }
  }

  // Limpiar filtros
  void clearFilters() {
    _searchQuery = '';
    _selectedType = null;
    _minPrice = null;
    _maxPrice = null;
    _filteredVehicles = _vehicles;
    notifyListeners();
  }

  // Seleccionar un vehículo
  Future<void> selectVehicle(String vehicleId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _selectedVehicle = await _vehicleService.getVehicleById(vehicleId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Limpiar vehículo seleccionado
  void clearSelectedVehicle() {
    _selectedVehicle = null;
    notifyListeners();
  }

  // Obtener vehículo por ID
  VehicleModel? getVehicleById(String vehicleId) {
    try {
      return _vehicles.firstWhere((vehicle) => vehicle.id == vehicleId);
    } catch (e) {
      return null;
    }
  }

  // Ordenar vehículos
  void sortVehicles(String sortBy) {
    switch (sortBy) {
      case 'price_asc':
        _filteredVehicles
            .sort((a, b) => a.precioPorDia.compareTo(b.precioPorDia));
        break;
      case 'price_desc':
        _filteredVehicles
            .sort((a, b) => b.precioPorDia.compareTo(a.precioPorDia));
        break;
      case 'rating_desc':
        _filteredVehicles.sort(
            (a, b) => b.calificacionPromedio.compareTo(a.calificacionPromedio));
        break;
      case 'name_asc':
        _filteredVehicles
            .sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
        break;
      default:
        // Por defecto, más recientes primero
        _filteredVehicles
            .sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
    }
    notifyListeners();
  }

  // Limpiar error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Recargar vehículos
  void reloadVehicles() {
    loadVehicles();
  }
}
