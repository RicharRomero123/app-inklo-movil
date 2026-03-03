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

  bool _isLogin = true; // true = Iniciar Sesión, false = Crear Cuenta
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
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

      if (_isLogin) {
        // --- FLUJO 1: SOLO INICIAR SESIÓN ---
        print('🔐 Iniciando sesión con correo...');
        token = await _authService.loginWithEmail(email, password);

      } else {
        // --- FLUJO 2: SOLO REGISTRAR ---
        print('📝 Registrando cuenta nueva en Auth0...');
        await _authService.signUpWithEmail(email, password);

        print('✅ Registro exitoso. Mostrando diálogo de verificación...');
        setState(() => _isLoading = false);

        // 🛑 Le mostramos el aviso para que verifique su correo
        if (mounted) {
          showDialog(
              context: context,
              barrierDismissible: false, // Evita que lo cierre tocando afuera
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('¡Revisa tu correo! 📩', textAlign: TextAlign.center),
                content: const Text(
                  'Te enviamos un enlace de verificación. Ábrelo desde tu celular o computadora. Cuando lo hayas hecho, presiona el botón de abajo.',
                  textAlign: TextAlign.center,
                ),
                actions: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        // Cierra el diálogo y automáticamente intenta iniciar sesión
                        Navigator.pop(context);
                        setState(() {
                          _isLogin = true; // Lo pasamos al modo Login
                        });
                        _submit(); // Llamamos de nuevo a la función para que entre por el Flujo 1
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
                      // Cierra el diálogo y lo deja en el formulario para que entre después
                      Navigator.pop(context);
                      setState(() {
                        _isLogin = true;
                        _passwordController.clear(); // Limpiamos por seguridad
                      });
                    },
                    child: const Text('Lo haré más tarde', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  )
                ],
              )
          );
        }
        return; // 🛑 Detenemos la ejecución aquí para que no siga evaluando sin token
      }

      // --- 🚦 EL SEMÁFORO (Solo llega aquí si obtuvo el Token en el Flujo 1) ---
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
      print('❌ ERROR AUTH0: $e');
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
              Text(_isLogin ? 'Iniciar Sesión' : 'Crear Cuenta', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(_isLogin ? 'Qué bueno verte de nuevo' : 'Únete a Inklop hoy mismo', style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
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
                      : Text(_isLogin ? 'Ingresar' : 'Registrarme', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),

              // EL INTERRUPTOR PARA CAMBIAR ENTRE LOGIN Y REGISTRO
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: RichText(
                  text: TextSpan(
                    text: _isLogin ? '¿No tienes cuenta? ' : '¿Ya tienes una cuenta? ',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                    children: [
                      TextSpan(
                        text: _isLogin ? 'Regístrate aquí' : 'Inicia sesión',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}