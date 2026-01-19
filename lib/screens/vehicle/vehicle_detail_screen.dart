import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/vehicle_provider.dart';
import '../../providers/review_provider.dart';
import '../../models/vehicle_model.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_helper.dart';
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
            expandedHeight: ResponsiveHelper.responsiveSliverAppBarHeight(context),
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
                  padding: EdgeInsets.all(
                    ResponsiveHelper.responsivePadding(context, AppSpacing.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tipo
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: ResponsiveHelper.responsivePadding(
                            context,
                            AppSpacing.xs,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.sm),
                        ),
                        child: Text(
                          vehicle.tipo,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: ResponsiveHelper.responsiveFontSize(
                              context,
                              AppFontSizes.sm,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Nombre
                      Text(
                        vehicle.nombreCompleto,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.responsiveFontSize(
                            context,
                            AppFontSizes.xxl,
                          ),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: null,
                        overflow: TextOverflow.visible,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Calificación
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 24,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              vehicle.calificacionTexto,
                              style: TextStyle(
                                fontSize: ResponsiveHelper.responsiveFontSize(
                                  context,
                                  AppFontSizes.md,
                                ),
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Precio
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Text(
                              '\$${vehicle.precioPorDia.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.responsiveFontSize(
                                  context,
                                  32,
                                ),
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              AppStrings.perDay,
                              style: TextStyle(
                                fontSize: ResponsiveHelper.responsiveFontSize(
                                  context,
                                  AppFontSizes.md,
                                ),
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Características
                      Text(
                        'Características',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.responsiveFontSize(
                            context,
                            AppFontSizes.lg,
                          ),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      GridView.count(
                        crossAxisCount: ResponsiveHelper.isSmallScreen(context)
                            ? 2
                            : ResponsiveHelper.isMediumScreen(context)
                                ? 2
                                : 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: ResponsiveHelper.responsivePadding(
                          context,
                          AppSpacing.md,
                        ),
                        crossAxisSpacing: ResponsiveHelper.responsivePadding(
                          context,
                          AppSpacing.md,
                        ),
                        childAspectRatio: ResponsiveHelper.isSmallScreen(context)
                            ? 1.35
                            : ResponsiveHelper.isMediumScreen(context)
                                ? 1.4
                                : 1.3,
                        children: [
                          _buildFeatureCard(
                            context,
                            Icons.people,
                            AppStrings.capacity,
                            '${vehicle.capacidad} personas',
                          ),
                          _buildFeatureCard(
                            context,
                            Icons.settings,
                            AppStrings.transmission,
                            vehicle.transmision,
                          ),
                          _buildFeatureCard(
                            context,
                            Icons.calendar_today,
                            AppStrings.year,
                            vehicle.anio.toString(),
                          ),
                          _buildFeatureCard(
                            context,
                            Icons.check_circle,
                            'Estado',
                            vehicle.disponible
                                ? 'Disponible'
                                : 'No disponible',
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Descripción
                      Text(
                        'Descripción',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.responsiveFontSize(
                            context,
                            AppFontSizes.lg,
                          ),
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

  Widget _buildFeatureCard(
      BuildContext context, IconData icon, String label, String value) {
    final isSmall = ResponsiveHelper.isSmallScreen(context);
    final isMedium = ResponsiveHelper.isMediumScreen(context);
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.white,
              AppColors.white.withOpacity(0.98),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(
            ResponsiveHelper.responsivePadding(
              context,
              isSmall ? AppSpacing.md : AppSpacing.lg,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(
                  isSmall ? AppSpacing.sm : AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Icon(
                  icon,
                  size: isSmall ? 28 : isMedium ? 32 : 36,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(
                height: isSmall ? AppSpacing.xs : AppSpacing.sm,
              ),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.responsiveFontSize(
                      context,
                      isSmall ? AppFontSizes.xs : AppFontSizes.sm,
                    ),
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                height: isSmall ? AppSpacing.xs : AppSpacing.sm,
              ),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.responsiveFontSize(
                      context,
                      isSmall ? AppFontSizes.sm : AppFontSizes.md,
                    ),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
