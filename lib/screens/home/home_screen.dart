import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/vehicle_card.dart';
import '../../widgets/loanding_widget.dart';
import '../vehicle/vehicle_detail_screen.dart';
import '../reservation/my_reservations_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_screen.dart';
import '../chat/conversations_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Cargar vehículos al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().loadVehicles();
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<ReservationProvider>().loadUserReservations(userId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.currentUser?.rol == 'admin';

    final List<Widget> screens = isAdmin
        ? [
            _buildVehiclesScreen(),
            const MyReservationsScreen(),
            const ConversationsListScreen(),
            const AdminScreen(),
            const ProfileScreen(),
          ]
        : [
            _buildVehiclesScreen(),
            const MyReservationsScreen(),
            const ConversationsListScreen(),
            const ProfileScreen(),
          ];

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              title: const Text(AppStrings.availableVehicles),
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterBottomSheet,
                ),
              ],
            )
          : null,
      body: screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(authProvider, isAdmin),
    );
  }

  Widget _buildVehiclesScreen() {
    return Column(
      children: [
        // Barra de búsqueda
        Padding(
          padding: EdgeInsets.all(ResponsiveHelper.responsivePadding(
            context,
            AppSpacing.md,
          )),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppStrings.searchVehicle,
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<VehicleProvider>().searchVehicles('');
                      },
                    )
                  : null,
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
            ),
            onChanged: (value) {
              context.read<VehicleProvider>().searchVehicles(value);
            },
          ),
        ),

        // Filtros rápidos por tipo
        Consumer<VehicleProvider>(
          builder: (context, vehicleProvider, _) {
            return SizedBox(
              height: ResponsiveHelper.isSmallScreen(context) ? 45 : 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.responsivePadding(
                    context,
                    AppSpacing.md,
                  ),
                ),
                children: [
                  _buildFilterChip('Todos', null, vehicleProvider),
                  ...VehicleTypes.all.map(
                    (type) => _buildFilterChip(type, type, vehicleProvider),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: AppSpacing.sm),

        // Listado de vehículos
        Expanded(
          child: Consumer<VehicleProvider>(
            builder: (context, vehicleProvider, _) {
              if (vehicleProvider.isLoading) {
                return const LoadingWidget(message: AppStrings.loading);
              }

              final vehicles = vehicleProvider.vehicles;

              if (vehicles.isEmpty) {
                return SingleChildScrollView(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.car_rental,
                            size: ResponsiveHelper.isSmallScreen(context) ? 60 : 80,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: ResponsiveHelper.responsivePadding(context, AppSpacing.md)),
                          Text(
                            AppStrings.noVehiclesFound,
                            style: TextStyle(
                              fontSize: ResponsiveHelper.responsiveFontSize(
                                context,
                                AppFontSizes.lg,
                              ),
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Intenta con otros filtros',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.responsiveFontSize(
                                context,
                                AppFontSizes.sm,
                              ),
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: ResponsiveHelper.responsivePadding(context, AppSpacing.lg)),
                          ElevatedButton(
                            onPressed: () {
                              vehicleProvider.clearFilters();
                              _searchController.clear();
                            },
                            child: const Text('Limpiar filtros'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  vehicleProvider.reloadVehicles();
                },
                child: ListView.builder(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.responsivePadding(
                      context,
                      AppSpacing.md,
                    ),
                  ),
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    return VehicleCard(
                      vehicle: vehicle,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VehicleDetailScreen(
                              vehicleId: vehicle.id,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    String? filterValue,
    VehicleProvider vehicleProvider,
  ) {
    final isSelected = vehicleProvider.selectedType == filterValue;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveHelper.responsiveFontSize(
              context,
              AppFontSizes.sm,
            ),
            color: isSelected ? AppColors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          vehicleProvider.filterByType(selected ? filterValue : null);
        },
        backgroundColor: AppColors.white,
        selectedColor: AppColors.primary,
        checkmarkColor: AppColors.white,
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.lg),
        ),
      ),
      builder: (context) {
        return Consumer<VehicleProvider>(
          builder: (context, vehicleProvider, _) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: AppFontSizes.xl,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Ordenar por
                  const Text(
                    'Ordenar por:',
                    style: TextStyle(
                      fontSize: AppFontSizes.md,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      _buildSortChip(
                          'Más recientes', 'recent', vehicleProvider),
                      _buildSortChip(
                          'Precio: Menor', 'price_asc', vehicleProvider),
                      _buildSortChip(
                          'Precio: Mayor', 'price_desc', vehicleProvider),
                      _buildSortChip(
                          'Mejor valorados', 'rating_desc', vehicleProvider),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            vehicleProvider.clearFilters();
                            _searchController.clear();
                            Navigator.pop(context);
                          },
                          child: const Text('Limpiar'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortChip(
    String label,
    String sortType,
    VehicleProvider vehicleProvider,
  ) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        vehicleProvider.sortVehicles(sortType);
      },
      backgroundColor: AppColors.white,
      side: const BorderSide(color: AppColors.grey),
    );
  }

  Widget _buildBottomNavBar(AuthProvider authProvider, bool isAdmin) {
    final userId = authProvider.currentUser?.id;
    final chatProvider = context.read<ChatProvider>();

    return StreamBuilder<int>(
      stream: (userId != null) ? chatProvider.streamUnreadMessageCount(userId) : Stream.value(0),
      // Use the current authenticated UID for both users and admins so badge clears correctly
      // If userId is null, show 0
      // This replaces the previous admin-specific stream which used a fixed 'admin' marker
      // and could fail when admins use their real UID.
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        final List<BottomNavigationBarItem> navItems = isAdmin
            ? [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Inicio',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today),
                  label: 'Reservas',
                ),
                _buildMessagesNavItem(unreadCount),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.admin_panel_settings),
                  label: 'Admin',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Perfil',
                ),
              ]
            : [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Inicio',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today),
                  label: 'Reservas',
                ),
                _buildMessagesNavItem(unreadCount),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Perfil',
                ),
              ];

        return BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavItemTapped,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          items: navItems,
        );
      },
    );
  }

  BottomNavigationBarItem _buildMessagesNavItem(int unreadCount) {
    return BottomNavigationBarItem(
      icon: Stack(
        children: [
          const Icon(Icons.chat),
          if (unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      label: 'Mensajes',
    );
  }
}
