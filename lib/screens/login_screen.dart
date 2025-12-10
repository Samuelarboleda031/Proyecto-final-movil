import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/app_role.dart';
import '../models/usuario.dart';
import '../models/cliente.dart';
import '../models/barbero.dart';
import '../services/cliente_service.dart';
import '../services/barbero_service.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _obscureText = true;

  AppRole _selectedRole = AppRole.client; // Cliente por defecto

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String _homeRouteForRole(AppRole role) {
    switch (role) {
      case AppRole.client:
        return '/client_home';
      case AppRole.barber:
        return '/barber_home';
      case AppRole.admin:
        return '/home';
    }
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await _auth.signIn(_emailCtrl.text.trim(), _passCtrl.text);
      await _verificarAccesoYRedirigir();
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Error en autenticación');
    } catch (e) {
      _showMessage('Error inesperado');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() => _loading = true);
    try {
      final user = await _auth.signInWithGoogle();
      if (user != null) {
        await _verificarAccesoYRedirigir();
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Error en autenticación con Google');
    } catch (e) {
      _showMessage('Error inesperado con Google');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _verificarAccesoYRedirigir() async {
    final firebaseUser = _auth.currentUser;
    final emailActual = firebaseUser?.email ?? '(sin correo)';
    final rolSeleccionadoId = rolIdForRole(_selectedRole);
    print('[Login] Intentando ingresar $emailActual como ${roleLabel(_selectedRole)} (rolId=$rolSeleccionadoId)');

    Usuario? usuarioApi = await _auth.fetchUsuarioDesdeApi();

    // Fallback CONTROLADO a datos cacheados (solo si corresponden al mismo correo)
    if (usuarioApi == null && firebaseUser?.email != null) {
      final cached = await _auth.getCurrentUser();
      if (cached != null && cached.correo.toLowerCase() == firebaseUser!.email!.toLowerCase()) {
        print('[Login] Usando datos cacheados para ${cached.correo} con rolId ${cached.rolId}');
        usuarioApi = cached;
      }
    }

    if (usuarioApi == null) {
      // Si el usuario no existe en la API, intentamos crearlo con el rol seleccionado
      // Esto es común la primera vez que alguien entra con Google
      print('[Login] Usuario no encontrado en API. Intentando registrar con rol: ${roleLabel(_selectedRole)}');
      usuarioApi = await _auth.syncUsuarioConApi(rolId: rolSeleccionadoId);
      
      if (usuarioApi == null) {
        _showMessage('No fue posible registrar/validar tu usuario en la API. Intenta más tarde.');
        await _auth.signOut();
        return;
      }
    }

    if (usuarioApi.rolId == null) {
      _showMessage('Tu cuenta no tiene un rol asignado en la API. Contacta al administrador.');
      await _auth.signOut();
      return;
    }

    print('[Login] Rol en API para $emailActual: ${usuarioApi.rolId} (${roleLabelFromRolId(usuarioApi.rolId)})');

    if (usuarioApi.rolId != rolSeleccionadoId) {
      final rolCuenta = roleLabelFromRolId(usuarioApi.rolId);
      final rolSeleccion = roleLabel(_selectedRole);
      _showMessage('Tu cuenta está registrada como $rolCuenta. Ingresa seleccionando ese rol (no $rolSeleccion).');
      await _auth.signOut();
      return;
    }

    // --- LÓGICA DE AUTO-CREACIÓN DE PERFILES (CLIENTE / BARBERO) ---
    try {
      if (_selectedRole == AppRole.client) {
        final clienteService = ClienteService();
        final clienteExistente = await clienteService.obtenerClientePorUsuarioId(usuarioApi.id!);
        
        if (clienteExistente == null) {
          print('[Login] Creando perfil de Cliente automáticamente para ${usuarioApi.correo}');
          // Crear cliente con datos básicos
          final nuevoCliente = Cliente(
            documento: 'G-${DateTime.now().millisecondsSinceEpoch}', // Documento temporal/generado
            nombre: firebaseUser?.displayName?.split(' ').first ?? 'Usuario',
            apellido: firebaseUser?.displayName?.split(' ').skip(1).join(' ') ?? 'Google',
            email: usuarioApi.correo,
            usuarioId: usuarioApi.id,
            estado: true,
          );
          await clienteService.crearCliente(nuevoCliente);
          print('[Login] Perfil de Cliente creado exitosamente.');
        } else {
          print('[Login] Perfil de Cliente ya existe.');
        }
      } else if (_selectedRole == AppRole.barber) {
        final barberoService = BarberoService();
        final barberoExistente = await barberoService.obtenerBarberoPorUsuarioId(usuarioApi.id!);

        if (barberoExistente == null) {
          print('[Login] Creando perfil de Barbero automáticamente para ${usuarioApi.correo}');
          // Crear barbero con datos básicos
          final nuevoBarbero = Barbero(
            documento: 'G-${DateTime.now().millisecondsSinceEpoch}',
            nombre: firebaseUser?.displayName?.split(' ').first ?? 'Barbero',
            apellido: firebaseUser?.displayName?.split(' ').skip(1).join(' ') ?? 'Google',
            email: usuarioApi.correo,
            usuarioId: usuarioApi.id,
            estado: true,
            // La API espera DateOnly (yyyy-MM-dd), no ISO completo con hora
            fechaIngreso: DateTime.now().toIso8601String().split('T').first, 
          );
          await barberoService.crearBarbero(nuevoBarbero);
          print('[Login] Perfil de Barbero creado exitosamente.');
        } else {
          print('[Login] Perfil de Barbero ya existe.');
        }
      }
    } catch (e) {
      print('[Login] Error en auto-creación de perfil: $e');
      if (mounted) {
        _showMessage('Error al crear tu perfil de ${_selectedRole == AppRole.client ? 'Cliente' : 'Barbero'}: $e');
      }
      await _auth.signOut();
      return;
    }
    // ---------------------------------------------------------------

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, _homeRouteForRole(_selectedRole));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Image.asset(
                'assets/images/logo.png',
                height: 150,
              ),
              const SizedBox(height: 24),
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
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Usuario (correo)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'Clave',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Iniciar Sesión'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _googleLogin,
                  icon: const Icon(Icons.g_mobiledata, size: 24), // O usa un asset de Google
                  label: const Text('Iniciar con Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('¿Aún no tienes cuenta?'),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text('Registrarte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

