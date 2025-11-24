import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../providers/user_provider.dart';
import '../providers/clients_provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final tutorialVisto = prefs.getBool('tutorialVisto') ?? false;

    if (!isLoggedIn) {
      Navigator.pushReplacementNamed(context, AppRoutes.apresentacao);
      return;
    }

    final userProvider = context.read<UserProvider>();

    try {
      // 🔄 Carrega perfil do usuário
      await userProvider.carregarDoFirestore();
      if (!mounted) return; // ← novo check

      // 🔄 Carrega clientes
      final uid = userProvider.uid;
      if (uid.isNotEmpty) {
        await context.read<ClientsProvider>().carregarTodos(uid);
      }
    } catch (e) {
      debugPrint('Erro ao carregar Firestore: $e');
      if (!mounted) return;
    }

    if (!mounted) return;

    if (!tutorialVisto) {
      Navigator.pushReplacementNamed(context, AppRoutes.tutorial);
      return;
    }

    if (userProvider.nome.isEmpty) {
      Navigator.pushReplacementNamed(context, AppRoutes.informacoesOrcamento);
      return;
    }

    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
