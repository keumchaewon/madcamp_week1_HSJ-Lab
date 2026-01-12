import 'package:flutter/material.dart';

class OnboardingIdScreen extends StatelessWidget {
  const OnboardingIdScreen({
    super.key,
    required this.username,
    required this.isValid,
    required this.onChanged,
    required this.onNext,
    this.errorText,
  });

  final String username;
  final bool isValid;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose your ID',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '3~15자 영문/숫자/언더스코어만 사용할 수 있어요.',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          initialValue: username,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixText: '@',
            hintText: 'username',
            errorText: errorText,
            filled: true,
            fillColor: const Color(0xFFF4F5F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isValid ? onNext : null,
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }
}
