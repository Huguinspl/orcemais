import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_routes.dart';

class TutorialPage extends StatelessWidget {
  const TutorialPage({super.key});

  Future<void> _continuar(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorialVisto', true);

    if (context.mounted) {
      // Remove tudo da pilha e vai direto para a página de informações
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.informacoesOrcamento,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutorial'),
        automaticallyImplyLeading: false, // ❌ remove botão de voltar
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Bem-vindo ao Gestorfy!\n\nAqui você pode controlar suas finanças de forma fácil e prática. '
              'Navegue pelo app para registrar despesas, ver relatórios, configurar metas e muito mais.',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _continuar(context),
                child: const Text('VAMOS COMEÇAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
