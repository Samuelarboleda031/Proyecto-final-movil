import 'cliente.dart';
import 'barbero.dart';
// Asegúrate de que los modelos Producto, Servicio y Paquete existan
// si los necesitas para la deserialización de objetos completos.
// import 'producto.dart';
// import 'servicio.dart';
// import 'paquete.dart'; 

// --- CLASE VENTA ---
class Venta {
  final int? id;
  final String numero;
  final String? fechaRegistro;
  final int clienteId;
  final int barberoId;
  final String metodoPago;
  final double subtotal;
  final double porcentajeDescuento;
  final double total;
  final bool? estado;
  final Cliente? cliente;
  final Barbero? barbero;
  final List<DetalleVenta>? detalles;

  Venta({
    this.id,
    required this.numero,
    this.fechaRegistro,
    required this.clienteId,
    required this.barberoId,
    required this.metodoPago,
    required this.subtotal,
    required this.porcentajeDescuento,
    required this.total,
    this.estado,
    this.cliente,
    this.barbero,
    this.detalles,
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    // Buscar la lista de detalles bajo las claves posibles
    final List<dynamic>? detallesList = 
        json['detalles'] ?? json['detalleVenta'] ?? json['DetalleVenta'];

    return Venta(
      id: json['id'] ?? json['ID'],
      numero: json['numero'] ?? json['Numero'] ?? '',
      fechaRegistro: json['fechaRegistro'] ?? json['FechaRegistro'],
      clienteId: json['clienteId'] ?? json['ClienteID'] ?? 0,
      barberoId: json['barberoId'] ?? json['BarberoID'] ?? 0,
      metodoPago: json['metodoPago'] ?? json['MetodoPago'] ?? '',
      // Convertir a double con seguridad
      subtotal: (json['subtotal'] ?? json['Subtotal'] ?? 0).toDouble(),
      porcentajeDescuento: (json['porcentajeDescuento'] ?? json['PorcentajeDescuento'] ?? 0).toDouble(),
      total: (json['total'] ?? json['Total'] ?? 0).toDouble(),
      estado: json['estado'] ?? json['Estado'],
      // Asume que Cliente.fromJson y Barbero.fromJson existen
      cliente: json['cliente'] != null ? Cliente.fromJson(json['cliente']) : null,
      barbero: json['barbero'] != null ? Barbero.fromJson(json['barbero']) : null,
      
      detalles: detallesList != null 
          ? detallesList.map((d) => DetalleVenta.fromJson(d)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'numero': numero,
      'fechaRegistro': fechaRegistro,
      'clienteId': clienteId,
      'barberoId': barberoId,
      'metodoPago': metodoPago,
      'subtotal': subtotal,
      'porcentajeDescuento': porcentajeDescuento,
      'total': total,
      'estado': estado ?? true, 
      // *** CORRECCIÓN CLAVE para el API: Usar 'detalleVenta' ***
      'detalleVenta': detalles?.map((d) => d.toJson()).toList() ?? [], 
    };
    
    if (id != null && id != 0) {
      data['id'] = id;
    }
    
    return data;
  }
}

// ------------------------------------------------------------------
// --- CLASE DETALLEVENTA ---
class DetalleVenta {
  final int? id;
  final int ventaId;
  final int? productoId;
  final int? servicioId;
  final int? paqueteId;
  final int cantidad;
  final double precioUnitario;
  final double? subTotal; // Usando 'subTotal' con 'S' mayúscula según el ejemplo de API

  DetalleVenta({
    this.id,
    required this.ventaId,
    this.productoId,
    this.servicioId,
    this.paqueteId,
    required this.cantidad,
    required this.precioUnitario,
    this.subTotal,
  });

  factory DetalleVenta.fromJson(Map<String, dynamic> json) {
    return DetalleVenta(
      id: json['id'] ?? json['ID'],
      ventaId: json['ventaId'] ?? json['VentaID'] ?? 0,
      productoId: json['productoId'] ?? json['ProductoID'],
      servicioId: json['servicioId'] ?? json['ServicioID'],
      paqueteId: json['paqueteId'] ?? json['PaqueteID'],
      cantidad: json['cantidad'] ?? json['Cantidad'] ?? 0,
      precioUnitario: (json['precioUnitario'] ?? json['PrecioUnitario'] ?? 0).toDouble(),
      subTotal: json['subTotal'] != null ? (json['subTotal'] ?? json['SubTotal']).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'productoId': productoId,
      'servicioId': servicioId,
      'paqueteId': paqueteId,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
      'subTotal': subTotal, // Usando 'subTotal' para coincidir con la API
    };

    if (id != null && id != 0) {
      data['id'] = id;
    }
    if (ventaId != 0) {
      data['ventaId'] = ventaId;
    }

    return data;
  }
}