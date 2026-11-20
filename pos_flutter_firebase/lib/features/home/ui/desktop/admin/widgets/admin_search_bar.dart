import 'package:flutter/material.dart';

import '../admin_theme_tokens.dart';

/// Buscador compacto (48–52 px): fondo blanco, borde suave, foco naranja.
/// Sin bloques oscuros dominantes.
class AdminSearchBar extends StatelessWidget {
  const AdminSearchBar({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
    this.hasQuery = false,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AdminText.body,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AdminText.bodySmall,
          prefixIcon: const Icon(Icons.search_outlined, color: AdminColors.textSecondary),
          suffixIcon: hasQuery
              ? IconButton(
                  tooltip: 'Limpiar',
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: AdminColors.card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AdminRadii.button),
            borderSide: const BorderSide(color: Color(0xFFE2E5EC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AdminRadii.button),
            borderSide: const BorderSide(color: AdminColors.accent, width: 1.5),
          ),
        ),
      ),
    );
  }
}
