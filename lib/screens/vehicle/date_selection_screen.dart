import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/vehicle_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../../widgets/custom_buttom.dart';
import 'vehicle_gallery_screen.dart';

class DateSelectionScreen extends StatefulWidget {
  final VehicleModel vehicle;

  const DateSelectionScreen({
    super.key,
    required this.vehicle,
  });

  @override
  State<DateSelectionScreen> createState() => _DateSelectionScreenState();
}

class _DateSelectionScreenState extends State<DateSelectionScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    // Limpiar fechas seleccionadas previas y cargar reservas activas del vehículo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ReservationProvider>();
      provider.clearSelectedDates();
      provider.loadActiveReservationsForVehicle(widget.vehicle.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Fechas'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Información del vehículo
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              color: AppColors.white,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (widget.vehicle.imagenes.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VehicleGalleryScreen(
                              images: widget.vehicle.imagenes,
                            ),
                          ),
                        );
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      child: widget.vehicle.portada != null && widget.vehicle.portada!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.vehicle.portada!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 80,
                                height: 80,
                                color: AppColors.grey,
                                child: const Icon(Icons.directions_car),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 80,
                                height: 80,
                                color: AppColors.grey,
                                child: const Icon(Icons.directions_car),
                              ),
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: AppColors.grey,
                              child: const Icon(Icons.directions_car),
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.vehicle.nombreCompleto,
                          style: const TextStyle(
                            fontSize: AppFontSizes.md,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '\$${widget.vehicle.precioPorDia.toStringAsFixed(2)} ${AppStrings.perDay}',
                          style: const TextStyle(
                            fontSize: AppFontSizes.lg,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(thickness: 8, color: AppColors.background),

            // Instrucciones
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecciona las fechas',
                    style: TextStyle(
                      fontSize: AppFontSizes.lg,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    '1. Selecciona la fecha de inicio\n2. Selecciona la fecha de fin',
                    style: TextStyle(
                      fontSize: AppFontSizes.sm,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Calendario
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Card(
                elevation: 2,
                child: Consumer<ReservationProvider>(
                  builder: (context, reservationProvider, _) {
                    final blocked = reservationProvider.blockedDays;

                    return TableCalendar(
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      calendarFormat: CalendarFormat.month,
                      selectedDayPredicate: (day) {
                        if (_selectedStartDate != null &&
                            _selectedEndDate != null) {
                          return AppDateUtils.isSameDay(day, _selectedStartDate!) ||
                              AppDateUtils.isSameDay(day, _selectedEndDate!);
                        } else if (_selectedStartDate != null) {
                          return AppDateUtils.isSameDay(day, _selectedStartDate!);
                        }
                        return false;
                      },
                      rangeStartDay: _selectedStartDate,
                      rangeEndDay: _selectedEndDate,
                      rangeSelectionMode: RangeSelectionMode.enforced,
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _focusedDay = focusedDay;

                          // Evitar seleccionar días bloqueados
                          final selectedDateOnly = AppDateUtils.getDateOnly(selectedDay);
                          if (blocked.contains(selectedDateOnly)) return;

                          if (_selectedStartDate == null ||
                              (_selectedStartDate != null &&
                                  _selectedEndDate != null)) {
                            // Iniciar nueva selección
                            _selectedStartDate = selectedDay;
                            _selectedEndDate = null;
                          } else if (_selectedStartDate != null &&
                              _selectedEndDate == null) {
                            // Seleccionar fecha de fin (validar que el rango no contenga días bloqueados)
                            if (selectedDay.isAfter(_selectedStartDate!)) {
                              if (reservationProvider.isRangeAvailable(
                                  _selectedStartDate!, selectedDay)) {
                                _selectedEndDate = selectedDay;
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(AppStrings.vehicleNotAvailable),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            } else {
                              _selectedStartDate = selectedDay;
                              _selectedEndDate = null;
                            }
                          }

                          // Actualizar provider
                          context.read<ReservationProvider>().selectDates(
                                _selectedStartDate,
                                _selectedEndDate,
                              );
                        });
                      },
                      enabledDayPredicate: (day) {
                        // Deshabilitar días pasados y días bloqueados por reservas activas
                        if (AppDateUtils.isPast(day)) return false;
                        final dayOnly = AppDateUtils.getDateOnly(day);
                        if (blocked.contains(dayOnly)) return false;
                        return true;
                      },
                      calendarStyle: CalendarStyle(
                        selectedDecoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppColors.primary.withAlpha((0.3 * 255).round()),
                          shape: BoxShape.circle,
                        ),
                        rangeHighlightColor: AppColors.primary.withAlpha((0.2 * 255).round()),
                        rangeStartDecoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        rangeEndDecoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        disabledDecoration: BoxDecoration(
                          color: AppColors.grey.withAlpha((0.3 * 255).round()),
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: AppFontSizes.lg,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Resumen y botón al final del contenido (requiere hacer scroll para verlo)
            Consumer<ReservationProvider>(
              builder: (context, reservationProvider, _) {
                final canProceed = reservationProvider.selectedStartDate != null &&
                    reservationProvider.selectedEndDate != null;
                final days = reservationProvider.selectedDays;
                final totalPrice = canProceed
                    ? reservationProvider
                        .calculateTotalPrice(widget.vehicle.precioPorDia)
                    : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha((0.08 * 255).round()),
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.md),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: canProceed
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Fecha de inicio:',
                                        style: TextStyle(
                                          fontSize: AppFontSizes.sm,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        AppDateUtils.formatDate(
                                            reservationProvider
                                                .selectedStartDate!),
                                        style: const TextStyle(
                                          fontSize: AppFontSizes.sm,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Fecha de fin:',
                                        style: TextStyle(
                                          fontSize: AppFontSizes.sm,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        AppDateUtils.formatDate(
                                            reservationProvider
                                                .selectedEndDate!),
                                        style: const TextStyle(
                                          fontSize: AppFontSizes.sm,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: AppSpacing.lg),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total ($days ${days == 1 ? 'día' : 'días'}):',
                                        style: const TextStyle(
                                          fontSize: AppFontSizes.md,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '\$${totalPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: AppFontSizes.xl,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : const Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Selecciona rango de fechas para ver total',
                                    style: TextStyle(
                                      fontSize: AppFontSizes.sm,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      CustomButton(
                        text: AppStrings.confirmReservation,
                        onPressed:
                            canProceed ? _handleConfirmReservation : () {},
                        isLoading: reservationProvider.isLoading,
                        backgroundColor: canProceed ? null : AppColors.grey,
                      ),

                      // Espacio extra para evitar que el botón se corte en pantallas pequeñas
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),

    );
  }

  Future<void> _handleConfirmReservation() async {
    final reservationProvider = context.read<ReservationProvider>();
    final authProvider = context.read<AuthProvider>();

    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para reservar'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Verificar disponibilidad
    final isAvailable = await reservationProvider.checkAvailability(
      vehicleId: widget.vehicle.id,
      startDate: reservationProvider.selectedStartDate!,
      endDate: reservationProvider.selectedEndDate!,
    );

    if (!mounted) return;

    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.vehicleNotAvailable),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Crear reserva
    final success = await reservationProvider.createReservation(
      userId: authProvider.currentUser!.id,
      vehicleId: widget.vehicle.id,
      pricePerDay: widget.vehicle.precioPorDia,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.reservationSuccess),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reservationProvider.errorMessage ?? 'Error al crear reserva',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
