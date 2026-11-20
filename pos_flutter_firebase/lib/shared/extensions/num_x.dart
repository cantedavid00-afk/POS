import 'package:intl/intl.dart';

/// Formato de números para humanos según la región del dispositivo.
/// Regla: si se lee como "cuánto", se formatea. Si se lee como "cuál"
/// (folios, REFs, teléfonos, PINs), se deja intacto.
extension NumX on num {
  String humanizedCount({
    int? decimalDigits,
  }) {
    return NumberFormat.decimalPatternDigits(
      decimalDigits: decimalDigits,
    ).format(this);
  }

  String humanizedCurrency(String code) {
    return NumberFormat.simpleCurrency(
      name: code,
    ).format(this);
  }

  String humanizedCompact() {
    return NumberFormat.compact().format(this);
  }
}
