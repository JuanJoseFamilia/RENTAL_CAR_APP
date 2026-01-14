import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/vehicle_provider.dart';
import '../../providers/review_provider.dart';
import '../../models/vehicle_model.dart';
import '../../utils/constants.dart';
import '../../widgets/loanding_widget.dart';
import '../../widgets/review_card.dart';
import '../../widgets/custom_buttom.dart';
import 'date_selection_screen.dart';
import 'vehicle_gallery_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final String vehicleId;

  const VehicleDetailScreen({
    super.key,
    required this.vehicleId,
  });

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().selectVehicle(widget.vehicleId);
      context.read<ReviewProvider>().loadVehicleReviews(widget.vehicleId);
      context.read<ReviewProvider>().loadReviewStats(widget.vehicleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VehicleProvider>(
      builder: (context, vehicleProvider, _) {
        if (vehicleProvider.isLoading) {
          return const Scaffold(
            body: FullScreenLoading(),
          );
        }

        final vehicle = vehicleProvider.selectedVehicle;

        if (vehicle == null) {
          return const Scaffold(
            body: Center(
              child: Text('Vehículo no encontrado'),
            ),
          );
        }

        return _buildVehicleDetail(vehicle);
      },
    );
  }

  Widget _buildVehicleDetail(VehicleModel vehicle) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar con imagen
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: () {
                  if (vehicle.imagenes.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VehicleGalleryScreen(
                          images: vehicle.imagenes,
                          initialIndex: vehicle.imagenes.indexWhere((u) => u == vehicle.portada),
                        ),
                      ),
                    );
                  }
                },
                child: CachedNetworkImage(
                  imageUrl: vehicle.portada ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.grey,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.grey,
                    child: const Icon(
                      Icons.directions_car,
                      size: 100,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información principal
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tipo
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.sm),
                        ),
                        child: Text(
                          vehicle.tipo,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: AppFontSizes.sm,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Nombre
                      Text(
                        vehicle.nombreCompleto,
                        style: const TextStyle(
                          fontSize: AppFontSizes.xxl,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Calificación
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 24,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            vehicle.calificacionTexto,
                            style: const TextStyle(
                              fontSize: AppFontSizes.md,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Precio
                      Row(
                        children: [
                          Text(
                            '\$${vehicle.precioPorDia.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Text(
                            AppStrings.perDay,
                            style: TextStyle(
                              fontSize: AppFontSizes.md,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Características
                      const Text(
                        'Características',
                        style: TextStyle(
                          fontSize: AppFontSizes.lg,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFeatureCard(
                              Icons.people,
                              AppStrings.capacity,
                              '${vehicle.capacidad} personas',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildFeatureCard(
                              Icons.settings,
                              AppStrings.transmission,
                              vehicle.transmision,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFeatureCard(
                              Icons.calendar_today,
                              AppStrings.year,
                              vehicle.anio.toString(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildFeatureCard(
                              Icons.check_circle,
                              'Estado',
                              vehicle.disponible
                                  ? 'Disponible'
                                  : 'No disponible',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Descripción
                      const Text(
                        'Descripción',
                        style: TextStyle(
                          fontSize: AppFontSizes.lg,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        vehicle.descripcion,
                        style: const TextStyle(
                          fontSize: AppFontSizes.md,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(thickness: 8, color: AppColors.background),

                // Reseñas
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.reviews,
                        style: TextStyle(
                          fontSize: AppFontSizes.lg,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Estadísticas
                      Consumer<ReviewProvider>(
                        builder: (context, reviewProvider, _) {
                          if (reviewProvider.reviewStats != null) {
                            return ReviewStats(
                                stats: reviewProvider.reviewStats!);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Lista de reseñas
                      Consumer<ReviewProvider>(
                        builder: (context, reviewProvider, _) {
                          final reviews = reviewProvider.vehicleReviews;

                          if (reviews.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(AppSpacing.lg),
                                child: Text(
                                  'No hay reseñas aún',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: reviews
                                .map((review) => ReviewCard(review: review))
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Espacio para el botón fijo
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: CustomButton(
            text: AppStrings.bookNow,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DateSelectionScreen(vehicle: vehicle),
                ),
              );
            },
            icon: Icons.event_available,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String label, String value) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: const TextStyle(
                fontSize: AppFontSizes.xs,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: const TextStyle(
                fontSize: AppFontSizes.sm,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
