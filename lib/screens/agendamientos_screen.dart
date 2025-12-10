import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/agendamiento.dart';
import '../services/agendamiento_service.dart';
import '../services/auxiliar_service.dart'; // Import AuxiliarService
import '../models/cliente.dart'; // Import Cliente
import '../models/barbero.dart'; // Import Barbero
import 'agendamiento_form_screen.dart';

import '../models/app_role.dart';
import '../widgets/session_guard.dart';
import '../widgets/side_menu.dart';

class AgendamientosScreen extends StatefulWidget {
  const AgendamientosScreen({super.key});

  @override
  State<AgendamientosScreen> createState() => _AgendamientosScreenState();
}

class _AgendamientosScreenState extends State<AgendamientosScreen> {
  final AgendamientoService _agendamientoService = AgendamientoService();
  final AuxiliarService _auxiliarService = AuxiliarService(); // Instantiate AuxiliarService
  List<Agendamiento> _agendamientos = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filtroEstado = 'Todos';

  @override
  void initState() {
    super.initState();
    _cargarAgendamientos();
  }

  Future<void> _cargarAgendamientos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final agendamientos = await _agendamientoService.obtenerAgendamientos();
      setState(() {
        _agendamientos = agendamientos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar agendamientos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Agendamiento> get _agendamientosFiltrados {
    var filtrados = _agendamientos;

    // Filtro por estado
    if (_filtroEstado != 'Todos') {
      filtrados = filtrados
          .where((a) => a.estadoCita == _filtroEstado)
          .toList();
    }

    // Filtro por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtrados = filtrados.where((agendamiento) {
        final cliente = agendamiento.cliente?.nombreCompleto.toLowerCase() ?? '';
        final barbero = agendamiento.barbero?.nombreCompleto.toLowerCase() ?? '';
        final servicio = agendamiento.servicio?.nombre.toLowerCase() ?? '';
        final paquete = agendamiento.paquete?.nombre.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return cliente.contains(query) ||
            barbero.contains(query) ||
            servicio.contains(query) ||
            paquete.contains(query);
      }).toList();
    }

    return filtrados;
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'confirmado':
        return Colors.blue;
      case 'completado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _verDetallesAgendamiento(Agendamiento agendamientoResumen) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final agendamiento = await _agendamientoService.obtenerAgendamientoPorId(agendamientoResumen.id!);

      // Lógica para obtener nombres si vienen nulos (fallback)
      String clienteNombre = agendamiento.cliente?.nombreCompleto ?? 'N/A';
      String barberoNombre = agendamiento.barbero?.nombreCompleto ?? 'N/A';

      if (agendamiento.cliente == null || agendamiento.barbero == null) {
        try {
          // Si falta alguno, cargamos las listas para buscar por ID
          if (agendamiento.cliente == null) {
             final clientes = await _auxiliarService.obtenerClientes();
             final cliente = clientes.firstWhere(
               (c) => c.id == agendamiento.clienteId, 
               orElse: () => Cliente(id: 0, documento: '', nombre: 'Desconocido', apellido: '', telefono: '', email: '', direccion: '', estado: true)
             );
             clienteNombre = cliente.nombreCompleto;
          }
          
          if (agendamiento.barbero == null) {
             final barberos = await _auxiliarService.obtenerBarberos();
             final barbero = barberos.firstWhere(
               (b) => b.id == agendamiento.barberoId, 
               orElse: () => Barbero(id: 0, documento: '', nombre: 'Desconocido', apellido: '', telefono: '', email: '', direccion: '', estado: true)
             );
             barberoNombre = barbero.nombreCompleto;
          }
        } catch (e) {
          print('Error recuperando datos auxiliares: $e');
        }
      }

      if (!mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Detalles Cita'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Tipo:', agendamiento.servicio != null ? 'Servicio' : 'Paquete'),
                _buildDetailRow('Nombre:', agendamiento.servicio?.nombre ?? agendamiento.paquete?.nombre ?? 'N/A'),
                const Divider(),
                _buildDetailRow('Cliente:', clienteNombre),
                _buildDetailRow('Barbero:', barberoNombre),
                const Divider(),
                _buildDetailRow('Fecha:', DateFormat('dd/MM/yyyy').format(DateTime.parse(agendamiento.fechaCita))),
                _buildDetailRow('Hora:', '${agendamiento.horaInicio} - ${agendamiento.horaFin}'),
                _buildDetailRow('Estado:', agendamiento.estadoCita),
                if (agendamiento.monto != null)
                  _buildDetailRow('Monto:', '\$${agendamiento.monto!.toStringAsFixed(2)}', isBold: true),
                if (agendamiento.observaciones != null && agendamiento.observaciones!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text('Observaciones:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(agendamiento.observaciones!),
                    ],
                  ),
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
        SnackBar(content: Text('Error al cargar detalles: $e'), backgroundColor: Colors.red),
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
          Flexible(child: Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Future<void> _eliminarAgendamiento(Agendamiento agendamiento) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Agendamiento'),
        content: Text(
            '¿Está seguro que desea eliminar el agendamiento del ${agendamiento.fechaCita}?'),
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
        await _agendamientoService.eliminarAgendamiento(agendamiento.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Agendamiento eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarAgendamientos();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar agendamiento: $e'),
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
      requiredRole: AppRole.admin,
      child: Scaffold(
        drawer: const SideMenu(),
        appBar: AppBar(title: const Text('Agendamientos')),
        body: Column(
          children: [
            // Barra de búsqueda y filtros
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por cliente, barbero o servicio...',
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
                    initialValue: _filtroEstado,
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
                    items: ['Todos', 'Pendiente', 'Confirmado', 'Completado', 'Cancelado']
                        .map((estado) {
                      return DropdownMenuItem(
                        value: estado,
                        child: Text(estado),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _filtroEstado = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            // Lista de agendamientos
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
                                    ? 'No hay agendamientos registrados'
                                    : 'No se encontraron agendamientos',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarAgendamientos,
                          child: ListView.builder(
                            itemCount: _agendamientosFiltrados.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemBuilder: (context, index) {
                              final agendamiento = _agendamientosFiltrados[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          agendamiento.servicio != null
                                              ? 'Servicio: ${agendamiento.servicio!.nombre}'
                                              : agendamiento.paquete != null
                                                  ? 'Paquete: ${agendamiento.paquete!.nombre}'
                                                  : 'Cita General',
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
                                          color: _getEstadoColor(agendamiento.estadoCita)
                                              .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _getEstadoColor(agendamiento.estadoCita),
                                          ),
                                        ),
                                        child: Text(
                                          agendamiento.estadoCita,
                                          style: TextStyle(
                                            color: _getEstadoColor(agendamiento.estadoCita),
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
                                      if (agendamiento.cliente != null)
                                        Row(
                                          children: [
                                            const Icon(Icons.person, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Cliente: ${agendamiento.cliente!.nombreCompleto}',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (agendamiento.barbero != null)
                                        Row(
                                          children: [
                                            const Icon(Icons.content_cut, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Barbero: ${agendamiento.barbero!.nombreCompleto}',
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
                                            'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(agendamiento.fechaCita))}',
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
                                            'Hora: ${agendamiento.horaInicio} - ${agendamiento.horaFin}',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (agendamiento.monto != null)
                                        const SizedBox(height: 4),
                                      if (agendamiento.monto != null)
                                        Text(
                                          'Monto: \$${agendamiento.monto!.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white, // Or Theme.of(context).primaryColor
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
                                            Text('Eliminar',
                                                style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'details') {
                                        _verDetallesAgendamiento(agendamiento);
                                      } else if (value == 'edit') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AgendamientoFormScreen(
                                                    agendamiento: agendamiento),
                                          ),
                                        ).then((_) => _cargarAgendamientos());
                                      } else if (value == 'delete') {
                                        _eliminarAgendamiento(agendamiento);
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
                builder: (context) => const AgendamientoFormScreen(),
              ),
            ).then((_) => _cargarAgendamientos());
          },
          backgroundColor: const Color(0xFFD8B081),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

