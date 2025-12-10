import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/cliente_service.dart';
import '../services/barbero_service.dart';
import '../models/app_role.dart';
import '../models/usuario.dart';
import '../models/cliente.dart';
import '../models/barbero.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _emailConfirmCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();
  final _auth = AuthService();
  final _clienteService = ClienteService();
  final _barberoService = BarberoService();
  bool _loading = false;
  AppRole _selectedRole = AppRole.client; // Por defecto, cliente

  String _generateDocumentoTemp() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final suffix = timestamp.length > 12
        ? timestamp.substring(timestamp.length - 12)
        : timestamp.padLeft(12, '0');
    return 'TMP$suffix'; // 3 + 12 = 15 caracteres máx.
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _emailConfirmCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _register() async {
    final email = _emailCtrl.text.trim();
    final emailConf = _emailConfirmCtrl.text.trim();
    final pass = _passCtrl.text;
    final passConf = _passConfirmCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      _showMessage('Complete todos los campos');
      return;
    }
    if (email != emailConf) {
      _showMessage('Los correos no coinciden');
      return;
    }
    if (pass != passConf) {
      _showMessage('Las contraseñas no coinciden');
      return;
    }

    setState(() => _loading = true);
    try {
      await _auth.signUp(email, pass);
      // Sincronizar también el usuario con la API usando el rol elegido
      final usuarioApi = await _auth.syncUsuarioConApi(
        rolId: rolIdForRole(_selectedRole),
        contrasena: pass,
      );
      
      // Crear el registro de rol si el usuario fue creado exitosamente
      if (usuarioApi != null && usuarioApi.id != null) {
        await _crearRegistroRol(usuarioApi);
      }
      
      await _auth.sendEmailVerification();
      _showMessage('Cuenta creada. Revise su correo para verificar la cuenta.');
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Error al registrar');
    } catch (e) {
      _showMessage('Error inesperado');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _crearRegistroRol(Usuario usuarioApi) async {
    if (usuarioApi.id == null) {
      return;
    }

    final usuarioId = usuarioApi.id!;

    try {
      if (_selectedRole == AppRole.barber) {
        // Verificar si ya existe
        final existente = await _barberoService.obtenerBarberoPorUsuarioId(usuarioId);
        if (existente != null) return;

        // Crear registro de barbero
        final barbero = Barbero(
          documento: _generateDocumentoTemp(),
          nombre: 'Por completar',
          apellido: 'Por completar',
          email: usuarioApi.correo,
          usuarioId: usuarioId,
          estado: true,
        );
        await _barberoService.crearBarbero(barbero);
      } else if (_selectedRole == AppRole.client) {
        // Verificar si ya existe
        final existente = await _clienteService.obtenerClientePorUsuarioId(usuarioId);
        if (existente != null) return;

        // Crear registro de cliente
        final cliente = Cliente(
          documento: _generateDocumentoTemp(),
          nombre: 'Por completar',
          apellido: 'Por completar',
          email: usuarioApi.correo,
          usuarioId: usuarioId,
          estado: true,
        );
        await _clienteService.crearCliente(cliente);
      }
      // Rol administrador: no requiere registro adicional
    } catch (e) {
      print('Error al crear registro de rol: $e');
      // No bloquear el registro si falla la creación del rol
      // El usuario puede completar su perfil más tarde
    }
  }

  Future<void> _googleRegister() async {
    setState(() => _loading = true);
    try {
      final user = await _auth.signInWithGoogle();
      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Error en registro con Google');
    } catch (e) {
      _showMessage('Error inesperado con Google');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrarse')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Selector de rol
            Wrap(
              spacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Cliente'),
                  selected: _selectedRole == AppRole.client,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedRole = AppRole.client);
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Barbero'),
                  selected: _selectedRole == AppRole.barber,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedRole = AppRole.barber);
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Administrador'),
                  selected: _selectedRole == AppRole.admin,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedRole = AppRole.admin);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Correo'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextField(controller: _emailConfirmCtrl, decoration: const InputDecoration(labelText: 'Confirmar correo'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true),
            const SizedBox(height: 12),
            TextField(controller: _passConfirmCtrl, decoration: const InputDecoration(labelText: 'Confirmar contraseña'), obscureText: true),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Registrarse'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _googleRegister,
                icon: const Icon(Icons.g_mobiledata, size: 24),
                label: const Text('Registrarse con Google'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}