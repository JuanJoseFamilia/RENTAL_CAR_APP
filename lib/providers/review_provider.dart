//lib/providers/review_provider.dart
import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

class ReviewProvider with ChangeNotifier {
  final ReviewService _reviewService = ReviewService();

  List<ReviewModel> _vehicleReviews = [];
  List<ReviewModel> _userReviews = [];
  ReviewModel? _selectedReview;
  Map<String, dynamic>? _reviewStats;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ReviewModel> get vehicleReviews => _vehicleReviews;
  List<ReviewModel> get userReviews => _userReviews;
  ReviewModel? get selectedReview => _selectedReview;
  Map<String, dynamic>? get reviewStats => _reviewStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Cargar reseñas de un vehículo
  void loadVehicleReviews(String vehicleId) {
    _reviewService.getVehicleReviews(vehicleId).listen(
      (reviews) {
        _vehicleReviews = reviews;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  // Cargar reseñas de un usuario
  void loadUserReviews(String userId) {
    _reviewService.getUserReviews(userId).listen(
      (reviews) {
        _userReviews = reviews;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  // Verificar si el usuario puede dejar reseña
  Future<bool> canUserReview({
    required String userId,
    required String reservationId,
  }) async {
    try {
      return await _reviewService.canUserReview(
        userId: userId,
        reservationId: reservationId,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Crear nueva reseña
  Future<bool> createReview({
    required String userId,
    required String vehicleId,
    required String reservationId,
    required int calificacion,
    required String comentario,
    required String nombreUsuario,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _reviewService.createReview(
        userId: userId,
        vehicleId: vehicleId,
        reservationId: reservationId,
        calificacion: calificacion,
        comentario: comentario,
        nombreUsuario: nombreUsuario,
      );

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

  // Obtener reseña por reserva
  Future<ReviewModel?> getReviewByReservation(String reservationId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final review = await _reviewService.getReviewByReservation(reservationId);

      _isLoading = false;
      notifyListeners();
      return review;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Cargar estadísticas de reseñas
  Future<void> loadReviewStats(String vehicleId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _reviewStats = await _reviewService.getVehicleReviewStats(vehicleId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Actualizar reseña
  Future<bool> updateReview({
    required String reviewId,
    required int calificacion,
    required String comentario,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _reviewService.updateReview(
        reviewId: reviewId,
        calificacion: calificacion,
        comentario: comentario,
      );

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

  // Eliminar reseña
  Future<bool> deleteReview(String reviewId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _reviewService.deleteReview(reviewId);

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

  // Limpiar reseñas del vehículo
  void clearVehicleReviews() {
    _vehicleReviews = [];
    _reviewStats = null;
    notifyListeners();
  }

  // Limpiar error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
