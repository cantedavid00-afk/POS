import 'package:flutter/material.dart';

/// Tokens visuales centralizados del .exe administrador.
///
/// Dirección: fondo claro suave, tarjetas blancas redondeadas, sombra tenue,
/// acento naranja solo cuando comunica información.
/// Nada de decoración (glow, gradientes, bordes múltiples).
/// Los widgets admin deben usar estos tokens, no colores hardcodeados.
class AdminColors {
  AdminColors._();

  static const appBg = Color(0xFFF5F6FA);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF171923);
  static const textSecondary = Color(0xFF6B7280);
  static const border = Color(0xFFE7E9EF);
  static const track = Color(0xFFEFF1F5);

  static const accent = Color(0xFFFF6B00);
  static const accentSoft = Color(0xFFFFF1E8);

  static const success = Color(0xFF22A06B);
  static const successBg = Color(0xFFE9F8F0);
  static const warning = Color(0xFFB07C00);
  static const warningBg = Color(0xFFFFF7DD);
  static const danger = Color(0xFFD64545);
  static const dangerBg = Color(0xFFFDECEC);
  static const info = Color(0xFF3B82F6);
  static const infoBg = Color(0xFFEDF4FF);
}

class AdminRadii {
  AdminRadii._();

  static const double card = 22;
  static const double inner = 16;
  static const double button = 12;
  static const double input = 12;
  static const double chip = 999;
}

class AdminSpacing {
  AdminSpacing._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AdminShadows {
  AdminShadows._();

  /// Una sola sombra tenue para elevar tarjetas. Nada de glow.
  static List<BoxShadow> get card => const [
        BoxShadow(
          color: Color(0x0F171923),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ];
}

class AdminText {
  AdminText._();

  static const pageTitle = TextStyle(fontSize: 27, fontWeight: FontWeight.w700, color: AdminColors.text, height: 1.15);
  static const pageSubtitle = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AdminColors.textSecondary);
  static const cardTitle = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AdminColors.text);
  static const cardSubtitle = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AdminColors.textSecondary);
  static const kpiValue = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AdminColors.text,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const kpiLabel = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AdminColors.textSecondary);
  static const body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AdminColors.text);
  static const bodySmall = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AdminColors.textSecondary);
  static const badge = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1);
  static const tabular = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);
}

/// Formato monetario `$12,345.00` sin depender de locale inicializado.
class AdminFormat {
  AdminFormat._();

  static String money(double value) {
    final negative = value < 0;
    final abs = value.abs();
    final parts = abs.toStringAsFixed(2).split('.');
    final grouped = _groupThousands(parts[0]);
    return '${negative ? '-' : ''}\$$grouped.${parts[1]}';
  }

  static String moneyShort(double value) {
    final abs = value.abs();
    if (abs >= 1000000) return '\$${(value / 1000000).toStringAsFixed(1)}M';
    if (abs >= 1000) return '\$${(value / 1000).toStringAsFixed(1)}k';
    return money(value);
  }

  static String qty(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  static String _groupThousands(String digits) {
    final buffer = StringBuffer();
    var count = 0;
    for (var i = digits.length - 1; i >= 0; i--) {
      buffer.write(digits[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write(',');
    }
    return buffer.toString().split('').reversed.join();
  }
}

/// Tema claro del .exe administrador: superficies blancas, acento naranja.
/// Se aplica envolviendo pantallas (crear/editar producto, Back Office,
/// detalle de ticket) para darles la paleta del dashboard sin tocar
/// el tema global ni el flujo móvil.
class AdminTheme {
  AdminTheme._();

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AdminColors.accent,
      onPrimary: Colors.white,
      secondary: AdminColors.info,
      surface: AdminColors.card,
      onSurface: AdminColors.text,
      error: AdminColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AdminColors.appBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: AdminColors.card,
        foregroundColor: AdminColors.text,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AdminColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminRadii.card),
          side: const BorderSide(color: AdminColors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AdminColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadii.inner)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AdminColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadii.inner)),
        textStyle: AdminText.body,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminRadii.input)),
        filled: true,
        fillColor: AdminColors.card,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AdminColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadii.button)),
        ),
      ),
      dividerColor: AdminColors.border,
    );
  }
}
