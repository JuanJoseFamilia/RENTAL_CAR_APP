import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/vehicle_card.dart';
import '../../widgets/loanding_widget.dart';
import '../vehicle/vehicle_detail_screen.dart';
import '../reservation/my_reservations_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_screen.dart';

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
            const AdminScreen(),
            const ProfileScreen(),
          ]
        : [
            _buildVehiclesScreen(),
            const MyReservationsScreen(),
            const ProfileScreen(),
          ];

    final List<BottomNavigationBarItem> navItems = isAdmin
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Reservas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Reservas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Perfil',
            ),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
    );
  }

  Widget _buildVehiclesScreen() {
    return Column(
      children: [
        // Barra de búsqueda
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
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
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.car_rental,
                        size: 80,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        AppStrings.noVehiclesFound,
                        style: TextStyle(
                          fontSize: AppFontSizes.lg,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Intenta con otros filtros',
                        style: TextStyle(
                          fontSize: AppFontSizes.sm,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: () {
                          vehicleProvider.clearFilters();
                          _searchController.clear();
                        },
                        child: const Text('Limpiar filtros'),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  vehicleProvider.reloadVehicles();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
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
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          vehicleProvider.filterByType(selected ? filterValue : null);
        },
        backgroundColor: AppColors.white,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
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
}
