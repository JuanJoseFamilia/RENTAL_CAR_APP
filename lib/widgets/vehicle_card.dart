// lib/widgets/vehicle_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/vehicle_model.dart';
import '../utils/constants.dart';
import '../utils/responsive_helper.dart';

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
    final imageHeight = ResponsiveHelper.responsiveImageHeight(
      context,
      smallHeight: 140,
      mediumHeight: 180,
      largeHeight: 220,
    );

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    imageUrl: vehicle.portada ?? '',
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: imageHeight,
                      color: AppColors.grey,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: imageHeight,
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
              padding: EdgeInsets.all(
                ResponsiveHelper.responsivePadding(context, AppSpacing.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del vehículo
                  Text(
                    vehicle.nombreCompleto,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.responsiveFontSize(
                        context,
                        AppFontSizes.lg,
                      ),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
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
                      Expanded(
                        child: Text(
                          vehicle.totalCalificaciones > 0
                              ? '${vehicle.calificacionPromedio.toStringAsFixed(1)} (${vehicle.totalCalificaciones})'
                              : 'Sin calificaciones',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.responsiveFontSize(
                              context,
                              AppFontSizes.sm,
                            ),
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Características - Responsive layout
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFeature(context, Icons.people, '${vehicle.capacidad}'),
                        const SizedBox(width: AppSpacing.md),
                        _buildFeature(context, Icons.settings, vehicle.transmision),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Precio
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\$${vehicle.precioPorDia.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.responsiveFontSize(
                                  context,
                                  AppFontSizes.xl,
                                ),
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              AppStrings.perDay,
                              style: TextStyle(
                                fontSize: ResponsiveHelper.responsiveFontSize(
                                  context,
                                  AppFontSizes.xs,
                                ),
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: ResponsiveHelper.responsivePadding(
                            context,
                            AppSpacing.sm,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.sm),
                        ),
                        child: Text(
                          'Ver',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: ResponsiveHelper.responsiveFontSize(
                              context,
                              AppFontSizes.sm,
                            ),
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

  Widget _buildFeature(BuildContext context, IconData icon, String text) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: ResponsiveHelper.responsiveFontSize(
                  context,
                  AppFontSizes.xs,
                ),
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
