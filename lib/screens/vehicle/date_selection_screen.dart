import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/vehicle_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../../widgets/custom_buttom.dart';

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
    // Limpiar fechas seleccionadas previas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationProvider>().clearSelectedDates();
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    child: Image.network(
                      widget.vehicle.imagenUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: AppColors.grey,
                          child: const Icon(Icons.directions_car),
                        );
                      },
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
                child: TableCalendar(
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

                      if (_selectedStartDate == null ||
                          (_selectedStartDate != null &&
                              _selectedEndDate != null)) {
                        // Iniciar nueva selección
                        _selectedStartDate = selectedDay;
                        _selectedEndDate = null;
                      } else if (_selectedStartDate != null &&
                          _selectedEndDate == null) {
                        // Seleccionar fecha de fin
                        if (selectedDay.isAfter(_selectedStartDate!)) {
                          _selectedEndDate = selectedDay;
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
                    // Deshabilitar días pasados
                    return !AppDateUtils.isPast(day);
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    rangeHighlightColor: AppColors.primary.withOpacity(0.2),
                    rangeStartDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    rangeEndDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    disabledDecoration: BoxDecoration(
                      color: AppColors.grey.withOpacity(0.3),
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
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Resumen de selección
            Consumer<ReservationProvider>(
              builder: (context, reservationProvider, _) {
                if (reservationProvider.selectedStartDate != null &&
                    reservationProvider.selectedEndDate != null) {
                  final days = reservationProvider.selectedDays;
                  final totalPrice = reservationProvider.calculateTotalPrice(
                    widget.vehicle.precioPorDia,
                  );

                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                reservationProvider.selectedStartDate!,
                              ),
                              style: const TextStyle(
                                fontSize: AppFontSizes.sm,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                reservationProvider.selectedEndDate!,
                              ),
                              style: const TextStyle(
                                fontSize: AppFontSizes.sm,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: AppSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      bottomSheet: Consumer<ReservationProvider>(
        builder: (context, reservationProvider, _) {
          final canProceed = reservationProvider.selectedStartDate != null &&
              reservationProvider.selectedEndDate != null;

          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: CustomButton(
                text: AppStrings.confirmReservation,
                onPressed: canProceed ? _handleConfirmReservation : () {},
                isLoading: reservationProvider.isLoading,
                backgroundColor: canProceed ? null : AppColors.grey,
              ),
            ),
          );
        },
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
