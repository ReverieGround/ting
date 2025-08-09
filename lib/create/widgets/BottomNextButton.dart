// widgets/BottomNextButton.dart
import 'package:flutter/material.dart';

class BottomNextButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const BottomNextButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: const BorderSide(color: Color.fromRGBO(255, 110, 199, 1), width: 1),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text(
                  '다음',
                  style: TextStyle(
                    color: Color.fromRGBO(255, 110, 199, 1),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
