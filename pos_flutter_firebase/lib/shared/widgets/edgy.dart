import 'package:flutter/material.dart';

/// Difumina un borde del scrollable hijo para insinuar que hay más contenido.
///
/// Solo alfa, así funciona igual en modo claro y oscuro.
class Edgy extends StatelessWidget {
  final Widget child;
  final Axis axis;
  final bool fadeStart;
  final bool fadeEnd;

  const Edgy({
    super.key,
    required this.child,
    this.axis = Axis.vertical,
    this.fadeStart = true,
    this.fadeEnd = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isVertical = axis == Axis.vertical;

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: isVertical ? Alignment.topCenter : Alignment.centerLeft,
          end: isVertical ? Alignment.bottomCenter : Alignment.centerRight,
          colors: <Color>[
            fadeStart ? const Color(0x00FFFFFF) : const Color(0xFFFFFFFF),
            const Color(0xFFFFFFFF),
            const Color(0xFFFFFFFF),
            fadeEnd ? const Color(0x00FFFFFF) : const Color(0xFFFFFFFF),
          ],
          stops: const <double>[0.0, 0.12, 0.88, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}
