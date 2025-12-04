import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_buttom.dart';
import '../../widgets/vehicle_card.dart';
import 'add_vehicle_screen.dart';
import 'edit_vehicle_screen.dart';
import 'admin_reservations_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().loadAllVehicles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.currentUser?.rol == 'admin';

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Acceso Denegado'),
        ),
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
        title: const Text('Panel de Administración'),
        automaticallyImplyLeading: false,
        actions: [
          // Botón para ver reservaciones
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Ver Reservaciones',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminReservationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con botones de acciones rápidas
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: AppColors.primary.withOpacity(0.1),
            child: Column(
              children: [
                const Text(
                  'Gestión de Vehículos',
                  style: TextStyle(
                    fontSize: AppFontSizes.xl,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Botón de agregar vehículo
                CustomButton(
                  text: 'Agregar Nuevo Vehículo',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddVehicleScreen(),
                      ),
                    );
                  },
                  icon: Icons.add,
                  backgroundColor: AppColors.success,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Botón de ver reservaciones
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminReservationsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Ver Todas las Reservaciones'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ],
            ),
          ),

          // Lista de vehículos
          Expanded(
            child: Consumer<VehicleProvider>(
              builder: (context, vehicleProvider, _) {
                final vehicles = vehicleProvider.allVehicles;

                if (vehicles.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.car_rental,
                          size: 80,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: AppSpacing.md),
                        Text(
                          'No hay vehículos registrados',
                          style: TextStyle(
                            fontSize: AppFontSizes.lg,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Column(
                        children: [
                          VehicleCard(
                            vehicle: vehicle,
                            onTap: () {},
                          ),
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditVehicleScreen(
                                            vehicle: vehicle,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.edit, size: 18),
                                    label: const Text('Editar'),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: context
                                            .read<VehicleProvider>()
                                            .isLoading
                                        ? null
                                        : () => _toggleAvailability(
                                            vehicle.id, vehicle.disponible),
                                    icon: Icon(
                                      vehicle.disponible
                                          ? Icons.toggle_on
                                          : Icons.toggle_off,
                                      size: 18,
                                    ),
                                    label: Text(
                                      vehicle.disponible
                                          ? 'Disponible'
                                          : 'No Disponible',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: vehicle.disponible
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAvailability(String vehicleId, bool currentStatus) async {
    try {
      final vehicleProvider = context.read<VehicleProvider>();
      await vehicleProvider.toggleVehicleAvailability(vehicleId, currentStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Disponibilidad cambiada a ${!currentStatus ? "Disponible" : "No Disponible"}',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
