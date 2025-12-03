import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/reservation_provider.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../../widgets/loanding_widget.dart';
import '../../widgets/custom_buttom.dart';
import '../review/add_review_screen.dart';

class ReservationDetailScreen extends StatefulWidget {
  final String reservationId;

  const ReservationDetailScreen({
    super.key,
    required this.reservationId,
  });

  @override
  State<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<ReservationProvider>()
          .selectReservation(widget.reservationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Reserva'),
      ),
      body: Consumer<ReservationProvider>(
        builder: (context, reservationProvider, _) {
          if (reservationProvider.isLoading) {
            return const LoadingWidget(message: 'Cargando reserva...');
          }

          final reservation = reservationProvider.selectedReservation;

          if (reservation == null) {
            return const Center(
              child: Text('Reserva no encontrada'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Estado de la reserva
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  color: _getStatusColor(reservation.estado),
                  child: Column(
                    children: [
                      Icon(
                        _getStatusIcon(reservation.estado),
                        size: 60,
                        color: AppColors.white,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        reservation.estadoTexto.toUpperCase(),
                        style: const TextStyle(
                          fontSize: AppFontSizes.xl,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Imagen del vehículo
                if (reservation.vehicleImagenUrl != null)
                  CachedNetworkImage(
                    imageUrl: reservation.vehicleImagenUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: AppColors.grey,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      color: AppColors.grey,
                      child: const Icon(
                        Icons.directions_car,
                        size: 80,
                      ),
                    ),
                  ),

                // Información de la reserva
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vehículo
                      const Text(
                        'Vehículo',
                        style: TextStyle(
                          fontSize: AppFontSizes.lg,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        reservation.vehicleNombre,
                        style: const TextStyle(
                          fontSize: AppFontSizes.xl,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ID de Reserva
                      _buildInfoRow(
                        'ID de Reserva',
                        reservation.id,
                        Icons.confirmation_number,
                      ),
                      const Divider(height: AppSpacing.lg),

                      // Fecha de reserva
                      _buildInfoRow(
                        'Fecha de Reserva',
                        AppDateUtils.formatDateTime(reservation.fechaReserva),
                        Icons.event_available,
                      ),
                      const Divider(height: AppSpacing.lg),

                      // Fecha de inicio
                      _buildInfoRow(
                        'Fecha de Inicio',
                        AppDateUtils.formatDate(reservation.fechaInicio),
                        Icons.calendar_today,
                      ),
                      const Divider(height: AppSpacing.lg),

                      // Fecha de fin
                      _buildInfoRow(
                        'Fecha de Fin',
                        AppDateUtils.formatDate(reservation.fechaFin),
                        Icons.event,
                      ),
                      const Divider(height: AppSpacing.lg),

                      // Duración
                      _buildInfoRow(
                        'Duración',
                        AppDateUtils.formatDuration(reservation.diasAlquiler),
                        Icons.schedule,
                      ),
                      const Divider(height: AppSpacing.lg),

                      // Precio total
                      _buildInfoRow(
                        'Precio Total',
                        '\$${reservation.precioTotal.toStringAsFixed(2)}',
                        Icons.attach_money,
                        valueColor: AppColors.primary,
                        valueSize: AppFontSizes.xl,
                      ),
                    ],
                  ),
                ),

                // Botones de acción
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      // Cancelar reserva
                      if (reservation.canBeCancelled) ...[
                        CustomButton(
                          text: AppStrings.cancelReservation,
                          onPressed: () => _showCancelDialog(reservation.id),
                          backgroundColor: AppColors.error,
                          icon: Icons.cancel,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Dejar reseña
                      if (reservation.canBeReviewed) ...[
                        CustomButton(
                          text: AppStrings.leaveReview,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddReviewScreen(
                                  reservation: reservation,
                                ),
                              ),
                            );
                          },
                          backgroundColor: AppColors.secondary,
                          icon: Icons.rate_review,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Volver
                      CustomButton(
                        text: 'Volver',
                        onPressed: () => Navigator.pop(context),
                        isOutlined: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    double? valueSize,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 24,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppFontSizes.sm,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: TextStyle(
                  fontSize: valueSize ?? AppFontSizes.md,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
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

  IconData _getStatusIcon(String estado) {
    switch (estado) {
      case 'confirmada':
        return Icons.check_circle;
      case 'completada':
        return Icons.event_available;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  void _showCancelDialog(String reservationId) {
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
              await _handleCancelReservation(reservationId);
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
      Navigator.pop(context);
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
}
