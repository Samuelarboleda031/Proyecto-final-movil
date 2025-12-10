import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/agendamiento.dart';
import '../models/barbero.dart';
import '../models/cliente.dart';
import '../models/paquete.dart';
import '../models/servicio.dart';
import '../models/app_role.dart';
import '../services/agendamiento_service.dart';
import '../services/auxiliar_service.dart';
import '../services/user_context_service.dart';
import '../widgets/session_guard.dart';

class BarberAgendamientoFormScreen extends StatefulWidget {
  final Agendamiento? agendamiento;

  const BarberAgendamientoFormScreen({super.key, this.agendamiento});

  @override
  State<BarberAgendamientoFormScreen> createState() =>
      _BarberAgendamientoFormScreenState();
}

class _BarberAgendamientoFormScreenState
    extends State<BarberAgendamientoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AgendamientoService _agendamientoService = AgendamientoService();
  final AuxiliarService _auxiliarService = AuxiliarService();
  final UserContextService _userContextService = UserContextService();

  List<Cliente> _clientes = [];
  List<Servicio> _servicios = [];
  List<Paquete> _paquetes = [];

  Cliente? _clienteSeleccionado;
  Servicio? _servicioSeleccionado;
  Paquete? _paqueteSeleccionado;
  Barbero? _barberoActual;

  DateTime _fechaSeleccionada = DateTime.now();
  TimeOfDay _horaInicio = TimeOfDay.now();
  TimeOfDay _horaFin = TimeOfDay.now();
  String _estadoCita = 'Pendiente';
  double? _monto;
  String? _observaciones;
  bool _esServicio = true;

  bool _isLoading = false;
  bool _isLoadingData = true;
  String? _barberoError;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      setState(() {
        _isLoadingData = true;
      });

      final clientes = await _auxiliarService.obtenerClientes();
      final servicios = await _auxiliarService.obtenerServicios();
      final paquetes = await _auxiliarService.obtenerPaquetes();
      final barbero = await _userContextService.obtenerBarberoActual();

      if (!mounted) return;

      if (barbero == null || barbero.id == null) {
        setState(() {
          _barberoError =
              'No se encontró un perfil de barbero asociado a tu cuenta. Contacta al administrador.';
          _isLoadingData = false;
        });
        return;
      }

      setState(() {
        _clientes = clientes;
        _servicios = servicios;
        _paquetes = paquetes;
        _barberoActual = barbero;
        _isLoadingData = false;
      });

      if (widget.agendamiento != null) {
        _cargarDatosAgendamiento(widget.agendamiento!);
      }
    } catch (e) {
      setState(() {
        _isLoadingData = false;
        _barberoError = 'Error al cargar los datos: $e\n\nIntenta nuevamente.';
      });
      print('Error detail: $e'); // Keep log for developers
    }
  }

  void _cargarDatosAgendamiento(Agendamiento agendamiento) {
    Cliente? clienteSeleccionado;
    try {
      clienteSeleccionado =
          _clientes.firstWhere((c) => c.id == agendamiento.clienteId);
    } catch (_) {
      clienteSeleccionado = agendamiento.cliente ??
          Cliente(
            id: agendamiento.clienteId,
            documento: '0',
            nombre: 'Cliente',
            apellido: 'Temporal',
          );
    }

    Servicio? servicioSeleccionado;
    Paquete? paqueteSeleccionado;
    bool esServicio = _esServicio;

    if (agendamiento.servicioId != null) {
      try {
        servicioSeleccionado =
            _servicios.firstWhere((s) => s.id == agendamiento.servicioId);
      } catch (_) {
        servicioSeleccionado = agendamiento.servicio ??
            Servicio(
              id: agendamiento.servicioId,
              nombre: 'Servicio',
              precio: 0,
              duracionMinutos: 30,
            );
      }
      esServicio = true;
    } else if (agendamiento.paqueteId != null) {
      try {
        paqueteSeleccionado =
            _paquetes.firstWhere((p) => p.id == agendamiento.paqueteId);
      } catch (_) {
        paqueteSeleccionado = agendamiento.paquete ??
            Paquete(
              id: agendamiento.paqueteId,
              nombre: 'Paquete',
              precio: 0,
              duracionMinutos: 30,
            );
      }
      esServicio = false;
    }

    final fecha = DateTime.parse(agendamiento.fechaCita);
    final inicioParts = agendamiento.horaInicio.split(':');
    final finParts = agendamiento.horaFin.split(':');

    setState(() {
      if (!_clientes.any((c) => c.id == clienteSeleccionado!.id)) {
        _clientes = [..._clientes, clienteSeleccionado!];
      }
      if (servicioSeleccionado != null &&
          !_servicios.any((s) => s.id == servicioSeleccionado!.id)) {
        _servicios = [..._servicios, servicioSeleccionado];
      }
      if (paqueteSeleccionado != null &&
          !_paquetes.any((p) => p.id == paqueteSeleccionado!.id)) {
        _paquetes = [..._paquetes, paqueteSeleccionado];
      }

      _clienteSeleccionado = clienteSeleccionado;
      _servicioSeleccionado = servicioSeleccionado;
      _paqueteSeleccionado = paqueteSeleccionado;
      _esServicio = esServicio;
      _fechaSeleccionada = fecha;
      _horaInicio = TimeOfDay(
        hour: int.parse(inicioParts[0]),
        minute: int.parse(inicioParts[1]),
      );
      _horaFin = TimeOfDay(
        hour: int.parse(finParts[0]),
        minute: int.parse(finParts[1]),
      );
      _estadoCita = agendamiento.estadoCita;
      _monto = agendamiento.monto;
      _observaciones = agendamiento.observaciones;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
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
    if (picked != null) {
      setState(() {
        _horaInicio = picked;
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
    if (picked != null) {
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

  void _calcularMonto() {
    if (_esServicio && _servicioSeleccionado != null) {
      setState(() {
        _monto = _servicioSeleccionado!.precio;
      });
    } else if (!_esServicio && _paqueteSeleccionado != null) {
      setState(() {
        _monto = _paqueteSeleccionado!.precio;
      });
    } else {
      setState(() {
        _monto = null;
      });
    }
  }

  Future<void> _guardarAgendamiento() async {
    if (!_formKey.currentState!.validate()) return;

    if (_barberoActual == null || _barberoActual!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar tu perfil de barbero'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione un cliente'),
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
      final fecha = DateFormat('yyyy-MM-dd').format(_fechaSeleccionada);
      final horaInicio =
          '${_horaInicio.hour.toString().padLeft(2, '0')}:${_horaInicio.minute.toString().padLeft(2, '0')}';
      final horaFin =
          '${_horaFin.hour.toString().padLeft(2, '0')}:${_horaFin.minute.toString().padLeft(2, '0')}';

      final agendamiento = Agendamiento(
        id: widget.agendamiento?.id,
        clienteId: _clienteSeleccionado!.id!,
        barberoId: _barberoActual!.id!,
        servicioId: _esServicio ? _servicioSeleccionado?.id : null,
        paqueteId: !_esServicio ? _paqueteSeleccionado?.id : null,
        fechaCita: fecha,
        horaInicio: horaInicio,
        horaFin: horaFin,
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
                ? 'Cita creada exitosamente'
                : 'Cita actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la cita: $e'),
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

  Widget _buildPickerField({
    required String label,
    required String value,
    required VoidCallback onTap,
    IconData icon = Icons.calendar_today,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(icon, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatItemLabel(String nombre, double precio) {
    return '$nombre - \$${precio.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return SessionGuard(
      requiredRole: AppRole.barber,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.agendamiento == null ? 'Nueva Cita' : 'Editar Cita'),
        ),
        body: _isLoadingData
            ? const Center(child: CircularProgressIndicator())
            : _barberoError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                          const SizedBox(height: 16),
                          Text(
                            _barberoError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _cargarDatos,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Barbero',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.content_cut),
                              helperText: 'La cita se registrará con tu cuenta actual',
                            ),
                            child: Text(
                              _barberoActual?.nombreCompleto ?? 'Perfil no disponible',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16),

                          DropdownButtonFormField<Cliente>(
                            value: _clienteSeleccionado,
                            decoration: const InputDecoration(
                              labelText: 'Cliente *',
                              border: OutlineInputBorder(),
                            ),
                            items: _clientes.map((cliente) {
                              return DropdownMenuItem<Cliente>(
                                value: cliente,
                                child: Text(cliente.nombreCompleto),
                              );
                            }).toList(),
                            onChanged: (cliente) {
                              setState(() {
                                _clienteSeleccionado = cliente;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Seleccione un cliente' : null,
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'Tipo de Cita',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<bool>(
                                  title: const Text('Servicio'),
                                  value: true,
                                  groupValue: _esServicio,
                                  onChanged: (value) {
                                    setState(() {
                                      _esServicio = value ?? true;
                                      _servicioSeleccionado = null;
                                      _paqueteSeleccionado = null;
                                      _calcularMonto();
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<bool>(
                                  title: const Text('Paquete'),
                                  value: false,
                                  groupValue: _esServicio,
                                  onChanged: (value) {
                                    setState(() {
                                      _esServicio = value ?? false;
                                      _servicioSeleccionado = null;
                                      _paqueteSeleccionado = null;
                                      _calcularMonto();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _esServicio
                              ? DropdownButtonFormField<Servicio>(
                                  value: _servicioSeleccionado,
                                  decoration: const InputDecoration(
                                    labelText: 'Servicio',
                                    border: OutlineInputBorder(),
                                  ),
                                  isExpanded: true,
                                  items: _servicios.map((servicio) {
                                    return DropdownMenuItem<Servicio>(
                                      value: servicio,
                                      child: Text(
                                        _formatItemLabel(
                                            servicio.nombre, servicio.precio),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _servicioSeleccionado = value;
                                      _paqueteSeleccionado = null;
                                      _calcularMonto();
                                    });
                                  },
                                  validator: (value) => value == null
                                      ? 'Por favor seleccione un servicio'
                                      : null,
                                )
                              : DropdownButtonFormField<Paquete>(
                                  value: _paqueteSeleccionado,
                                  decoration: const InputDecoration(
                                    labelText: 'Paquete',
                                    border: OutlineInputBorder(),
                                  ),
                                  isExpanded: true,
                                  items: _paquetes.map((paquete) {
                                    return DropdownMenuItem<Paquete>(
                                      value: paquete,
                                      child: Text(
                                        _formatItemLabel(
                                            paquete.nombre, paquete.precio),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _paqueteSeleccionado = value;
                                      _servicioSeleccionado = null;
                                      _calcularMonto();
                                    });
                                  },
                                  validator: (value) => value == null
                                      ? 'Por favor seleccione un paquete'
                                      : null,
                                ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: _buildPickerField(
                                  label: 'Fecha de la cita',
                                  value: DateFormat('dd/MM/yyyy')
                                      .format(_fechaSeleccionada),
                                  onTap: _selectDate,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildPickerField(
                                  label: 'Hora de inicio',
                                  value: _horaInicio.format(context),
                                  onTap: _selectHoraInicio,
                                  icon: Icons.access_time,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: _buildPickerField(
                                  label: 'Hora de fin',
                                  value: _horaFin.format(context),
                                  onTap: _selectHoraFin,
                                  icon: Icons.access_time,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Monto',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.attach_money),
                                  ),
                                  controller: TextEditingController(
                                    text: _monto != null
                                        ? '\$${_monto!.toStringAsFixed(2)}'
                                        : '',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            value: _estadoCita,
                            decoration: const InputDecoration(
                              labelText: 'Estado de la cita',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              'Pendiente',
                              'Confirmada',
                              'En curso',
                              'Completada',
                              'Cancelada',
                            ].map((estado) {
                              return DropdownMenuItem(
                                value: estado,
                                child: Text(estado),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _estadoCita = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            initialValue: _observaciones,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Observaciones',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) => _observaciones =
                                value.trim().isEmpty ? null : value.trim(),
                          ),
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed:
                                      _isLoading ? null : () => Navigator.pop(context),
                                  child: const Text('Cancelar'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ||
                                          _barberoError != null ||
                                          _isLoadingData
                                      ? null
                                      : _guardarAgendamiento,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Text(widget.agendamiento == null
                                          ? 'Crear Cita'
                                          : 'Actualizar Cita'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}


