import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_reservation_provider.dart';
import '../../models/reservation_model.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_buttom.dart';

class AdminReservationDetailScreen extends StatefulWidget {
  final String reservationId;

  const AdminReservationDetailScreen({
    super.key,
    required this.reservationId,
  });

  @override
  State<AdminReservationDetailScreen> createState() =>
      _AdminReservationDetailScreenState();
}

class _AdminReservationDetailScreenState
    extends State<AdminReservationDetailScreen> {
  ReservationModel? _reservation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReservationDetails();
  }

  Future<void> _loadReservationDetails() async {
    final provider = context.read<AdminReservationProvider>();
    final reservation =
        await provider.getReservationDetails(widget.reservationId);

    setState(() {
      _reservation = reservation;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalles de Reservación')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_reservation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('No se pudo cargar la reservación'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de Reservación'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del vehículo
            if (_reservation!.vehicleImagenUrl != null) _buildVehicleImage(),

            // Información detallada
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estado actual
                  _buildStatusSection(),
                  const SizedBox(height: AppSpacing.lg),

                  // Información del vehículo
                  _buildSectionTitle('Información del Vehículo'),
                  _buildInfoCard([
                    _buildInfoRow(
                      Icons.directions_car,
                      'Vehículo',
                      _reservation!.vehicleNombre,
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.lg),

                  // Información del cliente
                  _buildSectionTitle('Información del Cliente'),
                  _buildInfoCard([
                    _buildInfoRow(
                      Icons.person,
                      'Cliente',
                      _reservation!.userName ?? 'No disponible',
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.lg),

                  // Detalles de la reservación
                  _buildSectionTitle('Detalles de la Reservación'),
                  _buildInfoCard([
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Fecha de Inicio',
                      DateFormat('dd/MM/yyyy')
                          .format(_reservation!.fechaInicio),
                    ),
                    const Divider(),
                    _buildInfoRow(
                      Icons.event,
                      'Fecha de Fin',
                      DateFormat('dd/MM/yyyy').format(_reservation!.fechaFin),
                    ),
                    const Divider(),
                    _buildInfoRow(
                      Icons.access_time,
                      'Duración',
                      '${_reservation!.diasAlquiler} día${_reservation!.diasAlquiler > 1 ? 's' : ''}',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      Icons.schedule,
                      'Fecha de Reserva',
                      DateFormat('dd/MM/yyyy HH:mm')
                          .format(_reservation!.fechaReserva),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.lg),

                  // Información de pago
                  _buildSectionTitle('Información de Pago'),
                  _buildInfoCard([
                    _buildInfoRow(
                      Icons.attach_money,
                      'Total',
                      '\$${_reservation!.precioTotal.toStringAsFixed(2)}',
                      valueStyle: const TextStyle(
                        fontSize: AppFontSizes.xl,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.xl),

                  // Acciones de administrador
                  _buildAdminActions(),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleImage() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(_reservation!.vehicleImagenUrl!),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.5),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (_reservation!.estado) {
      case 'pendiente':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Pendiente';
        break;
      case 'confirmada':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Confirmada';
        break;
      case 'completada':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        statusText = 'Completada';
        break;
      case 'cancelada':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Cancelada';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = _reservation!.estado;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 32),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estado Actual',
                style: TextStyle(
                  fontSize: AppFontSizes.sm,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: AppFontSizes.xl,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: AppFontSizes.lg,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: valueStyle ??
                      const TextStyle(
                        fontSize: AppFontSizes.md,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Acciones de Administrador',
          style: TextStyle(
            fontSize: AppFontSizes.lg,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Botones según el estado actual
        if (_reservation!.estado == 'pendiente') ...[
          CustomButton(
            text: 'Confirmar Reservación',
            onPressed: () => _updateStatus('confirmada'),
            icon: Icons.check_circle,
            backgroundColor: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.sm),
          CustomButton(
            text: 'Cancelar Reservación',
            onPressed: () => _updateStatus('cancelada'),
            icon: Icons.cancel,
            backgroundColor: AppColors.error,
          ),
        ] else if (_reservation!.estado == 'confirmada') ...[
          CustomButton(
            text: 'Marcar como Completada',
            onPressed: () => _updateStatus('completada'),
            icon: Icons.done_all,
            backgroundColor: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          CustomButton(
            text: 'Cancelar Reservación',
            onPressed: () => _updateStatus('cancelada'),
            icon: Icons.cancel,
            backgroundColor: AppColors.error,
          ),
        ] else if (_reservation!.estado == 'cancelada') ...[
          CustomButton(
            text: 'Reactivar Reservación',
            onPressed: () => _updateStatus('pendiente'),
            icon: Icons.refresh,
            backgroundColor: AppColors.primary,
          ),
        ] else if (_reservation!.estado == 'completada') ...[
          const Center(
            child: Text(
              'Esta reservación ya ha sido completada',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    // Confirmar acción
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Acción'),
        content: Text('¿Estás seguro de cambiar el estado a "$newStatus"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Actualizar estado
    final provider = context.read<AdminReservationProvider>();
    final success = await provider.updateReservationStatus(
      widget.reservationId,
      newStatus,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estado actualizado correctamente'),
          backgroundColor: AppColors.success,
        ),
      );

      // Recargar detalles
      await _loadReservationDetails();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${provider.errorMessage}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
