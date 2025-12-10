import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/agendamiento.dart';
import '../models/cliente.dart';
import '../models/barbero.dart';
import '../models/servicio.dart';
import '../models/paquete.dart';
import '../services/agendamiento_service.dart';
import '../services/auxiliar_service.dart';
import '../models/app_role.dart';
import '../widgets/session_guard.dart';

class AgendamientoFormScreen extends StatefulWidget {
  final Agendamiento? agendamiento;

  const AgendamientoFormScreen({super.key, this.agendamiento});

  @override
  State<AgendamientoFormScreen> createState() => _AgendamientoFormScreenState();
}

class _AgendamientoFormScreenState extends State<AgendamientoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AgendamientoService _agendamientoService = AgendamientoService();
  final AuxiliarService _auxiliarService = AuxiliarService();

  List<Cliente> _clientes = [];
  List<Barbero> _barberos = [];
  List<Servicio> _servicios = [];
  List<Paquete> _paquetes = [];

  Cliente? _clienteSeleccionado;
  Barbero? _barberoSeleccionado;
  Servicio? _servicioSeleccionado;
  Paquete? _paqueteSeleccionado;
  DateTime _fechaSeleccionada = DateTime.now();
  TimeOfDay _horaInicio = TimeOfDay.now();
  TimeOfDay _horaFin = TimeOfDay.now();
  String _estadoCita = 'Pendiente';
  double? _monto;
  String? _observaciones;

  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _esServicio = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos().then((_) {
      if (widget.agendamiento != null && mounted) {
        setState(() {
          // Buscar y asignar el cliente de la lista cargada
          _clienteSeleccionado = _clientes.firstWhere(
            (cliente) => cliente.id == widget.agendamiento!.clienteId,
            orElse: () => widget.agendamiento!.cliente!,
          );
          
          // Buscar y asignar el barbero de la lista cargada
          _barberoSeleccionado = _barberos.firstWhere(
            (barbero) => barbero.id == widget.agendamiento!.barberoId,
            orElse: () => widget.agendamiento!.barbero!,
          );
          
          // Buscar y asignar el servicio de la lista cargada si existe
          if (widget.agendamiento!.servicioId != null) {
            _servicioSeleccionado = _servicios.firstWhere(
              (servicio) => servicio.id == widget.agendamiento!.servicioId,
              orElse: () => widget.agendamiento!.servicio!, // Ya tenía el !
            );
            _esServicio = true;
          }
          
          // Buscar y asignar el paquete de la lista cargada si existe
          if (widget.agendamiento!.paqueteId != null) {
            _paqueteSeleccionado = _paquetes.firstWhere(
              (paquete) => paquete.id == widget.agendamiento!.paqueteId,
              orElse: () => widget.agendamiento!.paquete!, // Ya tenía el !
            );
            _esServicio = false;
          }
          
          _fechaSeleccionada = DateTime.parse(widget.agendamiento!.fechaCita);
          
          // Configurar horas
          final horaInicioParts = widget.agendamiento!.horaInicio.split(':');
          _horaInicio = TimeOfDay(
            hour: int.parse(horaInicioParts[0]),
            minute: int.parse(horaInicioParts[1]),
          );
          
          final horaFinParts = widget.agendamiento!.horaFin.split(':');
          _horaFin = TimeOfDay(
            hour: int.parse(horaFinParts[0]),
            minute: int.parse(horaFinParts[1]),
          );
          
          _estadoCita = widget.agendamiento!.estadoCita;
          _monto = widget.agendamiento!.monto;
          _observaciones = widget.agendamiento!.observaciones;
        });
      }
    });
  }

  Future<void> _cargarDatos() async {
    try {
      final clientes = await _auxiliarService.obtenerClientes();
      final barberos = await _auxiliarService.obtenerBarberos();
      final servicios = await _auxiliarService.obtenerServicios();
      final paquetes = await _auxiliarService.obtenerPaquetes();

      setState(() {
        _clientes = clientes;
        _barberos = barberos;
        _servicios = servicios;
        _paquetes = paquetes;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  Future<void> _selectHoraInicio() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaInicio,
    );
    if (picked != null && picked != _horaInicio) {
      setState(() {
        _horaInicio = picked;
        // Ajustar hora fin si es menor que hora inicio
        if (_horaInicio.hour > _horaFin.hour ||
            (_horaInicio.hour == _horaFin.hour &&
                _horaInicio.minute >= _horaFin.minute)) {
          _horaFin = TimeOfDay(
            hour: _horaInicio.hour,
            minute: (_horaInicio.minute + 30) % 60,
          );
        }
      });
    }
  }

  Future<void> _selectHoraFin() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaFin,
    );
    if (picked != null && picked != _horaFin) {
      // Validar que hora fin sea mayor que hora inicio
      if (picked.hour > _horaInicio.hour ||
          (picked.hour == _horaInicio.hour &&
              picked.minute > _horaInicio.minute)) {
        setState(() {
          _horaFin = picked;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La hora de fin debe ser mayor que la hora de inicio'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _guardarAgendamiento() async {
    if (_formKey.currentState!.validate()) {
      if (_clienteSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor seleccione un cliente'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_barberoSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor seleccione un barbero'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_esServicio && _servicioSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor seleccione un servicio'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!_esServicio && _paqueteSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor seleccione un paquete'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final horaInicioStr =
            '${_horaInicio.hour.toString().padLeft(2, '0')}:${_horaInicio.minute.toString().padLeft(2, '0')}';
        final horaFinStr =
            '${_horaFin.hour.toString().padLeft(2, '0')}:${_horaFin.minute.toString().padLeft(2, '0')}';

        final agendamiento = Agendamiento(
          id: widget.agendamiento?.id,
          clienteId: _clienteSeleccionado!.id!,
          barberoId: _barberoSeleccionado!.id!,
          servicioId: _esServicio ? _servicioSeleccionado!.id : null,
          paqueteId: !_esServicio ? _paqueteSeleccionado!.id : null,
          fechaCita: DateFormat('yyyy-MM-dd').format(_fechaSeleccionada),
          horaInicio: horaInicioStr,
          horaFin: horaFinStr,
          estadoCita: _estadoCita,
          monto: _monto,
          observaciones: _observaciones,
        );

        if (widget.agendamiento == null) {
          await _agendamientoService.crearAgendamiento(agendamiento);
        } else {
          await _agendamientoService.actualizarAgendamiento(agendamiento);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.agendamiento == null
                  ? 'Agendamiento creado exitosamente'
                  : 'Agendamiento actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar agendamiento: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SessionGuard(
      requiredRole: AppRole.admin,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.agendamiento == null
              ? 'Nuevo Agendamiento'
              : 'Editar Agendamiento'),
          backgroundColor: Colors.brown.shade800,
          foregroundColor: Colors.white,
        ),
        body: _isLoadingData
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    // Tipo de cita
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('Servicio')),
                        ButtonSegment(value: false, label: Text('Paquete')),
                      ],
                      selected: {_esServicio},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() {
                          _esServicio = newSelection.first;
                          _servicioSeleccionado = null;
                          _paqueteSeleccionado = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Cliente
                    DropdownButtonFormField<Cliente>(
                      value: _clienteSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Cliente *',
                        border: OutlineInputBorder(),
                      ),
                      items: _clientes.map((cliente) {
                        return DropdownMenuItem(
                          value: cliente,
                          child: Text(cliente.nombreCompleto),
                        );
                      }).toList(),
                      onChanged: (cliente) {
                        setState(() {
                          _clienteSeleccionado = cliente;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Seleccione un cliente';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Barbero
                    DropdownButtonFormField<Barbero>(
                      value: _barberoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Barbero *',
                        border: OutlineInputBorder(),
                      ),
                      items: _barberos.map((barbero) {
                        return DropdownMenuItem(
                          value: barbero,
                          child: Text(barbero.nombreCompleto),
                        );
                      }).toList(),
                      onChanged: (barbero) {
                        setState(() {
                          _barberoSeleccionado = barbero;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Seleccione un barbero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Servicio o Paquete
                    if (_esServicio)
                      DropdownButtonFormField<Servicio>(
                        value: _servicioSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Servicio *',
                          border: OutlineInputBorder(),
                        ),
                        items: _servicios.map((servicio) {
                          return DropdownMenuItem(
                            value: servicio,
                            child: Text(
                                '${servicio.nombre} - \$${servicio.precio.toStringAsFixed(2)}'),
                          );
                        }).toList(),
                        onChanged: (servicio) {
                          setState(() {
                            _servicioSeleccionado = servicio;
                            _monto = servicio?.precio;
                            _paqueteSeleccionado = null; // Limpiar selección de paquete
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Seleccione un servicio';
                          }
                          return null;
                        },
                      )
                    else
                      DropdownButtonFormField<Paquete>(
                        value: _paqueteSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Paquete *',
                          border: OutlineInputBorder(),
                        ),
                        items: _paquetes.map((paquete) {
                          return DropdownMenuItem(
                            value: paquete,
                            child: Text(
                                '${paquete.nombre} - \$${paquete.precio.toStringAsFixed(2)}'),
                          );
                        }).toList(),
                        onChanged: (paquete) {
                          setState(() {
                            _paqueteSeleccionado = paquete;
                            _monto = paquete?.precio;
                            _servicioSeleccionado = null; // Limpiar selección de servicio
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Seleccione un paquete';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 16),
                    // Fecha
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Cita *',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_fechaSeleccionada),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Hora Inicio
                    InkWell(
                      onTap: _selectHoraInicio,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Hora Inicio *',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(_horaInicio.format(context)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Hora Fin
                    InkWell(
                      onTap: _selectHoraFin,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Hora Fin *',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(_horaFin.format(context)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Estado
                    DropdownButtonFormField<String>(
                      value: _estadoCita,
                      decoration: const InputDecoration(
                        labelText: 'Estado de Cita',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Pendiente', 'Confirmado', 'Completado', 'Cancelado']
                          .map((estado) {
                        return DropdownMenuItem(
                          value: estado,
                          child: Text(estado),
                        );
                      }).toList(),
                      onChanged: (estado) {
                        setState(() {
                          _estadoCita = estado!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Monto
                    TextFormField(
                      controller: TextEditingController(
                        text: _monto?.toStringAsFixed(2) ?? '',
                      )..selection = TextSelection.collapsed(offset: _monto?.toStringAsFixed(2).length ?? 0),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Monto',
                        border: const OutlineInputBorder(),
                        suffixIcon: (_servicioSeleccionado != null || _paqueteSeleccionado != null)
                            ? Tooltip(
                                message: 'Precio automático. Puede modificarlo si es necesario.',
                                child: Icon(Icons.info_outline, color: Colors.blue.shade700),
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        _monto = double.tryParse(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Observaciones
                    TextFormField(
                      initialValue: _observaciones,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _observaciones = value;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Botón Guardar
                    ElevatedButton(
                      onPressed: _isLoading ? null : _guardarAgendamiento,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD8B081),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Guardar Agendamiento',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
             )       ),
    );
  }
}

