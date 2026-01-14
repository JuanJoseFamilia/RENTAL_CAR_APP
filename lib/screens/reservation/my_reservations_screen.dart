import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../models/reservation_model.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import 'reservation_detail_screen.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myReservations),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withAlpha((0.7 * 255).round()),
          tabs: const [
            Tab(text: AppStrings.active),
            Tab(text: AppStrings.completed),
            Tab(text: AppStrings.cancelled),
          ],
        ),
      ),
      body: Consumer<ReservationProvider>(
        builder: (context, reservationProvider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildReservationsList(
                reservationProvider.activeReservations,
                'No tienes reservas activas',
              ),
              _buildReservationsList(
                reservationProvider.completedReservations,
                'No tienes reservas completadas',
              ),
              _buildReservationsList(
                reservationProvider.cancelledReservations,
                'No tienes reservas canceladas',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReservationsList(
    List<ReservationModel> reservations,
    String emptyMessage,
  ) {
    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_busy,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: AppFontSizes.lg,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final userId = context.read<AuthProvider>().currentUser?.id;
        if (userId != null) {
          context.read<ReservationProvider>().reloadReservations(userId);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          final reservation = reservations[index];
          return _buildReservationCard(reservation);
        },
      ),
    );
  }

  Widget _buildReservationCard(ReservationModel reservation) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReservationDetailScreen(
                reservationId: reservation.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(reservation.estado),
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: Text(
                      reservation.estadoTexto,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: AppFontSizes.xs,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'ID: ${reservation.id.substring(0, 8)}...',
                    style: const TextStyle(
                      fontSize: AppFontSizes.xs,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Información del vehículo
              Row(
                children: [
                  // Imagen
                  if (reservation.vehicleImagenUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      child: CachedNetworkImage(
                        imageUrl: reservation.vehicleImagenUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 80,
                          height: 80,
                          color: AppColors.grey,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 80,
                          height: 80,
                          color: AppColors.grey,
                          child: const Icon(Icons.directions_car),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.grey,
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        size: 40,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(width: AppSpacing.md),

                  // Detalles
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reservation.vehicleNombre,
                          style: const TextStyle(
                            fontSize: AppFontSizes.md,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                '${AppDateUtils.formatDateShort(reservation.fechaInicio)} - ${AppDateUtils.formatDateShort(reservation.fechaFin)}',
                                style: const TextStyle(
                                  fontSize: AppFontSizes.sm,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            const Icon(
                              Icons.event,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${reservation.diasAlquiler} ${reservation.diasAlquiler == 1 ? 'día' : 'días'}',
                              style: const TextStyle(
                                fontSize: AppFontSizes.sm,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Precio total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: AppFontSizes.md,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '\$${reservation.precioTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: AppFontSizes.xl,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              // Botones de acción
              if (reservation.canBeCancelled) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCancelDialog(reservation),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Cancelar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Botón para dejar reseña
              if (reservation.canBeReviewed) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToReview(reservation),
                        icon: const Icon(Icons.rate_review, size: 18),
                        label: const Text('Dejar Reseña'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'confirmada':
        return AppColors.success;
      case 'completada':
        return AppColors.primary;
      case 'cancelada':
        return AppColors.error;
      default:
        return AppColors.secondary;
    }
  }

  void _showCancelDialog(ReservationModel reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Reserva'),
        content: const Text(
          '¿Estás seguro de que deseas cancelar esta reserva? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleCancelReservation(reservation.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancelReservation(String reservationId) async {
    final reservationProvider = context.read<ReservationProvider>();

    final success = await reservationProvider.cancelReservation(reservationId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reserva cancelada exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reservationProvider.errorMessage ?? 'Error al cancelar reserva',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _navigateToReview(ReservationModel reservation) {
    // Importar y navegar a la pantalla de reseñas
    Navigator.pushNamed(
      context,
      '/add-review',
      arguments: reservation,
    );
  }
}
