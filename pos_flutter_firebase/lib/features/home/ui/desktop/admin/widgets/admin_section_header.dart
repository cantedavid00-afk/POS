import 'package:flutter/material.dart';

import '../admin_theme_tokens.dart';

/// Encabezado consistente de cada pantalla: título 27px + subtítulo.
/// No repetir en tarjetas lo que ya dice el encabezado.
class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({super.key, required this.title, required this.subtitle, this.action});

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AdminText.pageTitle),
              const SizedBox(height: 4),
              Text(subtitle, style: AdminText.pageSubtitle),
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: 12),
          action!,
        ],
      ],
    );
  }
}
