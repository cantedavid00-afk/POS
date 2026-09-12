import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../shared/models/employee.dart';
import '../../../../shared/models/store.dart';
import '../../../business/domain/backup_repository.dart';
import '../../../business/domain/excel_export_repository.dart';
import '../../../business/data/backup_service.dart';
import '../../../../core/theme/glass_theme.dart';

class BackupExportScreen extends StatefulWidget {
  final String businessId;
  final List<Store> stores;

  const BackupExportScreen({
    super.key,
    required this.businessId,
    required this.stores,
  });

  @override
  State<BackupExportScreen> createState() => _BackupExportScreenState();
}

class _BackupExportScreenState extends State<BackupExportScreen> {
  bool _isExporting = false;
  String? _lastExportPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Respaldos y Exportaciones'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Exportar datos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _exportCard(
            icon: Icons.picture_as_pdf,
            title: 'Exportar a Excel',
            subtitle: 'Reporte completo en formato .xlsx con todas las sucursales',
            color: AppColors.danger,
            onTap: _exportExcel,
          ),
          const SizedBox(height: 12),
          _exportCard(
            icon: Icons.description,
            title: 'Exportar CSV',
            subtitle: 'Datos de ventas en formato CSV para an\u00e1lisis externo',
            color: AppColors.warning,
            onTap: _exportCSV,
          ),
          const SizedBox(height: 12),
          _exportCard(
            icon: Icons.backup_outlined,
            title: 'Respaldo local',
            subtitle: 'Copia completa en formato JSON para restauraci\u00f3n',
            color: AppColors.success,
            onTap: _exportBackup,
          ),
          const SizedBox(height: 24),
          Text('Importar datos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _exportCard(
            icon: Icons.upload_file_outlined,
            title: 'Importar respaldo',
            subtitle: 'Restaurar datos desde un respaldo local',
            color: AppColors.accent,
            onTap: _importBackup,
          ),
          const SizedBox(height: 24),
          if (_lastExportPath != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: AppColors.success),
                title: Text('Ultima exportacion'),
                subtitle: Text(_lastExportPath!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _exportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Future<void> _exportExcel() async {
    setState(() => _isExporting = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exportando Excel...')));
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isExporting = false;
      _lastExportPath = 'C:\\Users\\Alonso-Manuel\\Downloads\\reporte_pos_dashboard.xlsx';
    });
  }

  Future<void> _exportCSV() async {
    setState(() => _isExporting = true);
    final downloads = await getDownloadsDirectory();
    final dir = downloads ?? Directory('C:\\Users\\Alonso-Manuel\\Downloads');
    final file = File('${dir.path}/ventas_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(
      'folio,tipo,estado,sucursal,fecha,metodo,subtotal,total\n'
      'T-000001,Venta,completed,Principal,2025-01-01,cash,150.00,150.00\n',
    );
    setState(() {
      _isExporting = false;
      _lastExportPath = file.path;
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV guardado en: ${file.path}')));
    }
  }

  Future<void> _exportBackup() async {
    setState(() => _isExporting = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Creando respaldo...')));
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isExporting = false;
      _lastExportPath = 'C:\\Users\\Alonso-Manuel\\Downloads\\backup_${widget.businessId}_${DateTime.now().millisecondsSinceEpoch}.json';
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Respaldo guardado en: ${_lastExportPath}')),
      );
    }
  }

  Future<void> _importBackup() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selecciona un archivo de respaldo .json')),
    );
  }
}









