/// Historial de novedades por versión (solo español, el idioma de la app).
/// Las claves deben ser parseables por `pub_semver` (mayor.minor.patch).
const Map<String, List<String>> kChangelogEs = {
  '1.0.6': [
    'Cobro con pago dividido oculto tras el botón de tres puntos, con cálculo de cambio.',
    'La pantalla de Pérdidas ahora está visible para todos los usuarios.',
  ],
  '1.0.5': [
    'Cobro dividido entre efectivo y tarjeta.',
    'Nueva pantalla de Pérdidas de mercancía con historial.',
  ],
};
