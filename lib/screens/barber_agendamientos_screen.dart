import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/agendamiento.dart';
import '../models/barbero.dart';
import '../models/cliente.dart';
import '../services/agendamiento_service.dart';
import '../services/auxiliar_service.dart';
import '../services/auth_service.dart';
import '../models/app_role.dart';
import '../utils/estado_cita.dart';
import '../widgets/session_guard.dart';
import '../widgets/side_menu.dart';
import 'barber_agendamiento_form_screen.dart';

class BarberAgendamientosScreen extends StatefulWidget {
  const BarberAgendamientosScreen({super.key});

  @override
  State<BarberAgendamientosScreen> createState() => _BarberAgendamientosScreenState();
}

class _BarberAgendamientosScreenState extends State<BarberAgendamientosScreen> {
  final AgendamientoService _agendamientoService = AgendamientoService();
  final AuxiliarService _auxiliarService = AuxiliarService();
  final AuthService _authService = AuthService();

  List<Agendamiento> _agendamientos = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filtroEstado = 'Todos';

  @override
  void initState() {
    super.initState();
    _cargarAgendamientosBarbero();
  }

  Future<void> _cargarAgendamientosBarbero() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No se pudo identificar al usuario actual como barbero.');
      }

      final barberos = await _auxiliarService.obtenerBarberos();
      final barbero = barberos.firstWhere(
        (b) => (b.email ?? '').toLowerCase() == user.email!.toLowerCase(),
        orElse: () => Barbero(
          id: 0,
          documento: '',
          nombre: 'Barbero',
          apellido: 'Desconocido',
          telefono: '',
          email: user.email,
          direccion: '',
          estado: true,
        ),
      );

      final todos = await _agendamientoService.obtenerAgendamientos();

      final propios = todos.where((a) {
        final coincideId = barbero.id != null && barbero.id != 0 && a.barberoId == barbero.id;
        final coincideEmail = a.barbero?.email != null &&
            barbero.email != null &&
            a.barbero!.email!.toLowerCase() == barbero.email!.toLowerCase();
        return coincideId || coincideEmail;
      }).toList();

      setState(() {
        _agendamientos = propios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar tus citas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Agendamiento> get _agendamientosFiltrados {
    var filtrados = _agendamientos;

    if (_filtroEstado != 'Todos') {
      filtrados = filtrados.where((a) => a.estadoCita == _filtroEstado).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtrados = filtrados.where((a) {
        final cliente = a.cliente?.nombreCompleto.toLowerCase() ?? '';
        final servicio = a.servicio?.nombre.toLowerCase() ?? '';
        final paquete = a.paquete?.nombre.toLowerCase() ?? '';
        return cliente.contains(q) || servicio.contains(q) || paquete.contains(q);
      }).toList();
    }

    return filtrados;
  }

  Future<void> _verDetallesAgendamiento(Agendamiento ag) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final full = await _agendamientoService.obtenerAgendamientoPorId(ag.id!);

      String clienteNombre = full.cliente?.nombreCompleto ?? 'N/A';

      if (full.cliente == null || full.barbero == null) {
        try {
          if (full.cliente == null) {
            final clientes = await _auxiliarService.obtenerClientes();
            final cliente = clientes.firstWhere(
              (c) => c.id == full.clienteId,
              orElse: () => Cliente(
                id: 0,
                documento: '',
                nombre: 'Desconocido',
                apellido: '',
                telefono: '',
                email: '',
                direccion: '',
                estado: true,
              ),
            );
            clienteNombre = cliente.nombreCompleto;
          }
        } catch (_) {}
      }

      if (!mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Detalles de la Cita'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Cliente:', clienteNombre),
                _buildDetailRow('Servicio/Paquete:',
                    full.servicio?.nombre ?? full.paquete?.nombre ?? 'N/A'),
                const Divider(),
                _buildDetailRow(
                  'Fecha:',
                  DateFormat('dd/MM/yyyy').format(DateTime.parse(full.fechaCita)),
                ),
                _buildDetailRow('Hora:', '${full.horaInicio} - ${full.horaFin}'),
                _buildDetailRow('Estado:', full.estadoCita),
                if (full.monto != null)
                  _buildDetailRow(
                    'Monto:',
                    '\$${full.monto!.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                if (full.observaciones != null && full.observaciones!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Observaciones:', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(full.observaciones!),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar detalles: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarAgendamiento(Agendamiento ag) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cita'),
        content: Text('¿Está seguro que desea eliminar la cita del ${ag.fechaCita}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _agendamientoService.eliminarAgendamiento(ag.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita eliminada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarAgendamientosBarbero();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar cita: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SessionGuard(
      requiredRole: AppRole.barber,
      child: Scaffold(
        drawer: const SideMenu(isBarber: true),
      appBar: AppBar(
        title: const Text('Mis Citas'),
      ),
      body: Column(
        children: [
          // Búsqueda y filtro
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por cliente o servicio...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _filtroEstado,
                  decoration: InputDecoration(
                    labelText: 'Filtrar por estado',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: EstadoCita.todosConFiltro
                      .map((estado) => DropdownMenuItem<String>(
                            value: estado,
                            child: Text(estado),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _filtroEstado = value ?? 'Todos';
                    });
                  },
                ),
              ],
            ),
          ),
          // Lista
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _agendamientosFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty && _filtroEstado == 'Todos'
                                  ? 'No tienes citas registradas'
                                  : 'No se encontraron citas',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarAgendamientosBarbero,
                        child: ListView.builder(
                          itemCount: _agendamientosFiltrados.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final ag = _agendamientosFiltrados[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ag.servicio != null
                                            ? 'Servicio: ${ag.servicio!.nombre}'
                                            : ag.paquete != null
                                                ? 'Paquete: ${ag.paquete!.nombre}'
                                                : 'Cita',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                     Container(
                                       padding: const EdgeInsets.symmetric(
                                         horizontal: 8,
                                         vertical: 4,
                                       ),
                                       decoration: BoxDecoration(
                                         color: EstadoCita.getColor(ag.estadoCita).withAlpha(50),
                                         borderRadius: BorderRadius.circular(12),
                                         border: Border.all(
                                           color: EstadoCita.getColor(ag.estadoCita),
                                         ),
                                      ),
                                       child: Text(
                                         ag.estadoCita,
                                         style: TextStyle(
                                           color: EstadoCita.getColor(ag.estadoCita),
                                           fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    if (ag.cliente != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.person, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Cliente: ${ag.cliente!.nombreCompleto}',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(ag.fechaCita))}',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Hora: ${ag.horaInicio} - ${ag.horaFin}',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (ag.monto != null) const SizedBox(height: 4),
                                    if (ag.monto != null)
                                      Text(
                                        'Monto: \$${ag.monto!.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'details',
                                      child: Row(
                                        children: [
                                          Icon(Icons.visibility, size: 20, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Ver Detalles'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: 8),
                                          Text('Editar'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 20, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'details') {
                                      _verDetallesAgendamiento(ag);
                                    } else if (value == 'edit') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              BarberAgendamientoFormScreen(
                                            agendamiento: ag,
                                          ),
                                        ),
                                      ).then((_) => _cargarAgendamientosBarbero());
                                    } else if (value == 'delete') {
                                      _eliminarAgendamiento(ag);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BarberAgendamientoFormScreen(),
            ),
          ).then((_) => _cargarAgendamientosBarbero());
        },
        backgroundColor: const Color(0xFFD8B081),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      ),
    );
  }
}


