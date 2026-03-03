import 'package:flutter/material.dart';

class CustomInput extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isBio;
  final bool isNumber;
  final Widget? suffixIcon;
  final Function(String)? onChanged;

  const CustomInput({
    super.key, required this.label, required this.hint, required this.controller,
    required this.focusNode, this.isBio = false, this.isNumber = false, this.suffixIcon, this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive = focusNode.hasFocus || controller.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 6),
          child: Text(label, style: const TextStyle(color: Color(0xFFADADAD), fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(isBio ? 15 : 30),
            border: Border.all(color: isActive ? const Color(0xFFE0E0E0) : const Color(0xFFF3F3F3), width: 1.5),
          ),
          child: TextField(
            controller: controller, focusNode: focusNode, maxLines: isBio ? 3 : 1,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
            decoration: InputDecoration(
              hintText: hint, hintStyle: const TextStyle(color: Color(0xFFADADAD), fontSize: 14),
              border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: isBio ? 12 : 14),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}