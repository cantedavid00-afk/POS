import 'package:flutter/material.dart';

import '../admin_theme_tokens.dart';

/// Tarjeta base de todo el .exe: blanca, radio 22, borde tenue, sombra tenue.
class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    this.title,
    this.subtitle,
    this.action,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final String? title;
  final String? subtitle;
  final Widget? action;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(AdminRadii.card),
        border: Border.all(color: AdminColors.border),
        boxShadow: AdminShadows.card,
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title!, style: AdminText.cardTitle),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!, style: AdminText.cardSubtitle),
                        ],
                      ],
                    ),
                  ),
                  action ?? const SizedBox.shrink(),
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}
