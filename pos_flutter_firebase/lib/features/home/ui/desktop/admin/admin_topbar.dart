import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/models/store.dart';
import 'admin_filters.dart';
import 'admin_theme_tokens.dart';
import 'widgets/admin_selectors.dart';

/// Barra superior global: el contexto (sucursal + fecha) siempre visible.
/// Filtros en tarjeta blanca; sucursal es el control más visible.
class AdminTopBar extends StatelessWidget {
  const AdminTopBar({
    super.key,
    required this.stores,
    required this.employeeName,
    required this.employeeEmail,
    required this.onSignOut,
  });

  final List<Store> stores;
  final String employeeName;
  final String employeeEmail;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AdminColors.card,
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              AdminStoreSelector(stores: stores),
              const AdminDateSelector(),
              if (constraints.maxWidth >= 900) const SizedBox(width: 4),
              Tooltip(
                message: 'Recargar datos',
                child: InkWell(
                  borderRadius: BorderRadius.circular(AdminRadii.button),
                  onTap: () => context.read<AdminScope>().touch(),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AdminColors.card,
                      borderRadius: BorderRadius.circular(AdminRadii.button),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: const Icon(Icons.refresh_outlined, size: 20, color: AdminColors.text),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AdminColors.track,
                  borderRadius: BorderRadius.circular(AdminRadii.chip),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: AdminColors.accent,
                      child: Text(
                        employeeName.isNotEmpty ? employeeName[0].toUpperCase() : 'A',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(employeeName, style: AdminText.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
                        if (employeeEmail.isNotEmpty)
                          Text(
                            employeeEmail,
                            style: AdminText.bodySmall.copyWith(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'Cerrar sesión',
                child: InkWell(
                  borderRadius: BorderRadius.circular(AdminRadii.button),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AdminRadii.inner),
                        ),
                        title: const Text('Cerrar sesión'),
                        content: const Text('¿Cerrar sesión del administrador?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Salir'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) onSignOut();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AdminColors.card,
                      borderRadius: BorderRadius.circular(AdminRadii.button),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: const Icon(Icons.logout_outlined, size: 20, color: AdminColors.text),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
