// lib/utils/validators.dart
class Validators {
  // Validar email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo electrónico es requerido';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un correo electrónico válido';
    }

    return null;
  }

  // Validar contraseña
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    return null;
  }

  // Validar confirmación de contraseña
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }

    if (value != password) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  // Validar nombre
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es requerido';
    }

    if (value.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }

    return null;
  }

  // Validar teléfono
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es requerido';
    }

    final phoneRegex = RegExp(r'^[0-9]{10}$');

    if (!phoneRegex.hasMatch(value)) {
      return 'Ingresa un teléfono válido (10 dígitos)';
    }

    return null;
  }

  // Validar campo requerido
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }

    return null;
  }

  // Validar número positivo
  static String? validatePositiveNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es requerido';
    }

    final number = double.tryParse(value);

    if (number == null || number <= 0) {
      return 'Ingresa un número válido mayor a 0';
    }

    return null;
  }

  // Validar rango de calificación (1-5)
  static String? validateRating(int? value) {
    if (value == null) {
      return 'Selecciona una calificación';
    }

    if (value < 1 || value > 5) {
      return 'La calificación debe estar entre 1 y 5';
    }

    return null;
  }
}
