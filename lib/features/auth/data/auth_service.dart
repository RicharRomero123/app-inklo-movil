import 'package:auth0_flutter/auth0_flutter.dart';
import '../../../core/constants/app_constants.dart';

class AuthService {
  final Auth0 _auth0 = Auth0(AppConstants.auth0Domain, AppConstants.auth0ClientId);

  Future<String?> loginSocial(String connection) async {
    try {
      final credentials = await _auth0.webAuthentication(scheme: AppConstants.auth0Scheme).login(
        audience: AppConstants.auth0Audience,
        scopes: {'openid', 'profile', 'email', 'offline_access'},
        parameters: {'connection': connection},
      );
      return credentials.accessToken;
    } catch (e) {
      throw Exception('Error en login social: $e');
    }
  }

  Future<String?> loginWithEmail(String email, String password) async {
    try {
      final credentials = await _auth0.api.login(
        usernameOrEmail: email,
        password: password,
        connectionOrRealm: 'Username-Password-Authentication',
        audience: AppConstants.auth0Audience, // Tu API de Inklop
        scopes: {'openid', 'profile', 'email', 'offline_access'},
      );
      return credentials.accessToken;
    } catch (e) {
      // 🔥 AQUÍ ESTABA EL PROBLEMA: Estábamos ocultando el error real
      // Ahora sí imprimirá exactamente de qué se queja Auth0
      throw Exception('Error real de Auth0 al hacer login: $e');
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await _auth0.api.signup(email: email, password: password, connection: 'Username-Password-Authentication');
    } catch (e) {
      throw Exception('Error al registrar: $e');
    }
  }
}