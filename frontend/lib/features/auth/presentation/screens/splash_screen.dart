import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1a1a2e),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFe94560),
          strokeWidth: 3,
        ),
      ),
    );
  }
}
