import 'package:flutter/widgets.dart';

/// Espacio final para scrollables que llegan al borde inferior.
///
/// Mide la barra de navegación del sistema y deja ese alto como respiro,
/// con un mínimo de 16px cuando no hay barra. No usar `SafeArea` alrededor
/// de scrollables: encoge el viewport y corta los items al pasar.
class BottomPadding extends StatelessWidget {
  const BottomPadding({super.key});

  static double of(
    BuildContext context, {
    double minimum = 16,
  }) {
    // Get size of the bottom system bar
    final double viewPadding = MediaQuery.viewPaddingOf(context).bottom;

    // Use the system bar size if it's bigger than the minimum,
    // otherwise fall back to the minimum.
    final double height = viewPadding > minimum ? viewPadding : minimum;

    return height;
  }

  @override
  Widget build(BuildContext context) {
    final double height = of(context);

    // Return a box of that height.
    return SizedBox(height: height);
  }
}
