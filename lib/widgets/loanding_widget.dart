// lib/widgets/loanding_widget.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/responsive_helper.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;

  const LoadingWidget({
    super.key,
    this.message,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveSize = ResponsiveHelper.isSmallScreen(context)
        ? size * 0.8
        : size;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: responsiveSize,
            height: responsiveSize,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.responsivePadding(
                  context,
                  AppSpacing.md,
                ),
              ),
              child: Text(
                message!,
                style: TextStyle(
                  fontSize: ResponsiveHelper.responsiveFontSize(
                    context,
                    AppFontSizes.md,
                  ),
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: null,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Widget para mostrar en fullscreen
class FullScreenLoading extends StatelessWidget {
  final String? message;

  const FullScreenLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LoadingWidget(message: message),
    );
  }
}

// Widget pequeño para botones
class SmallLoadingIndicator extends StatelessWidget {
  final Color? color;

  const SmallLoadingIndicator({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.white,
        ),
      ),
    );
  }
}
