import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import 'package:gestorfy/pages/home/home_page.dart';

class InformacoesOrcamentoPage extends StatefulWidget {
  const InformacoesOrcamentoPage({super.key});

  @override
  State<InformacoesOrcamentoPage> createState() =>
      _InformacoesOrcamentoPageState();
}

class _InformacoesOrcamentoPageState extends State<InformacoesOrcamentoPage> {
  final TextEditingController _nomeController = TextEditingController();

  bool _isButtonEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomeController.addListener(() {
      setState(() => _isButtonEnabled = _nomeController.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  /* ─────────────────────── SALVAR NOME ─────────────────────── */
  Future<void> _salvarNome() async {
    setState(() => _isLoading = true);

    final nome = _nomeController.text.trim();
    final userProv = context.read<UserProvider>(); // captura antes dos awaits
    userProv.atualizarNome(nome);

    // grava no Firestore (nome, email fixo, cpf…)
    await userProv.salvarNoFirestore();

    if (!mounted) return;

    // pequeno delay só p/ UX suave (teclado / snackbar)
    await Future.delayed(const Duration(milliseconds: 120));

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => const HomePage(),
        transitionsBuilder:
            (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }
  /* ─────────────────────────────────────────────────────────── */

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Informações do orçamento'),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed:
                    () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Preencha seu nome; você pode editá-lo depois.',
                        ),
                      ),
                    ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seu nome completo:',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Ex: Maria Silva',
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        (_isButtonEnabled && !_isLoading) ? _salvarNome : null,
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: const Color.fromRGBO(0, 0, 0, 0.30),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
