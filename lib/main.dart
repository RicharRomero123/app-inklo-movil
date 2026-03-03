import 'package:flutter/material.dart';
import 'core/services/secure_storage_service.dart';
import 'features/auth/presentation/screens/welcome_screen.dart';
import 'features/main/presentation/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String?> _checkLoginStatus() async {
    final storage = SecureStorageService();
    return await storage.getToken();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inklop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.black), useMaterial3: true),
      home: FutureBuilder<String?>(
        future: _checkLoginStatus(),
        builder: (context, snapshot) {
          // Mientras lee la memoria, muestra un cargador
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          // Si encontró el token, va al Home. Si no, al Login.
          if (snapshot.hasData && snapshot.data != null) {
            return const MainScreen();
          } else {
            return const WelcomeScreen();
          }
        },
      ),
    );
  }
}