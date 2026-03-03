import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final String iconPath;
  final String label;
  final VoidCallback onTap;

  const SocialButton({super.key, required this.iconPath, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        decoration: BoxDecoration(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconPath, height: 24, width: 24, errorBuilder: (c, e, s) => const Icon(Icons.error)),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}