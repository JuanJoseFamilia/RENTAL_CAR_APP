import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../models/reservation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_buttom.dart';

class AddReviewScreen extends StatefulWidget {
  final ReservationModel reservation;

  const AddReviewScreen({
    super.key,
    required this.reservation,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _rating = 5.0;

  @override
  void initState() {
    super.initState();
    _checkIfCanReview();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkIfCanReview() async {
    final authProvider = context.read<AuthProvider>();
    final reviewProvider = context.read<ReviewProvider>();

    if (authProvider.currentUser == null) {
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    final canReview = await reviewProvider.canUserReview(
      userId: authProvider.currentUser!.id,
      reservationId: widget.reservation.id,
    );

    if (!mounted) return;

    if (!canReview) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya has dejado una reseña para esta reserva'),
          backgroundColor: AppColors.error,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _handleSubmitReview() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final reviewProvider = context.read<ReviewProvider>();

    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await reviewProvider.createReview(
      userId: authProvider.currentUser!.id,
      vehicleId: widget.reservation.vehicleId,
      reservationId: widget.reservation.id,
      calificacion: _rating.toInt(),
      comentario: _commentController.text.trim(),
      nombreUsuario: authProvider.currentUser!.nombre,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.reviewSuccess),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reviewProvider.errorMessage ?? 'Error al enviar reseña',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.leaveReview),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Información del vehículo
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Califica tu experiencia con:',
                        style: TextStyle(
                          fontSize: AppFontSizes.sm,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        widget.reservation.vehicleNombre,
                        style: const TextStyle(
                          fontSize: AppFontSizes.lg,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Calificación
              const Text(
                AppStrings.rating,
                style: TextStyle(
                  fontSize: AppFontSizes.lg,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Column(
                  children: [
                    RatingBar.builder(
                      initialRating: _rating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: false,
                      itemCount: 5,
                      itemSize: 50,
                      itemPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: AppColors.secondary,
                      ),
                      onRatingUpdate: (rating) {
                        setState(() {
                          _rating = rating;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _getRatingText(_rating.toInt()),
                      style: const TextStyle(
                        fontSize: AppFontSizes.lg,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Comentario
              CustomTextField(
                controller: _commentController,
                label: AppStrings.comment,
                hint: 'Comparte tu experiencia con este vehículo...',
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El comentario es requerido';
                  }
                  if (value.trim().length < 10) {
                    return 'El comentario debe tener al menos 10 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // Consejo
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  border: Border.all(
                    color: AppColors.primary.withAlpha((0.3 * 255).round()),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Tu reseña ayudará a otros usuarios a tomar mejores decisiones.',
                        style: TextStyle(
                          fontSize: AppFontSizes.sm,
                          color: AppColors.primary.withAlpha((0.8 * 255).round()),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Botón enviar
              Consumer<ReviewProvider>(
                builder: (context, reviewProvider, _) {
                  return CustomButton(
                    text: AppStrings.submitReview,
                    onPressed: _handleSubmitReview,
                    isLoading: reviewProvider.isLoading,
                    icon: Icons.send,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Botón cancelar
              CustomButton(
                text: 'Cancelar',
                onPressed: () => Navigator.pop(context),
                isOutlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Muy malo';
      case 2:
        return 'Malo';
      case 3:
        return 'Regular';
      case 4:
        return 'Bueno';
      case 5:
        return 'Excelente';
      default:
        return '';
    }
  }
}
