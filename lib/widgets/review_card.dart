//lib/widgets/review_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/review_model.dart';
import '../utils/constants.dart';

class ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const ReviewCard({
    super.key,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con nombre y fecha
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 20,
                      child: Text(
                        review.nombreUsuario.isNotEmpty
                            ? review.nombreUsuario[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: AppFontSizes.md,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Nombre
                    Text(
                      review.nombreUsuario,
                      style: const TextStyle(
                        fontSize: AppFontSizes.md,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                // Fecha
                Text(
                  review.fechaFormateada,
                  style: const TextStyle(
                    fontSize: AppFontSizes.xs,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Calificación
            RatingBarIndicator(
              rating: review.calificacion.toDouble(),
              itemBuilder: (context, index) => const Icon(
                Icons.star,
                color: AppColors.secondary,
              ),
              itemCount: 5,
              itemSize: 20,
              direction: Axis.horizontal,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Comentario
            if (review.tieneComentario)
              Text(
                review.comentario,
                style: const TextStyle(
                  fontSize: AppFontSizes.sm,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Widget para mostrar estadísticas de reseñas
class ReviewStats extends StatelessWidget {
  final Map<String, dynamic> stats;

  const ReviewStats({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final total = stats['total'] ?? 0;
    final promedio = stats['promedio'] ?? 0.0;
    final distribucion = stats['distribución'] as Map<int, int>? ?? {};

    if (total == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Este vehículo aún no tiene reseñas',
            style: TextStyle(
              fontSize: AppFontSizes.md,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // Promedio general
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  promedio.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: AppFontSizes.xxl,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.star,
                  size: 30,
                  color: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Basado en $total ${total == 1 ? 'reseña' : 'reseñas'}',
              style: const TextStyle(
                fontSize: AppFontSizes.sm,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Distribución de calificaciones
            ...List.generate(5, (index) {
              final stars = 5 - index;
              final count = distribucion[stars] ?? 0;
              final percentage = total > 0 ? (count / total) * 100 : 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Text(
                      '$stars',
                      style: const TextStyle(
                        fontSize: AppFontSizes.sm,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: AppColors.grey,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.secondary,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: AppFontSizes.xs,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
