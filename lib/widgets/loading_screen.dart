import 'package:flutter/material.dart';

/// Tela branca com um CircularProgressIndicator preto.
/// Pode ser usada em qualquer lugar do app enquanto dados assíncronos carregam.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator(color: Colors.black)),
    );
  }
}
