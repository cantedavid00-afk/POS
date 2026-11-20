import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/models/business.dart';
import '../../../../shared/models/store.dart';
import '../../../../shared/providers/app_session_notifier.dart';
import '../../../business/domain/business_repository.dart';
import '../../../business/domain/backup_repository.dart';
import '../../../business/domain/excel_export_repository.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../shared/extensions/phone_x.dart';
import '../../../../shared/extensions/string_x.dart';
import '../../../../shared/widgets/bottom_padding.dart';
import '../../../../shared/widgets/version_indicator.dart';

class BusinessConfigScreen extends StatefulWidget {
  final String businessId;

  const BusinessConfigScreen({super.key, required this.businessId});

  @override
  State<BusinessConfigScreen> createState() => _BusinessConfigScreenState();
}

class _BusinessConfigScreenState extends State<BusinessConfigScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppSessionNotifier>(
      builder: (context, sessionNotifier, _) {
        final session = sessionNotifier.session;
        final stores = session?.stores ?? [];
        return Scaffold(
          appBar: AppBar(title: const Text('Configuracion')),
          body: StreamBuilder<Business>(
            stream: FirebaseFirestore.instance.collection('businesses').doc(widget.businessId).snapshots().map((s) => Business.fromDoc(s)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final business = snapshot.data;
              if (business == null) return const Center(child: Text('Negocio no encontrado.'));
              return ListView(
                padding: EdgeInsets.all(20).copyWith(
                  bottom: BottomPadding.of(context, minimum: 20),
                ),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Informacion del negocio', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          _configRow('Nombre', business.name.orPlaceholder()),
                          _configRow('Moneda', business.currency.orPlaceholder()),
                          _configRow('Zona horaria', business.timezone.orPlaceholder()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Sucursales', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ...stores.map(
                    (store) => Card(
                      child: ListTile(
                        leading: Icon(store.active ? Icons.store : Icons.store_outlined),
                        title: Text(store.name.orPlaceholder()),
                        subtitle: Text('${store.address.orPlaceholder()} · ${store.phone.isUsable ? store.phone.maskPhoneNumber : '-'}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {},
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Editar')),
                            PopupMenuItem(
                              value: store.active ? 'deactivate' : 'activate',
                              child: Text(store.active ? 'Desactivar' : 'Activar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showAddStoreDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar sucursal'),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.download_for_offline_outlined, color: AppColors.accent),
                      title: const Text('Exportar a Excel'),
                      subtitle: const Text('Toda la informacion de todas las sucursales'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _exportExcel(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.backup_outlined, color: AppColors.success),
                      title: const Text('Respaldo local'),
                      subtitle: const Text('Copia de la informacion guardada en este dispositivo'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _exportBackup(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.upload_file_outlined, color: AppColors.warning),
                      title: const Text('Importar respaldo'),
                      subtitle: const Text('Restaura en este dispositivo un respaldo local'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _importBackup(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(child: VersionIndicator()),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showAddStoreDialog(BuildContext context) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva sucursal'),
        content: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: addressController, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Direccion', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: phoneController, keyboardType: TextInputType.phone, textInputAction: TextInputAction.done, inputFormatters: [phoneNumberInputFormatter], decoration: const InputDecoration(labelText: 'Telefono', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Crear')),
        ],
      ),
    );
  }

  void _exportExcel(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportando Excel...')),
    );
  }

  void _exportBackup(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Creando respaldo...')),
    );
  }

  void _importBackup(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Importando respaldo...')),
    );
  }

  Widget _configRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}









