import 'package:flutter/material.dart';
import 'package:inklop_v1/features/auth/presentation/screens/email_auth_screen.dart';
import '../../data/auth_service.dart';
import '../../data/user_api_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../widgets/social_button.dart';
import 'birth_date_screen.dart';
import '../../../main/presentation/main_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // Instanciamos todos los servicios que necesitamos
  final AuthService _authService = AuthService();
  final UserApiService _userApiService = UserApiService();
  final SecureStorageService _storageService = SecureStorageService();

  // Esta variable controlará si mostramos los botones o el circulito de carga
  bool _isLoading = false;

  Future<void> _handleSocialAuth(String connection) async {
    // 1. Ocultamos los botones y mostramos "Cargando..."
    setState(() => _isLoading = true);

    try {
      // 2. Auth0 abre el navegador y nos devuelve el Token
      final token = await _authService.loginSocial(connection);

      if (token != null && mounted) {
        print('✅ Token de Auth0 obtenido. Consultando al backend...');

        // 3. 🚦 AQUÍ SUCEDE LA MAGIA: Consultamos tu API apenas tenemos el token
        final isCompleted = await _userApiService.isProfileCompleted(token);

        if (isCompleted) {
          // 🟢 EL USUARIO YA EXISTE: Guardamos el token en memoria y vamos al Home
          print('🚀 Usuario antiguo detectado. Redirigiendo al MainScreen...');
          await _storageService.saveToken(token);

          if (mounted) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainScreen()),
                    (route) => false // Esto borra el historial para que no pueda regresar al Login
            );
          }
        } else {
          // 🔴 ES UN USUARIO NUEVO: Lo mandamos a ingresar su fecha
          print('📝 Usuario nuevo detectado. Redirigiendo al registro...');
          if (mounted) {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BirthDateScreen(accessToken: token))
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      // 4. Si hubo un error o el usuario canceló, volvemos a mostrar los botones
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text('Bienvenido a Inklop', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              const Text('Monetiza tu creatividad hoy mismo', style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),

              const Spacer(),

              // Si está cargando, mostramos el indicador. Si no, mostramos los botones.
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: Colors.black))
              else ...[
                SocialButton(
                  iconPath: 'assets/images/google_icon.png', // Asegúrate de tener tu imagen en esta ruta
                  label: 'Continuar con Google',
                  onTap: () => _handleSocialAuth('google-oauth2'),
                ),
                const SizedBox(height: 16),

                SocialButton(
                  iconPath: 'assets/images/apple_icon.png', // Asegúrate de tener tu imagen en esta ruta
                  label: 'Continuar con Apple',
                  onTap: () => _handleSocialAuth('apple'),
                ),
                const SizedBox(height: 24),

                FilledButton(
                  onPressed: () {
                    // 👇 Aquí hacemos la navegación a tu nueva pantalla 👇
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EmailAuthScreen())
                    );
                  },
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                  child: const Text('Continuar con Correo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                )
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}