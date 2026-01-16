import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/vehicle_provider.dart';
import 'providers/reservation_provider.dart';
import 'providers/review_provider.dart';
import 'providers/admin_reservation_provider.dart';
import 'providers/chat_provider.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/review/add_review_screen.dart';
import 'screens/chat/chat_screen.dart';

// Models
import 'models/reservation_model.dart';

// Utils
import 'utils/constants.dart';

// Update Service
import 'services/update_service.dart';
import 'widgets/update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar formateo de fechas para español

  await initializeDateFormatting('es_ES', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => AdminReservationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
          ),
          scaffoldBackgroundColor: AppColors.background,
          textTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: AppFontSizes.lg,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          tabBarTheme: const TabBarThemeData(
            labelColor: AppColors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            color: AppColors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: const BorderSide(color: AppColors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: const BorderSide(color: AppColors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
            ),
          ),
        ),
        onGenerateRoute: (settings) {
          if (settings.name == '/add-review') {
            final reservation = settings.arguments as ReservationModel;
            return MaterialPageRoute(
              builder: (_) => AddReviewScreen(reservation: reservation),
            );
          }

          if (settings.name == '/chat') {
            final args = settings.arguments as Map<String, dynamic>;
            final conversationId = args['conversationId'] as String;
            final reservationId = args['reservationId'] as String?;
            return MaterialPageRoute(
              builder: (_) => ChatScreen(conversationId: conversationId, reservationId: reservationId),
            );
          }

          return null;
        },
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _updateService = UpdateService(
    // IMPORTANTE: Reemplaza con tu usuario y repositorio de GitHub
    githubRepo: 'JuanJoseFamilia/RENTAL_CAR_APP',
    // githubToken: 'tu_token_github_opcional', // Opcional para más requests
  );
  bool _updateCheckDone = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    try {
      final currentVersion = await _updateService.getCurrentVersion();
      final latestVersion = await _updateService.getLatestVersion();

      if (!mounted) return;

      // Si no hay versión más reciente, continuar
      if (latestVersion == null ||
          !_updateService.hasUpdate(currentVersion, latestVersion)) {
        setState(() {
          _updateCheckDone = true;
        });
        return;
      }

      // Obtener URL de descarga
      final downloadUrl = await _updateService.getDownloadUrl();

      if (!mounted) return;

      if (downloadUrl != null) {
        // Mostrar diálogo de actualización
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => UpdateDialog(
            updateService: _updateService,
            downloadUrl: downloadUrl,
            isForced: true, // Cambiar a false si quieres permitir cerrar
          ),
        );
      }

      setState(() {
        _updateCheckDone = true;
      });
    } catch (e) {
      // Log silencioso, no interrumpe la app
      setState(() {
        _updateCheckDone = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_updateCheckDone) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Escuchar cambios en el estado de autenticación
        return StreamBuilder(
          stream: authProvider.authStateChanges,
          builder: (context, snapshot) {
            // Si está cargando
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Si hay un usuario autenticado
            if (snapshot.hasData && authProvider.isAuthenticated) {
              return const HomeScreen();
            }

            // Si no hay usuario, mostrar login
            return const LoginScreen();
          },
        );
      },
    );
  }
}
