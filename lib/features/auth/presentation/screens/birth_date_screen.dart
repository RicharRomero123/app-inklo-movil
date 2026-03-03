import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'creator_profile_screen.dart';

class BirthDateScreen extends StatefulWidget {
  final String accessToken;
  const BirthDateScreen({super.key, required this.accessToken});

  @override
  State<BirthDateScreen> createState() => _BirthDateScreenState();
}

class _BirthDateScreenState extends State<BirthDateScreen> {
  final _dateController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isDateValid = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  void _validateDate(String value) {
    if (value.length != 14) {
      if (_isDateValid) setState(() { _isDateValid = false; _errorText = null; });
      return;
    }
    try {
      List<String> parts = value.replaceAll(' ', '').split('/');
      int day = int.parse(parts[0]); int month = int.parse(parts[1]); int year = int.parse(parts[2]);
      final now = DateTime.now();
      if (year < 1900 || year > now.year || month < 1 || month > 12) throw Exception();
      final dob = DateTime(year, month, day);
      int age = now.year - dob.year;
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;

      if (age < 18) {
        setState(() { _isDateValid = false; _errorText = "Debes ser mayor de 18 años."; });
        return;
      }
      setState(() { _isDateValid = true; _errorText = null; });
    } catch (e) {
      setState(() { _isDateValid = false; _errorText = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black), onPressed: () => Navigator.pop(context))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text('Ingresa tu fecha de nacimiento', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Para verificar tu edad', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              TextField(
                controller: _dateController, focusNode: _focusNode, textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8), BirthDateInputFormatter()],
                decoration: InputDecoration(hintText: 'DD / MM / AAAA', errorText: _errorText),
                onChanged: _validateDate,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity, height: 56,
                child: FilledButton(
                  onPressed: _isDateValid ? () {
                    final parts = _dateController.text.replaceAll(' ', '').split('/');
                    final formattedDate = '${parts[2]}-${parts[1]}-${parts[0]}';
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CreatorProfileScreen(accessToken: widget.accessToken, birthDate: formattedDate)));
                  } : null,
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A)),
                  child: const Text('Continuar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class BirthDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text; var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i == 1 || i == 3) && i != text.length - 1) buffer.write(' / ');
    }
    return newValue.copyWith(text: buffer.toString(), selection: TextSelection.collapsed(offset: buffer.toString().length));
  }
}