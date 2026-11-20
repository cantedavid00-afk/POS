import 'package:flutter/services.dart';

/// Un campo de monto con tope: lo que pase del máximo nunca entra al campo.
/// El texto vacío siempre pasa, para poder borrar y empezar de nuevo.
class MaxAmountInputFormatter extends TextInputFormatter {
  final double maxAmount;

  MaxAmountInputFormatter(this.maxAmount);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final double? value = double.tryParse(newValue.text);
    if (value == null) return oldValue;

    if (value > maxAmount) return oldValue;

    return newValue;
  }
}
