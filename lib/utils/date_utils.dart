// lib/utils/date_utils.dart
import 'package:intl/intl.dart';

class AppDateUtils {
  // Formato de fecha legible: "15 de Enero, 2025"
  static String formatDate(DateTime date) {
    return DateFormat('d \'de\' MMMM, yyyy', 'es').format(date);
  }

  // Formato de fecha corta: "15/01/2025"
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Formato de fecha y hora: "15/01/2025 14:30"
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  // Calcular días entre dos fechas
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return to.difference(from).inDays;
  }

  // Verificar si una fecha es hoy
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Verificar si una fecha es en el pasado
  static bool isPast(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate.isBefore(today);
  }

  // Verificar si una fecha es en el futuro
  static bool isFuture(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate.isAfter(today);
  }

  // Obtener fecha sin hora (solo día, mes, año)
  static DateTime getDateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Verificar si dos fechas son el mismo día
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Obtener el primer día del mes
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Obtener el último día del mes
  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  // Agregar días a una fecha
  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  // Restar días a una fecha
  static DateTime subtractDays(DateTime date, int days) {
    return date.subtract(Duration(days: days));
  }

  // Formatear duración en días
  static String formatDuration(int days) {
    if (days == 1) {
      return '1 día';
    }
    return '$days días';
  }

  // Obtener nombre del mes
  static String getMonthName(int month) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return months[month - 1];
  }

  // Obtener nombre del día de la semana
  static String getDayName(DateTime date) {
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    return days[date.weekday - 1];
  }
}
