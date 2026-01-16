import 'package:get_it/get_it.dart';
import '../services/vehicle_service.dart';
import '../services/reservation_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/review_service.dart';
import '../services/image_service.dart';
import '../services/cache_service.dart';

/// Configuración del Service Locator para inyección de dependencias
/// Garantiza una única instancia de cada servicio en toda la app
class ServiceLocator {
  static final GetIt _instance = GetIt.instance;

  /// Inicializar todos los servicios (llamar en main.dart)
  static Future<void> initialize() async {
    // Inicializar caché primero
    await CacheService.initializeCache();

    // Registrar servicios como singletons
    _instance.registerSingleton<VehicleService>(VehicleService());
    _instance.registerSingleton<ReservationService>(ReservationService());
    _instance.registerSingleton<AuthService>(AuthService());
    _instance.registerSingleton<ChatService>(ChatService());
    _instance.registerSingleton<ReviewService>(ReviewService());
    _instance.registerSingleton<ImageService>(ImageService());
    _instance.registerSingleton<CacheService>(CacheService());
  }

  /// Obtener una instancia del servicio
  static T get<T extends Object>() {
    return _instance.get<T>();
  }

  /// Verificar si un servicio está registrado
  static bool isRegistered<T extends Object>() {
    return _instance.isRegistered<T>();
  }
}
