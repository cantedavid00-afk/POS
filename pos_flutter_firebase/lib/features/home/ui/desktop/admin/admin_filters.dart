import 'package:flutter/foundation.dart';

/// Rango de fechas usado en TODOS los apartados del .exe de administrador.
enum AdminDateRange { today, yesterday, thisWeek, thisMonth }

extension AdminDateRangeX on AdminDateRange {
  String get label {
    switch (this) {
      case AdminDateRange.today:
        return 'Hoy';
      case AdminDateRange.yesterday:
        return 'Ayer';
      case AdminDateRange.thisWeek:
        return 'Esta semana';
      case AdminDateRange.thisMonth:
        return 'Este mes';
    }
  }

  /// Devuelve [start, end] inclusivos en hora local.
  /// `end` para hoy/semana/mes es ahora mismo; para ayer es fin de ayer.
  ({DateTime start, DateTime end}) resolve(DateTime now) {
    final todayStart = DateTime(now.year, now.month, now.day);
    switch (this) {
      case AdminDateRange.today:
        return (start: todayStart, end: now);
      case AdminDateRange.yesterday:
        final start = todayStart.subtract(const Duration(days: 1));
        final end = todayStart.subtract(const Duration(milliseconds: 1));
        return (start: start, end: end);
      case AdminDateRange.thisWeek:
        // Lunes como inicio de semana.
        final weekday = now.weekday; // 1 = lunes
        final start = todayStart.subtract(Duration(days: weekday - 1));
        return (start: start, end: now);
      case AdminDateRange.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        return (start: start, end: now);
    }
  }

  bool contains(DateTime? date, DateTime now) {
    if (date == null) return false;
    final range = resolve(now);
    return !date.isBefore(range.start) && !date.isAfter(range.end);
  }
}

/// Alcance global del .exe: sucursal seleccionada + rango de fecha.
/// `selectedStoreId == null` significa TODAS las sucursales.
/// Vive por encima del shell desktop para que persista al cambiar de sección.
class AdminScope extends ChangeNotifier {
  AdminScope({String? initialStoreId, AdminDateRange initialRange = AdminDateRange.today})
      : _selectedStoreId = initialStoreId,
        _range = initialRange;

  String? _selectedStoreId;
  AdminDateRange _range;

  String? get selectedStoreId => _selectedStoreId;
  bool get isAllStores => _selectedStoreId == null;
  AdminDateRange get range => _range;

  void selectStore(String? storeId) {
    if (_selectedStoreId == storeId) return;
    _selectedStoreId = storeId;
    notifyListeners();
  }

  void setRange(AdminDateRange range) {
    if (_range == range) return;
    _range = range;
    notifyListeners();
  }

  /// Fuerza reconstrucción (botón ↻): los FutureBuilder recrean su future
  /// y recargan; los StreamBuilder en vivo conservan su suscripción.
  void touch() => notifyListeners();
}

/// Destinos del nav lateral del administrador (.exe).
enum AdminDestination { dashboard, receipts, products, poultry, backoffice }

extension AdminDestinationX on AdminDestination {
  String get key => name;
  String get label {
    switch (this) {
      case AdminDestination.dashboard:
        return 'Dashboard';
      case AdminDestination.receipts:
        return 'Recibos';
      case AdminDestination.products:
        return 'Productos';
      case AdminDestination.poultry:
        return 'Recibir pollo';
      case AdminDestination.backoffice:
        return 'Back Office';
    }
  }
}
