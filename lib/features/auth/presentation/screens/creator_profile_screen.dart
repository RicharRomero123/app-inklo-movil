import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inklop_v1/core/utils/custom_input.dart'; // Ajusta la ruta si es necesario
import '../../../../core/services/secure_storage_service.dart';
import '../../data/user_api_service.dart';
import '../../../main/presentation/main_screen.dart';

class CreatorProfileScreen extends StatefulWidget {
  final String accessToken;
  final String birthDate;
  const CreatorProfileScreen({super.key, required this.accessToken, required this.birthDate});

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  final UserApiService _apiService = UserApiService();
  final SecureStorageService _storageService = SecureStorageService();

  Timer? _debounce;
  bool _isCheckingUsername = false;
  bool? _isUsernameValid;
  bool _isLoadingPost = false;

  // Variables para la foto de perfil
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  String _selectedDocType = 'DNI';
  final List<String> _docTypes = ['DNI', 'RUC', 'CE', 'PASAPORTE'];

  final _controllers = {
    'username': TextEditingController(), 'nombre': TextEditingController(),
    'apellido': TextEditingController(), 'documento': TextEditingController(),
    'bio': TextEditingController(), 'pais': TextEditingController(), 'ciudad': TextEditingController(),
  };
  final _focusNodes = {
    'username': FocusNode(), 'nombre': FocusNode(), 'apellido': FocusNode(),
    'documento': FocusNode(), 'bio': FocusNode(), 'pais': FocusNode(), 'ciudad': FocusNode(),
  };

  @override
  void initState() {
    super.initState();
    _focusNodes.forEach((k, v) => v.addListener(() => setState(() {})));
  }

  // --- Función para seleccionar la imagen ---
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      print("Error al seleccionar imagen: $e");
    }
  }

  void _onUsernameChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (value.isEmpty) { setState(() { _isUsernameValid = null; _isCheckingUsername = false; }); return; }

    setState(() => _isCheckingUsername = true);
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final result = await _apiService.checkUsername(value, widget.accessToken);
      if (mounted) {
        setState(() {
          _isUsernameValid = result['valid'] == true && result['exists'] == false;
          _isCheckingUsername = false;
        });
      }
    });
  }

  Future<void> _submitData() async {
    if (_isUsernameValid != true) return;

    if (_controllers['nombre']!.text.isEmpty || _controllers['apellido']!.text.isEmpty ||
        _controllers['documento']!.text.isEmpty || _controllers['pais']!.text.isEmpty ||
        _controllers['ciudad']!.text.isEmpty || _controllers['bio']!.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor llena todos los campos.'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoadingPost = true);

    try {
      // 1. CONSTRUIR PAYLOAD (POST)
      final payload = {
        "real_name": '${_controllers['nombre']!.text} ${_controllers['apellido']!.text}'.trim(),
        "username": _controllers['username']!.text.trim(),
        "typeDocument": _selectedDocType,
        "document": _controllers['documento']!.text.trim(),
        // 🔥 SOLUCIÓN: URL temporal válida para que el backend no lance Error 400
        "avatarUrl": "https://ui-avatars.com/api/?name=User&background=random",
        "country": _controllers['pais']!.text.trim(),
        "city": _controllers['ciudad']!.text.trim(),
        "birthDate": widget.birthDate,
        "description": _controllers['bio']!.text.trim()
      };

      print('\n============= JSON PARA SWAGGER (POST) =============');
      print(jsonEncode(payload));

      // 2. ENVIAR POST
      final successPost = await _apiService.registerExtraData(payload, widget.accessToken);

      if (successPost) {
        // 3. SI HAY IMAGEN, ENVIAR PUT MULTIPART
        if (_profileImage != null) {
          print('Enviando PUT de imagen...');
          await _apiService.uploadProfileImage(_profileImage!.path, widget.accessToken);
        }

        // 4. GUARDAR TOKEN Y NAVEGAR AL HOME
        await _storageService.saveToken(widget.accessToken);
        if (mounted) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainScreen()), (route) => false);
        }
      } else {
        throw Exception('El servidor rechazó los datos (Error 400 u otro). Revisa la consola.');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoadingPost = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? userSuffix = _isCheckingUsername ? const Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(strokeWidth: 2))
        : (_isUsernameValid == true ? const Icon(Icons.check_circle, color: Colors.green) : (_isUsernameValid == false ? const Icon(Icons.cancel, color: Colors.red) : null));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black), onPressed: () => Navigator.pop(context))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECCIÓN DEL AVATAR CON LA LIBRERÍA DE FOTOS
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFFF3F3F3),
                        backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                        child: _profileImage == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                        child: const Icon(Icons.edit, size: 16, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(child: Text('Completa Tu Perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              const Center(child: Text('Date a conocer a otros creadores y la comunidad Inklop', style: TextStyle(fontSize: 13, color: Colors.grey))),
              const SizedBox(height: 24),

              CustomInput(label: 'Nombre de usuario', hint: '@username', controller: _controllers['username']!, focusNode: _focusNodes['username']!, onChanged: _onUsernameChanged, suffixIcon: userSuffix),
              if (_isUsernameValid == false && !_isCheckingUsername) const Padding(padding: EdgeInsets.only(left: 8.0), child: Text('Usuario no disponible', style: TextStyle(color: Colors.red, fontSize: 12))),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: CustomInput(label: 'Nombre', hint: 'Nombre', controller: _controllers['nombre']!, focusNode: _focusNodes['nombre']!)),
                  const SizedBox(width: 12),
                  Expanded(child: CustomInput(label: 'Apellido', hint: 'Apellido', controller: _controllers['apellido']!, focusNode: _focusNodes['apellido']!)),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: CustomInput(label: 'País', hint: 'País', controller: _controllers['pais']!, focusNode: _focusNodes['pais']!)),
                  const SizedBox(width: 12),
                  Expanded(child: CustomInput(label: 'Ciudad', hint: 'Ciudad', controller: _controllers['ciudad']!, focusNode: _focusNodes['ciudad']!)),
                ],
              ),
              const SizedBox(height: 12),

              const Padding(
                padding: EdgeInsets.only(left: 4.0, bottom: 6),
                child: Text('Documento de identidad', style: TextStyle(color: Color(0xFFADADAD), fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              Row(
                children: [
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFFF3F3F3), width: 1.5)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDocType,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                        items: _docTypes.map((String type) => DropdownMenuItem<String>(value: type, child: Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)))).toList(),
                        onChanged: (String? newValue) => setState(() => _selectedDocType = newValue!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(30), border: Border.all(color: _focusNodes['documento']!.hasFocus ? const Color(0xFFE0E0E0) : const Color(0xFFF3F3F3), width: 1.5)),
                      child: TextField(
                        controller: _controllers['documento'], focusNode: _focusNodes['documento'], keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
                        decoration: const InputDecoration(hintText: 'Número', hintStyle: TextStyle(color: Color(0xFFADADAD), fontSize: 14), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              CustomInput(label: 'Bio', hint: 'Soy el CPO de @Inklop y...', controller: _controllers['bio']!, focusNode: _focusNodes['bio']!, isBio: true),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity, height: 54,
                child: FilledButton(
                  onPressed: _isLoadingPost ? null : _submitData,
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A)),
                  child: _isLoadingPost ? const CircularProgressIndicator(color: Colors.white) : const Text('Continuar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}