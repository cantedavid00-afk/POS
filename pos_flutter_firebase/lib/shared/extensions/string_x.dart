/// Guarda compartida contra valores nulos, "null" serializado y vacíos
/// provenientes de la base de datos. Usar en todo texto visible.
extension StringX on String? {
  bool get isUsable {
    return this != null && this!.isNotEmpty && this != 'null';
  }

  String orPlaceholder([String placeholder = '-']) {
    if (!isUsable) return placeholder;

    return this!;
  }
}
