import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../shared/models/employee.dart';
import '../../../../shared/models/store.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../shared/extensions/phone_x.dart';
import '../../../../shared/extensions/string_x.dart';
import '../../../../shared/widgets/bottom_padding.dart';

class EmployeesViewScreen extends StatefulWidget {
  final String businessId;
  final List<Store> stores;

  const EmployeesViewScreen({
    super.key,
    required this.businessId,
    required this.stores,
  });

  @override
  State<EmployeesViewScreen> createState() => _EmployeesViewScreenState();
}

class _EmployeesViewScreenState extends State<EmployeesViewScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Empleados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEmployeeDialog(context),
            tooltip: 'Nuevo empleado',
          ),
        ],
      ),
      body: StreamBuilder<List<Employee>>(
        stream: FirebaseFirestore.instance
            .collection('businesses')
            .doc(widget.businessId)
            .collection('employees')
            .snapshots()
            .map((s) => s.docs.map((d) => Employee.fromDoc(d)).toList()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final employees = snapshot.data ?? const <Employee>[];
          final filtered = employees.where((e) {
            if (_searchQuery.isNotEmpty && !e.name.toLowerCase().contains(_searchQuery.toLowerCase())) return false;
            return true;
          }).toList();

          if (filtered.isEmpty) {
            return const Center(child: Text('No hay empleados registrados.'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16).copyWith(
              bottom: BottomPadding.of(context, minimum: 16),
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final employee = filtered[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: employee.isAdmin ? AppColors.accent : Colors.grey,
                    child: Text(employee.name[0], style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(employee.name.orPlaceholder()),
                  subtitle: Text('${employee.role.orPlaceholder()} · ${employee.email.orPlaceholder()}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!employee.active)
                        const Icon(Icons.person_off, color: Colors.grey),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleAction(context, employee, value),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Editar')),
                          if (employee.isAdmin) const PopupMenuItem(value: 'permissions', child: Text('Permisos')),
                          if (!employee.isOwner) const PopupMenuItem(value: 'deactivate', child: Text('Desactivar')),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => _showEmployeeDialog(context, employee: employee),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleAction(BuildContext context, Employee employee, String action) {
    switch (action) {
      case 'edit':
        _showEmployeeDialog(context, employee: employee);
        break;
      case 'permissions':
        _showPermissionsDialog(context, employee);
        break;
      case 'deactivate':
        setState(() {
          // In real implementation, call repository
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${employee.name.orPlaceholder()} desactivado')),
        );
        break;
    }
  }

  void _showPermissionsDialog(BuildContext context, Employee employee) {
    final permissions = ['pos', 'receipts', 'products', 'shift', 'butcher', 'poultry', 'transfers', 'employees'];
    final selected = <String>{};
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permisos - ${employee.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: permissions.map((p) {
              final label = {
                'pos': 'Venta (POS)',
                'receipts': 'Recibos',
                'products': 'Productos',
                'shift': 'Turnos',
                'butcher': 'Destazar',
                'poultry': 'Polleria',
                'transfers': 'Traspasos',
                'employees': 'Empleados',
              }[p] ?? p;
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(label),
                value: selected.contains(p),
                onChanged: (v) => setState(() {
                  if (v == true) selected.add(p);
                  else selected.remove(p);
                }),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  void _showEmployeeDialog(BuildContext context, {Employee? employee}) {
    final isEditing = employee != null;
    final nameController = TextEditingController(text: employee?.name ?? '');
    final emailController = TextEditingController(text: employee?.email ?? '');
    final phoneController = TextEditingController(text: (employee?.phone ?? '').maskPhoneNumber);
    final roleController = DropdownButtonFormField<String>(
      value: employee?.role ?? 'cashier',
      items: const [
        DropdownMenuItem(value: 'owner', child: Text('Dueno')),
        DropdownMenuItem(value: 'admin', child: Text('Administrador')),
        DropdownMenuItem(value: 'manager', child: Text('Gerente')),
        DropdownMenuItem(value: 'cashier', child: Text('Cajero')),
      ],
      onChanged: (v) {},
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar empleado' : 'Nuevo empleado'),
        content: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: phoneController, keyboardType: TextInputType.phone, inputFormatters: [phoneNumberInputFormatter], decoration: const InputDecoration(labelText: 'Telefono', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Text('Rol', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              roleController,
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context), child: Text(isEditing ? 'Guardar' : 'Crear')),
        ],
      ),
    );
  }
}









