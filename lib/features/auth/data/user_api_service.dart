import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';

class UserApiService {

  // --- 1. CONSULTAR USERNAME (GET) ---
  Future<Map<String, dynamic>> checkUsername(String username, String token) async {
    try {
      // 🚨 IMPRESIÓN DEL TOKEN PARA PROBAR EN SWAGGER 🚨
      print('\n======================================================');
      print('🔑 BEARER TOKEN OBTENIDO (Cópialo para usar en Swagger):');
      print(token);
      print('======================================================\n');

      final url = Uri.parse('${AppConstants.apiBaseUrl}/users/username/$username');

      final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          }
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 Respuesta API Username ($username): $data');
        return data;
      }

      print('❌ Error API Username. Status: ${response.statusCode}');
      return {'valid': false, 'exists': false};
    } catch (e) {
      print('❌ Error de red al consultar Username: $e');
      return {'valid': false, 'exists': false};
    }
  }

  // --- 2. ENVIAR DATOS DEL PERFIL (POST) ---
  Future<bool> registerExtraData(Map<String, dynamic> payload, String token) async {
    try {
      final url = Uri.parse('${AppConstants.apiBaseUrl}/users/register_extra_data');

      print('\n🚀 Enviando POST de registro a: $url');
      print('📦 Payload a enviar: ${jsonEncode(payload)}'); // jsonEncode para verlo formato Swagger

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      print('📥 Respuesta POST (Status ${response.statusCode}): ${response.body}\n');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Error de red en POST register_extra_data: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // --- 3. VERIFICAR SI EL PERFIL YA ESTÁ COMPLETO (GET) ---
  Future<bool> isProfileCompleted(String token) async {
    try {
      final url = Uri.parse('${AppConstants.apiBaseUrl}/users');

      print('🔍 Verificando si el usuario ya existe en: $url');

      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final isCompleted = data['profileCompleted'] == true;

        print('✅ Usuario encontrado en BD: ${data['username'] ?? 'Sin username'}');
        print('🚦 ¿Perfil completado?: $isCompleted');

        return isCompleted;
      }

      // Si el servidor responde 404, 500 u otro error
      print('⚠️ El usuario aún no existe en BD o hubo error (Status: ${response.statusCode})');
      return false;

    } catch (e) {
      print('❌ Error de red al verificar perfil: $e');
      return false; // Ante la duda o error de red, asumimos que no está completo
    }
  }
}