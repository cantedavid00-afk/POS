import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/domain/app_context_repository.dart';
import '../../../features/auth/domain/auth_repository.dart';
import '../../../shared/widgets/bottom_padding.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({
    super.key,
    required this.onCreated,
    required this.authRepository,
  });

  final VoidCallback onCreated;
  final AuthRepository authRepository;

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  AuthRepository get _authService => widget.authRepository;
  final _businessNameController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;
  String? _diagnosis;
  bool _diagnosing = true;

  @override
  void initState() {
    super.initState();
    _runDiagnosis();
  }

  Future<void> _runDiagnosis() async {
    setState(() {
      _diagnosing = true;
    });
    try {
      final code = await context.read<AppContextRepository>().diagnoseNoSession();
      if (!mounted) return;
      setState(() => _diagnosis = code);
    } catch (_) {
      if (!mounted) return;
      setState(() => _diagnosis = 'error');
    } finally {
      if (mounted) setState(() => _diagnosing = false);
    }
  }

  String _diagnosisMessage(String code, String email) {
    switch (code) {
      case 'no-user-doc':
      case 'no-business-id':
        return 'La cuenta $email no tiene ningún negocio vinculado. '
            'Entra con la cuenta del dueño (la misma con la que creaste la pollería en el celular).';
      case 'no-stores':
        return 'Tu cuenta sí está vinculada, pero no ve ninguna sucursal activa. '
            'Desde el celular revisa que haya al menos una sucursal activa y tu empleado asignado a ella.';
      case 'offline-no-cache':
        return 'Sin conexión y este equipo aún no descarga tu negocio. '
            'Conéctate a internet y pulsa Reintentar.';
      case 'no-business-or-employee':
        return 'No pudimos abrir tu negocio con esta cuenta (sin acceso o datos incompletos). '
            'Verifica tu conexión o entra con la cuenta del dueño.';
      default:
        return 'No pudimos cargar tu sesión. Revisa tu conexión y pulsa Reintentar.';
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final businessName = _businessNameController.text.trim();
    if (businessName.isEmpty) {
      setState(() => _errorMessage = 'Ingresa el nombre de tu empresa');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _authService.createOwnerWorkspace(businessName: businessName);
      if (!mounted) return;
      widget.onCreated();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar empresa'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesion',
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.all(24).copyWith(
            bottom: BottomPadding.of(context, minimum: 24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                const Icon(Icons.storefront, size: 64, color: Colors.indigo),
                const SizedBox(height: 16),
                Text(
                  'Antes de vender, crea tu empresa',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la empresa',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Crear empresa'),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Si tu pollería ya está registrada, no crees otra: '
                  'cierra sesión arriba e inicia sesión con la cuenta del dueño '
                  'para administrar tus sucursales.',
                  textAlign: TextAlign.center,
                ),
                TextButton.icon(
                  onPressed: _isSaving ? null : _signOut,
                  icon: const Icon(Icons.login),
                  label: const Text('Ya tengo negocio, entrar'),
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                if (_diagnosing)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  Builder(builder: (context) {
                    final email = FirebaseAuth.instance.currentUser?.email ?? 'esta cuenta';
                    return Text(
                      'Sesión: $email\n${_diagnosisMessage(_diagnosis ?? 'error', email)}',
                      textAlign: TextAlign.center,
                    );
                  }),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      widget.onCreated();
                      _runDiagnosis();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
