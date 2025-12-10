import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/cliente.dart';
import '../models/barbero.dart';
import '../models/servicio.dart';
import '../models/paquete.dart';
import '../models/producto.dart';
import '../services/auth_service.dart';

class AuxiliarService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Clientes
  Future<List<Cliente>> obtenerClientes() async {
    try {
      final headers = await _getHeaders();
      final url = '${ApiConfig.baseUrl}${ApiConfig.clientes}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado. Verifique su conexión a internet.');
        },
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return [];
        }
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Cliente.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener clientes: ${response.statusCode} - ${response.body}');
      }
    } on FormatException catch (e) {
      throw Exception('Error al procesar la respuesta de la API: $e');
    } catch (e) {
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('Failed to connect') ||
          e.toString().contains('Failed to fetch')) {
        throw Exception('No se pudo conectar con el servidor. Verifique su conexión a internet y que la API esté disponible.');
      }
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Cliente> crearCliente(Cliente cliente) async {
    try {
      final headers = await _getHeaders();
      final url = '${ApiConfig.baseUrl}${ApiConfig.clientes}';

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(cliente.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Cliente.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al crear cliente: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión al crear cliente: $e');
    }
  }

  Future<Cliente> actualizarCliente(Cliente cliente) async {
    if (cliente.id == null || cliente.id == 0) {
      throw Exception('No se puede actualizar un cliente sin ID');
    }

    try {
      final headers = await _getHeaders();
      final url = '${ApiConfig.baseUrl}${ApiConfig.clientes}/${cliente.id}';

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(cliente.toJson()),
      );

      if (response.statusCode == 200) {
        return Cliente.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 204) {
        return cliente;
      } else {
        throw Exception('Error al actualizar cliente: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión al actualizar cliente: $e');
    }
  }

  // Barberos
  Future<List<Barbero>> obtenerBarberos() async {
    try {
      final headers = await _getHeaders();
      final url = '${ApiConfig.baseUrl}${ApiConfig.barberos}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado. Verifique su conexión a internet.');
        },
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return [];
        }
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Barbero.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener barberos: ${response.statusCode} - ${response.body}');
      }
    } on FormatException catch (e) {
      throw Exception('Error al procesar la respuesta de la API: $e');
    } catch (e) {
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('Failed to connect') ||
          e.toString().contains('Failed to fetch')) {
        throw Exception('No se pudo conectar con el servidor. Verifique su conexión a internet y que la API esté disponible.');
      }
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Barbero> crearBarbero(Barbero barbero) async {
    try {
      final headers = await _getHeaders();
      final url = '${ApiConfig.baseUrl}${ApiConfig.barberos}';

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(barbero.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Barbero.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al crear barbero: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión al crear barbero: $e');
    }
  }

  Future<Barbero> actualizarBarbero(Barbero barbero) async {
    if (barbero.id == null || barbero.id == 0) {
      throw Exception('No se puede actualizar un barbero sin ID');
    }

    try {
      final headers = await _getHeaders();
      final url = '${ApiConfig.baseUrl}${ApiConfig.barberos}/${barbero.id}';

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(barbero.toJson()),
      );

      if (response.statusCode == 200) {
        return Barbero.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 204) {
        return barbero;
      } else {
        throw Exception('Error al actualizar barbero: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión al actualizar barbero: $e');
    }
  }

  // Servicios
  Future<List<Servicio>> obtenerServicios() async {
    try {
      final headers = await _getHeaders();
      final url = '${ApiConfig.baseUrl}${ApiConfig.servicios}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado. Verifique su conexión a internet.');
        },
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return [];
        }
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Servicio.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener servicios: ${response.statusCode} - ${response.body}');
      }
    } on FormatException catch (e) {
      throw Exception('Error al procesar la respuesta de la API: $e');
    } catch (e) {
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('Failed to connect') ||
          e.toString().contains('Failed to fetch')) {
        throw Exception('No se pudo conectar con el servidor. Verifique su conexión a internet y que la API esté disponible.');
      }
      throw Exception('Error de conexión: $e');
    }
  }

  // Paquetes
  Future<List<Paquete>> obtenerPaquetes() async {
    try {
      final headers = await _getHeaders();
      final url = '${ApiConfig.baseUrl}${ApiConfig.paquetes}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado. Verifique su conexión a internet.');
        },
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return [];
        }
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Paquete.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener paquetes: ${response.statusCode} - ${response.body}');
      }
    } on FormatException catch (e) {
      throw Exception('Error al procesar la respuesta de la API: $e');
    } catch (e) {
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('Failed to connect') ||
          e.toString().contains('Failed to fetch')) {
        throw Exception('No se pudo conectar con el servidor. Verifique su conexión a internet y que la API esté disponible.');
      }
      throw Exception('Error de conexión: $e');
    }
  }

  // Productos
  Future<List<Producto>> obtenerProductos() async {
    try {
      final headers = await _getHeaders();
      final url = '${ApiConfig.baseUrl}${ApiConfig.productos}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado. Verifique su conexión a internet.');
        },
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return [];
        }
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Producto.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener productos: ${response.statusCode} - ${response.body}');
      }
    } on FormatException catch (e) {
      throw Exception('Error al procesar la respuesta de la API: $e');
    } catch (e) {
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('Failed to connect') ||
          e.toString().contains('Failed to fetch')) {
        throw Exception('No se pudo conectar con el servidor. Verifique su conexión a internet y que la API esté disponible.');
      }
      throw Exception('Error de conexión: $e');
    }
  }
}

