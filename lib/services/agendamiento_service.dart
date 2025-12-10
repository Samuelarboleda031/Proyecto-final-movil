import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/agendamiento.dart';
import '../services/auth_service.dart';

class AgendamientoService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Agendamiento>> obtenerAgendamientos() async {
    try {
      final headers = await _getHeaders();
      final url = '${ApiConfig.baseUrl}${ApiConfig.agendamientos}';
      
      print('🔍 [AgendamientoService] Intentando conectar a: $url');
      print('📋 [AgendamientoService] Headers: $headers');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ [AgendamientoService] Tiempo de espera agotado');
          throw Exception('Tiempo de espera agotado. Verifique su conexión a internet.');
        },
      );

      print('📥 [AgendamientoService] Status Code: ${response.statusCode}');
      print('📄 [AgendamientoService] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          print('ℹ️ [AgendamientoService] La respuesta está vacía');
          return [];
        }
        
        try {
          // Decodificar la respuesta JSON
          final dynamic responseData = jsonDecode(response.body);
          print('🔍 [AgendamientoService] Tipo de respuesta: ${responseData.runtimeType}');
          
          // Verificar si la respuesta es una lista o un objeto con una propiedad data
          if (responseData is List) {
            print('✅ [AgendamientoService] Respuesta es una lista de ${responseData.length} elementos');
            if (responseData.isNotEmpty) {
              print('📝 [AgendamientoService] Primer elemento: ${responseData[0]}');
            }
            return responseData.map<Agendamiento>((json) {
              try {
                return Agendamiento.fromJson(json);
              } catch (e) {
                print('❌ [AgendamientoService] Error al mapear cita: $e');
                print('📝 JSON problemático: $json');
                rethrow;
              }
            }).toList();
          } else if (responseData is Map && responseData.containsKey('data')) {
            print('ℹ️ [AgendamientoService] Respuesta contiene propiedad "data"');
            final data = responseData['data'] as List;
            print('✅ [AgendamientoService] ${data.length} citas encontradas en la propiedad data');
            return data.map<Agendamiento>((json) => Agendamiento.fromJson(json)).toList();
          } else {
            print('❌ [AgendamientoService] Formato de respuesta inesperado');
            print('📝 Respuesta completa: $responseData');
            throw Exception('Formato de respuesta inesperado de la API');
          }
        } catch (e) {
          print('❌ [AgendamientoService] Error al procesar la respuesta: $e');
          rethrow;
        }
      } else {
        throw Exception('Error HTTP ${response.statusCode}: ${response.body.length > 100 ? response.body.substring(0, 100) : response.body}');
      }
    } on FormatException catch (e) {
      print('❌ Error de formato JSON: $e');
      throw Exception('Error al procesar la respuesta de la API (formato JSON inválido): $e');
    } on http.ClientException catch (e) {
      print('❌ Error de cliente HTTP: $e');
      String errorMessage = 'Error de conexión HTTP: $e';
      
      // Detectar error de CORS
      if (e.toString().contains('Failed to fetch') || 
          e.toString().contains('CORS') ||
          e.toString().contains('Access-Control-Allow-Origin')) {
        errorMessage = 'Error de CORS: El servidor no permite peticiones desde el navegador. '
            'Solución: Ejecuta la app en un dispositivo móvil o usa Chrome con CORS deshabilitado para desarrollo. '
            'Ver CORS_SOLUTION.md para más detalles.';
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      print('❌ Error general: $e');
      print('❌ Tipo de error: ${e.runtimeType}');
      
      String errorMessage = 'Error: $e';
      
      // Detectar error de CORS
      if (e.toString().contains('Failed to fetch') || 
          e.toString().contains('CORS') ||
          e.toString().contains('Access-Control-Allow-Origin')) {
        errorMessage = 'Error de CORS: El servidor no permite peticiones desde el navegador. '
            'Solución: Ejecuta la app en un dispositivo móvil o usa Chrome con CORS deshabilitado para desarrollo. '
            'Ver CORS_SOLUTION.md para más detalles.';
      }
      
      throw Exception(errorMessage);
    }
  }

  Future<Agendamiento> obtenerAgendamientoPorId(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.agendamientos}/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Agendamiento.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al obtener agendamiento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Agendamiento> crearAgendamiento(Agendamiento agendamiento) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.agendamientos}'),
        headers: headers,
        body: jsonEncode(agendamiento.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Agendamiento.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al crear agendamiento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Agendamiento> actualizarAgendamiento(Agendamiento agendamiento) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.agendamientos}/${agendamiento.id}'),
        headers: headers,
        body: jsonEncode(agendamiento.toJson()),
      );

      if (response.statusCode == 200) {
        return Agendamiento.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 204) {
        return agendamiento;
      } else {
        throw Exception('Error al actualizar agendamiento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> eliminarAgendamiento(int id) async {
    try {
      final headers = await _getHeaders();
      
      // Log the deletion for debugging
      print('Eliminando agendamiento $id');
      
      // Send DELETE request to the server
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.agendamientos}/$id'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar el agendamiento: ${response.statusCode}');
      }
      
      print('Agendamiento $id eliminado exitosamente');
      
    } catch (e) {
      print('Error en eliminarAgendamiento: $e');
      throw Exception('Error al eliminar agendamiento: $e');
    }
  }

  Future<List<Agendamiento>> obtenerAgendamientosPorCliente(int clienteId) async {
    try {
      final headers = await _getHeaders();
      // Use query parameters instead of path parameters
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.agendamientos}')
          .replace(queryParameters: {
            'clienteId': clienteId.toString(),
          });
      
      print('🔍 [AgendamientoService] Obteniendo citas para el cliente: $clienteId');
      print('🔗 URL: $url');
      
      final response = await http.get(
        url,
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado. Verifique su conexión a internet.');
        },
      );

      print('📥 [AgendamientoService] Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          print('ℹ️ [AgendamientoService] El cliente no tiene citas agendadas');
          return [];
        }
        
        try {
          final dynamic responseData = jsonDecode(response.body);
          
          if (responseData is List) {
            print('✅ [AgendamientoService] Se encontraron ${responseData.length} citas para el cliente');
            return responseData.map<Agendamiento>((json) => Agendamiento.fromJson(json)).toList();
          } else if (responseData is Map && responseData.containsKey('data')) {
            final data = responseData['data'] as List;
            print('✅ [AgendamientoService] Se encontraron ${data.length} citas para el cliente en la propiedad data');
            return data.map<Agendamiento>((json) => Agendamiento.fromJson(json)).toList();
          } else {
            // If we get here, the API returned a 200 but with an unexpected format
            // Let's try to get all appointments and filter client-side as a fallback
            print('⚠️ [AgendamientoService] Formato de respuesta inesperado, intentando filtrado local...');
            final allAppointments = await obtenerAgendamientos();
            final clientAppointments = allAppointments
                .where((appointment) => appointment.clienteId == clienteId)
                .toList();
            print('✅ [AgendamientoService] Se encontraron ${clientAppointments.length} citas para el cliente (filtrado local)');
            return clientAppointments;
          }
        } catch (e) {
          print('❌ [AgendamientoService] Error al procesar la respuesta: $e');
          rethrow;
        }
      } else {
        // If we get a 404 or other error, try to get all appointments and filter client-side
        print('⚠️ [AgendamientoService] Error ${response.statusCode} al obtener citas, intentando filtrado local...');
        try {
          final allAppointments = await obtenerAgendamientos();
          final clientAppointments = allAppointments
              .where((appointment) => appointment.clienteId == clienteId)
              .toList();
          print('✅ [AgendamientoService] Se encontraron ${clientAppointments.length} citas para el cliente (filtrado local)');
          return clientAppointments;
        } catch (e) {
          print('❌ [AgendamientoService] Error en el filtrado local: $e');
          throw Exception('No se pudieron cargar las citas. Por favor, intente nuevamente.');
        }
      }
    } on FormatException catch (e) {
      print('❌ Error de formato JSON: $e');
      throw Exception('Error al procesar la respuesta de la API (formato JSON inválido): $e');
    } catch (e) {
      print('❌ Error al obtener citas del cliente: $e');
      rethrow;
    }
  }
}

