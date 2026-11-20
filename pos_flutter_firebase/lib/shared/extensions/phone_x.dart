import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

/// Máscara mexicana (+52, 10 dígitos). El `eager` inserta los espacios
/// mientras se escribe. La base de datos guarda dígitos sin formato.
final phoneNumberInputFormatter = MaskTextInputFormatter(
  mask: '+52 ## #### ####',
  filter: {
    "#": RegExp(r'[0-9]'),
  },
  type: MaskAutoCompletionType.eager,
);

extension PhoneStringX on String {
  String get maskPhoneNumber {
    return phoneNumberInputFormatter.maskText(this);
  }

  String get unmaskPhoneNumber {
    return phoneNumberInputFormatter.unmaskText(this);
  }
}
