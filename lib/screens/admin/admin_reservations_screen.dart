import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_reservation_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/reservation_model.dart';
import '../../utils/constants.dart';
import 'admin_reservation_detail_screen.dart';

class AdminReservationsScreen extends StatefulWidget {
  const AdminReservationsScreen({super.key});

  @override
  State<AdminReservationsScreen> createState() =>
      _AdminReservationsScreenState();
}

class _AdminReservationsScreenState extends State<AdminReservationsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminReservationProvider>();
      provider.loadAllReservations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.currentUser?.rol == 'admin';

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso Denegado')),
        body: const Center(
          child: Text(
            'No tienes permisos de administrador',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Reservaciones'),
        elevation: 0,
      ),
      body: Consumer<AdminReservationProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Header con estadísticas
              _buildStatsHeader(provider),

              // Barra de búsqueda
              _buildSearchBar(provider),

              // Filtros
              _buildFilterChips(provider),

              // Lista de reservaciones
              Expanded(
                child: _buildReservationsList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(AdminReservationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'Total',
                provider.totalReservations.toString(),
                Icons.calendar_today,
                Colors.white,
              ),
              _buildStatCard(
                'Pendientes',
                provider.pendingReservations.toString(),
                Icons.hourglass_empty,
                Colors.orange,
              ),
              _buildStatCard(
                'Confirmadas',
                provider.confirmedReservations.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'Completadas',
                provider.completedReservations.toString(),
                Icons.done_all,
                Colors.blue,
              ),
              _buildStatCard(
                'Canceladas',
                provider.cancelledReservations.toString(),
                Icons.cancel,
                Colors.red,
              ),
              const SizedBox(width: 80), // Espaciador para balance visual
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AdminReservationProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por usuario o vehículo...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    provider.searchReservations('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) {
          provider.searchReservations(value);
        },
      ),
    );
  }

  Widget _buildFilterChips(AdminReservationProvider provider) {
    final filters = [
      {'value': 'todas', 'label': 'Todas', 'icon': Icons.list},
      {
        'value': 'pendiente',
        'label': 'Pendientes',
        'icon': Icons.hourglass_empty
      },
      {
        'value': 'confirmada',
        'label': 'Confirmadas',
        'icon': Icons.check_circle
      },
      {'value': 'completada', 'label': 'Completadas', 'icon': Icons.done_all},
      {'value': 'cancelada', 'label': 'Canceladas', 'icon': Icons.cancel},
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = provider.selectedFilter == filter['value'];

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(filter['label'] as String),
                ],
              ),
              onSelected: (_) {
                provider.setFilter(filter['value'] as String);
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReservationsList(AdminReservationProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Error: ${provider.errorMessage}',
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: () => provider.loadAllReservations(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (provider.filteredReservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No hay reservaciones',
              style: TextStyle(
                fontSize: AppFontSizes.lg,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: provider.filteredReservations.length,
      itemBuilder: (context, index) {
        final reservation = provider.filteredReservations[index];
        return _buildReservationCard(reservation);
      },
    );
  }

  Widget _buildReservationCard(ReservationModel reservation) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminReservationDetailScreen(
                reservationId: reservation.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      reservation.vehicleNombre,
                      style: const TextStyle(
                        fontSize: AppFontSizes.lg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(reservation.estado),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Info del usuario
              Row(
                children: [
                  const Icon(Icons.person,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    reservation.userName ?? 'Usuario desconocido',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppFontSizes.sm,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Fechas
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${dateFormat.format(reservation.fechaInicio)} - ${dateFormat.format(reservation.fechaFin)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppFontSizes.sm,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Precio y días
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${reservation.diasAlquiler} día${reservation.diasAlquiler > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: AppFontSizes.sm,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '\$${reservation.precioTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: AppFontSizes.lg,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String estado) {
    Color color;
    String label;

    switch (estado) {
      case 'pendiente':
        color = Colors.orange;
        label = 'Pendiente';
        break;
      case 'confirmada':
        color = Colors.green;
        label = 'Confirmada';
        break;
      case 'completada':
        color = Colors.blue;
        label = 'Completada';
        break;
      case 'cancelada':
        color = Colors.red;
        label = 'Cancelada';
        break;
      default:
        color = Colors.grey;
        label = estado;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AppFontSizes.sm,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
