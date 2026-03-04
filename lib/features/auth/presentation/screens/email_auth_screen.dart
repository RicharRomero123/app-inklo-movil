import 'package:flutter/material.dart';
import 'package:inklop_v1/core/utils/custom_input.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../data/auth_service.dart';
import '../../data/user_api_service.dart';
import 'birth_date_screen.dart';
import '../../../main/presentation/main_screen.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final AuthService _authService = AuthService();
  final UserApiService _userApiService = UserApiService();
  final SecureStorageService _storageService = SecureStorageService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  // Separamos el diálogo en una función para mantener el código ordenado
  void _showVerificationDialog() {
    if (!mounted) return;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('¡Revisa tu correo! 📩', textAlign: TextAlign.center),
          content: const Text(
            'Como eres un usuario nuevo, te enviamos un enlace de verificación. Ábrelo desde tu celular o computadora. Cuando lo hayas hecho, presiona el botón de abajo.',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context); // Cierra el diálogo
                  _submit(); // Intenta iniciar sesión automáticamente de nuevo
                },
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: const Text('Ya verifiqué mi correo', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _passwordController.clear()); // Limpia la contraseña
              },
              child: const Text('Lo haré más tarde', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            )
          ],
        )
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, ingresa un correo válido'), backgroundColor: Colors.orange));
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, ingresa tu contraseña'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? token;

      try {
        // --- INTENTO 1: LOGIN DIRECTO ---
        print('🔐 Intentando iniciar sesión...');
        token = await _authService.loginWithEmail(email, password);

      } catch (loginError) {
        // --- INTENTO 2: SI FALLA, INTENTAMOS REGISTRAR ---
        print('⚠️ Login falló. Intentando registrar como cuenta nueva...');
        try {
          await _authService.signUpWithEmail(email, password);
          print('✅ Registro exitoso. Pidiendo verificación...');

          setState(() => _isLoading = false);
          _showVerificationDialog();
          return; // Detenemos aquí hasta que el usuario verifique

        } catch (signUpError) {
          // Si el registro también falla, analizamos por qué
          final errorStr = signUpError.toString().toLowerCase();

          if (errorStr.contains('user already exists') || errorStr.contains('ya existe')) {
            // El usuario SÍ existe, entonces el error de login fue porque puso mal la contraseña
            throw Exception('La contraseña es incorrecta.');
          } else {
            // Es un usuario nuevo, pero puso una contraseña débil (ej. "1234")
            throw Exception(signUpError.toString().replaceAll('Exception:', '').trim());
          }
        }
      }

      // --- 🚦 EL SEMÁFORO (Si llegamos aquí, es porque el login fue exitoso) ---
      if (token != null && mounted) {
        print('🚦 Consultando estado del perfil en backend...');
        final isCompleted = await _userApiService.isProfileCompleted(token);

        if (isCompleted) {
          print('🟢 Perfil completo. Yendo al Home...');
          await _storageService.saveToken(token);
          if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainScreen()), (route) => false);
        } else {
          print('🔴 Perfil incompleto o nuevo. Yendo a Cumpleaños...');
          if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => BirthDateScreen(accessToken: token!)));
        }
      }

    } catch (e) {
      print('❌ ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString().replaceAll('Exception:', '').trim()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            )
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text('Continuar con Correo', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              const Text('Ingresa tu correo y contraseña para continuar', style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 40),

              CustomInput(label: 'Correo Electrónico', hint: 'ejemplo@correo.com', controller: _emailController, focusNode: _emailFocus),
              const SizedBox(height: 16),

              CustomInput(label: 'Contraseña', hint: '••••••••', controller: _passwordController, focusNode: _passwordFocus),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity, height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A)),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Continuar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}