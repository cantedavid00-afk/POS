import 'package:intl/intl.dart';

/// Formato único de fechas para la app (ej. `24 jul 2026, 14:44` con
/// `languageCode = 'es'`). Fecha nula → 'N/A', nunca "null" en pantalla.
extension DateTimeX on DateTime? {
  // 24 July 2016, 14:44
  String formattedDateTime(String languageCode) {
    if (this == null) return 'N/A';

    return DateFormat('d MMMM yyyy, HH:mm', languageCode).format(this!);
  }

  // 24 Jul 2016
  String formattedDate(String languageCode) {
    if (this == null) return 'N/A';

    return DateFormat('d MMM yyyy', languageCode).format(this!);
  }

  // Friday, 24 July
  String formattedWeekdayDate(String languageCode) {
    if (this == null) return 'N/A';

    return DateFormat('EEEE, d MMMM', languageCode).format(this!);
  }

  // 14:44
  String get formattedTime {
    if (this == null) return 'N/A';

    return DateFormat('HH:mm').format(this!);
  }

  // Today · Yesterday · 24 Jul 2016
  String formattedDayOrDate(String languageCode) {
    if (this == null) return 'N/A';

    if (isToday) return 'Hoy';
    if (isYesterday) return 'Ayer';

    return formattedDate(languageCode);
  }

  // 2016-07-24, for requests only
  String get formattedForBackend {
    if (this == null) return '';

    return DateFormat('yyyy-MM-dd').format(this!);
  }

  bool get isToday {
    if (this == null) return false;

    final DateTime now = DateTime.now();

    return this!.year == now.year &&
        this!.month == now.month &&
        this!.day == now.day;
  }

  bool get isYesterday {
    if (this == null) return false;

    final DateTime yesterday = DateTime.now().subtract(
      const Duration(days: 1),
    );

    return this!.year == yesterday.year &&
        this!.month == yesterday.month &&
        this!.day == yesterday.day;
  }
}
