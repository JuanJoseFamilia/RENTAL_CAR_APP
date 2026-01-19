// lib/utils/responsive_helper.dart
import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Obtener el ancho de la pantalla
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  // Obtener el alto de la pantalla
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Obtener el padding seguro (notches, etc)
  static EdgeInsets safePadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  // Verificar si es pantalla pequeña
  static bool isSmallScreen(BuildContext context) {
    return screenWidth(context) < 600;
  }

  // Verificar si es pantalla mediana
  static bool isMediumScreen(BuildContext context) {
    return screenWidth(context) >= 600 && screenWidth(context) < 900;
  }

  // Verificar si es pantalla grande
  static bool isLargeScreen(BuildContext context) {
    return screenWidth(context) >= 900;
  }

  // Obtener tamaño de fuente responsivo
  static double responsiveFontSize(BuildContext context, double baseSize) {
    final textScaler = MediaQuery.of(context).textScaler;

    // Ajustar basado en ancho de pantalla
    double scaledSize = baseSize;
    if (isSmallScreen(context)) {
      scaledSize = baseSize * 0.9;
    } else if (isLargeScreen(context)) {
      scaledSize = baseSize * 1.1;
    }

    // Aplicar escala de texto del dispositivo
    return textScaler.scale(scaledSize);
  }

  // Obtener padding responsivo
  static double responsivePadding(BuildContext context, double basePadding) {
    if (isSmallScreen(context)) {
      return basePadding * 0.85;
    } else if (isLargeScreen(context)) {
      return basePadding * 1.2;
    }
    return basePadding;
  }

  // Obtener altura responsiva para imágenes
  static double responsiveImageHeight(BuildContext context,
      {double smallHeight = 150,
      double mediumHeight = 200,
      double largeHeight = 280}) {
    if (isSmallScreen(context)) {
      return smallHeight;
    } else if (isMediumScreen(context)) {
      return mediumHeight;
    } else {
      return largeHeight;
    }
  }

  // Obtener número de columnas en grid responsivo
  static int responsiveGridColumns(BuildContext context) {
    if (isSmallScreen(context)) {
      return 1;
    } else if (isMediumScreen(context)) {
      return 2;
    } else {
      return 3;
    }
  }

  // Verificar orientación
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // Obtener máximo ancho para contenedores
  static double getConstrainedWidth(BuildContext context,
      {double maxWidth = 1200}) {
    final width = screenWidth(context);
    return width > maxWidth ? maxWidth : width;
  }

  // Obtener altura responsiva para SliverAppBar
  static double responsiveSliverAppBarHeight(BuildContext context) {
    if (isSmallScreen(context)) {
      return 200;
    } else if (isMediumScreen(context)) {
      return 250;
    } else {
      return 300;
    }
  }

  // Ajustar aspect ratio dinámicamente
  static double getImageAspectRatio(BuildContext context) {
    if (isLandscape(context)) {
      return 16 / 9;
    } else {
      return 4 / 3;
    }
  }
}
