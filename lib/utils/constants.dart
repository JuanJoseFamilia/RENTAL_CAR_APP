// lib/utils/constants.dart
import 'package:flutter/material.dart';

// Colores de la aplicación
class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFFFF9800);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color background = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFFE0E0E0);
  // Color para mensajes entrantes (chat)
  static const Color chatIncoming = Color(0xFF616161);
}

// Textos y Strings
class AppStrings {
  static const String appName = 'RentalCar';
  static const String login = 'Iniciar Sesión';
  static const String register = 'Registrarse';
  static const String email = 'Correo Electrónico';
  static const String password = 'Contraseña';
  static const String confirmPassword = 'Confirmar Contraseña';
  static const String name = 'Nombre Completo';
  static const String phone = 'Teléfono';
  static const String forgotPassword = '¿Olvidaste tu contraseña?';
  static const String dontHaveAccount = '¿No tienes cuenta?';
  static const String alreadyHaveAccount = '¿Ya tienes cuenta?';

  // Home
  static const String availableVehicles = 'Vehículos Disponibles';
  static const String searchVehicle = 'Buscar vehículo...';
  static const String filters = 'Filtros';

  // Vehicle
  static const String perDay = 'por día';
  static const String bookNow = 'Reservar Ahora';
  static const String vehicleDetails = 'Detalles del Vehículo';
  static const String capacity = 'Capacidad';
  static const String transmission = 'Transmisión';
  static const String year = 'Año';
  static const String reviews = 'Reseñas';

  // Reservations
  static const String myReservations = 'Mis Reservas';
  static const String active = 'Activas';
  static const String completed = 'Completadas';
  static const String cancelled = 'Canceladas';
  static const String startDate = 'Fecha de Inicio';
  static const String endDate = 'Fecha de Fin';
  static const String totalPrice = 'Precio Total';
  static const String days = 'días';
  static const String confirmReservation = 'Confirmar Reserva';
  static const String cancelReservation = 'Cancelar Reserva';

  // Reviews
  static const String leaveReview = 'Dejar Reseña';
  static const String rating = 'Calificación';
  static const String comment = 'Comentario';
  static const String submitReview = 'Enviar Reseña';
  static const String rateYourExperience = 'Califica tu experiencia';

  // Profile
  static const String profile = 'Perfil';
  static const String editProfile = 'Editar Perfil';
  static const String logout = 'Cerrar Sesión';
  static const String saveChanges = 'Guardar Cambios';

  // Messages
  static const String success = 'Éxito';
  static const String error = 'Error';
  static const String loading = 'Cargando...';
  static const String noVehiclesFound = 'No se encontraron vehículos';
  static const String noReservationsFound = 'No tienes reservas';
  static const String vehicleNotAvailable =
      'Vehículo no disponible en estas fechas';
  static const String reservationSuccess = 'Reserva realizada exitosamente';
  static const String reviewSuccess = 'Reseña enviada exitosamente';
  static const String loginSuccess = 'Inicio de sesión exitoso';
  static const String registerSuccess = 'Registro exitoso';
  static const String logoutSuccess = 'Sesión cerrada';
}

// Tipos de vehículos
class VehicleTypes {
  static const String sedan = 'Sedan';
  static const String suv = 'SUV';
  static const String pickup = 'Pickup';
  static const String van = 'Van';
  static const String coupe = 'Coupe';
  static const String hatchback = 'Hatchback';

  static List<String> get all => [sedan, suv, pickup, van, coupe, hatchback];
}

// Tipos de transmisión
class TransmissionTypes {
  static const String manual = 'Manual';
  static const String automatic = 'Automática';

  static List<String> get all => [manual, automatic];
}

// Estados de reserva
class ReservationStatus {
  static const String pending = 'pendiente';
  static const String confirmed = 'confirmada';
  static const String completed = 'completada';
  static const String cancelled = 'cancelada';
}

// Colecciones de Firebase
class FirebaseCollections {
  static const String users = 'users';
  static const String vehicles = 'vehicles';
  static const String reservations = 'reservations';
  static const String reviews = 'reviews';
}

// Espaciados
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// Border Radius
class AppBorderRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}

// Tamaños de fuente
class AppFontSizes {
  static const double xs = 12.0;
  static const double sm = 14.0;
  static const double md = 16.0;
  static const double lg = 18.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}
