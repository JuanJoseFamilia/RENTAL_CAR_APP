import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';
import '../../providers/reservation_provider.dart';
import '../../utils/constants.dart';

class AdminVehicleReservationsScreen extends StatefulWidget {
  final VehicleModel vehicle;

  const AdminVehicleReservationsScreen({super.key, required this.vehicle});

  @override
  State<AdminVehicleReservationsScreen> createState() =>
      _AdminVehicleReservationsScreenState();
}

class _AdminVehicleReservationsScreenState
    extends State<AdminVehicleReservationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<ReservationProvider>()
          .loadReservationsForVehicle(widget.vehicle.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reservas - ${widget.vehicle.nombreCompleto}'),
      ),
      body: Consumer<ReservationProvider>(
        builder: (context, reservationProvider, _) {
          final reservations = reservationProvider.vehicleReservations;

          if (reservationProvider.isLoading && reservations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (reservations.isEmpty) {
            return const Center(
              child: Text('No hay reservas para este vehículo'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final r = reservations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ListTile(
                  title: Text('${r.userName ?? r.userId} - ${r.estado}'),
                  subtitle: Text(
                      '${r.fechaInicio.toLocal().toString().split(' ')[0]} ➜ ${r.fechaFin.toLocal().toString().split(' ')[0]}\nTotal: \$${r.precioTotal.toStringAsFixed(2)}'),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'completar') {
                        final ok = await reservationProvider
                            .updateReservationStatus(r.id, 'completada');
                        if (!mounted) return;
                        if (ok) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Reserva marcada como completada')),
                            );
                          });
                        }
                      } else if (value == 'cancelar') {
                        final ok = await reservationProvider
                            .updateReservationStatus(r.id, 'cancelada');
                        if (!mounted) return;
                        if (ok) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Reserva cancelada')),
                            );
                          });
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: 'completar',
                          child: Text('Marcar como completada')),
                      const PopupMenuItem(
                          value: 'cancelar',
                          child: Text('Marcar como cancelada')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
