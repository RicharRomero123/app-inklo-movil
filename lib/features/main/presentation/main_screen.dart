
import 'package:flutter/material.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../auth/presentation/screens/welcome_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inklop App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Cerrar sesión
              await SecureStorageService().deleteToken();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()), (r) => false);
              }
            },
          )
        ],
      ),
      body: const Center(child: Text('¡Bienvenido a Inklop! Has ingresado con éxito.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18))),
    );
  }
}