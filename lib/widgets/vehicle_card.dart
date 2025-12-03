// lib/widgets/vehicle_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/vehicle_model.dart';
import '../utils/constants.dart';

class VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback onTap;

  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del vehículo
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppBorderRadius.md),
                topRight: Radius.circular(AppBorderRadius.md),
              ),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: vehicle.imagenUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 180,
                      color: AppColors.grey,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 180,
                      color: AppColors.grey,
                      child: const Icon(
                        Icons.directions_car,
                        size: 60,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  // Badge de tipo
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      ),
                      child: Text(
                        vehicle.tipo,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: AppFontSizes.xs,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Información del vehículo
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del vehículo
                  Text(
                    vehicle.nombreCompleto,
                    style: const TextStyle(
                      fontSize: AppFontSizes.lg,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Calificación
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        vehicle.totalCalificaciones > 0
                            ? '${vehicle.calificacionPromedio.toStringAsFixed(1)} (${vehicle.totalCalificaciones})'
                            : 'Sin calificaciones',
                        style: const TextStyle(
                          fontSize: AppFontSizes.sm,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Características
                  Row(
                    children: [
                      _buildFeature(
                        Icons.people,
                        '${vehicle.capacidad} personas',
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _buildFeature(
                        Icons.settings,
                        vehicle.transmision,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Precio
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${vehicle.precioPorDia.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: AppFontSizes.xl,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const Text(
                            AppStrings.perDay,
                            style: TextStyle(
                              fontSize: AppFontSizes.xs,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.sm),
                        ),
                        child: const Text(
                          'Ver detalles',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: AppFontSizes.sm,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          text,
          style: const TextStyle(
            fontSize: AppFontSizes.xs,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
