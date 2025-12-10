import 'cliente.dart';
import 'barbero.dart';
import 'servicio.dart';
import 'paquete.dart';

class Agendamiento {
  final int? id;
  final int clienteId;
  final int barberoId;
  final int? servicioId;
  final int? paqueteId;
  final String fechaCita;
  final String horaInicio;
  final String horaFin;
  final String estadoCita;
  final double? monto;
  final String? observaciones;
  final bool? estado;
  final Cliente? cliente;
  final Barbero? barbero;
  final Servicio? servicio;
  final Paquete? paquete;

  Agendamiento({
    this.id,
    required this.clienteId,
    required this.barberoId,
    this.servicioId,
    this.paqueteId,
    required this.fechaCita,
    required this.horaInicio,
    required this.horaFin,
    this.estadoCita = 'Pendiente',
    this.monto,
    this.observaciones,
    this.estado,
    this.cliente,
    this.barbero,
    this.servicio,
    this.paquete,
  });

  factory Agendamiento.fromJson(Map<String, dynamic> json) {
    return Agendamiento(
      id: json['id'] ?? json['ID'],
      clienteId: json['clienteId'] ?? json['ClienteID'] ?? 0,
      barberoId: json['barberoId'] ?? json['BarberoID'] ?? 0,
      servicioId: json['servicioId'] ?? json['ServicioID'],
      paqueteId: json['paqueteId'] ?? json['PaqueteID'],
      fechaCita: json['fechaCita'] ?? json['FechaCita'] ?? '',
      horaInicio: json['horaInicio'] ?? json['HoraInicio'] ?? '',
      horaFin: json['horaFin'] ?? json['HoraFin'] ?? '',
      estadoCita: json['estadoCita'] ?? json['EstadoCita'] ?? 'Pendiente',
      monto: json['monto'] != null ? (json['monto'] ?? json['Monto']).toDouble() : null,
      observaciones: json['observaciones'] ?? json['Observaciones'],
      estado: json['estado'] ?? json['Estado'],
      cliente: json['cliente'] != null ? Cliente.fromJson(json['cliente']) : null,
      barbero: json['barbero'] != null ? Barbero.fromJson(json['barbero']) : null,
      servicio: json['servicio'] != null ? Servicio.fromJson(json['servicio']) : null,
      paquete: json['paquete'] != null ? Paquete.fromJson(json['paquete']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'clienteId': clienteId,
      'barberoId': barberoId,
      'servicioId': servicioId,
      'paqueteId': paqueteId,
      'fechaCita': fechaCita,
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'estadoCita': estadoCita,
      'monto': monto,
      'observaciones': observaciones,
      'estado': estado,
    };
    
    if (id != null && id != 0) {
      data['id'] = id;
    }
    
    return data;
  }

  Agendamiento copyWith({
    int? id,
    int? clienteId,
    int? barberoId,
    int? servicioId,
    int? paqueteId,
    String? fechaCita,
    String? horaInicio,
    String? horaFin,
    String? estadoCita,
    double? monto,
    String? observaciones,
    bool? estado,
    Cliente? cliente,
    Barbero? barbero,
    Servicio? servicio,
    Paquete? paquete,
  }) {
    return Agendamiento(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      barberoId: barberoId ?? this.barberoId,
      servicioId: servicioId ?? this.servicioId,
      paqueteId: paqueteId ?? this.paqueteId,
      fechaCita: fechaCita ?? this.fechaCita,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      estadoCita: estadoCita ?? this.estadoCita,
      monto: monto ?? this.monto,
      observaciones: observaciones ?? this.observaciones,
      estado: estado ?? this.estado,
      cliente: cliente ?? this.cliente,
      barbero: barbero ?? this.barbero,
      servicio: servicio ?? this.servicio,
      paquete: paquete ?? this.paquete,
    );
  }
}

