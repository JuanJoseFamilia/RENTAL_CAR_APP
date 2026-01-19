// lib/widgets/custom_buttom.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/responsive_helper.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = backgroundColor ?? AppColors.primary;
    final txtColor = textColor ?? AppColors.white;
    final buttonHeight = height ?? (ResponsiveHelper.isSmallScreen(context) ? 45 : 50);

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: btnColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          minimumSize: Size(
            width ?? double.infinity,
            buttonHeight,
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(btnColor),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: btnColor),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.responsiveFontSize(
                          context,
                          AppFontSizes.md,
                        ),
                        fontWeight: FontWeight.w600,
                        color: btnColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: btnColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        elevation: 2,
        minimumSize: Size(
          width ?? double.infinity,
          buttonHeight,
        ),
      ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: txtColor),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.responsiveFontSize(
                          context,
                          AppFontSizes.md,
                        ),
                        fontWeight: FontWeight.w600,
                        color: txtColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
    );
  }
}
