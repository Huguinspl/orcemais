import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _obscureSenha = true;
  bool _obscureConfirmarSenha = true;
  bool _isLoading = false;

  /*---------------------------------------------------------------*/
  Future<void> _cadastrarUsuario() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();
    final confirmarSenha = _confirmarSenhaController.text.trim();

    if (senha != confirmarSenha) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('As senhas não coincidem.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      /* 1) Autenticação Firebase */
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      /* 2) Documento em Firestore (email “fixo”) */
      await FirestoreService().createUser(email: email);

      /* 3) Flags locais */
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('tutorialVisto', false);

      if (!mounted) return;

      /* 4) Provider: carrega dados + e-mail fixo  */
      final provider = context.read<UserProvider>();
      await provider.carregarDoFirestore(); // dados (nome, cpf…)
      await provider.setEmailCadastro(email); // e-mail fixo

      if (!mounted) return;

      /* 5) Navega para o Tutorial limpando a pilha  */
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.tutorial,
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao cadastrar: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  /*---------------------------------------------------------------*/

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Cadastro')),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  /* ------------------ E-mail ------------------- */
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  /* ------------------ Senha -------------------- */
                  TextFormField(
                    controller: _senhaController,
                    obscureText: _obscureSenha,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureSenha
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed:
                            () =>
                                setState(() => _obscureSenha = !_obscureSenha),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /* ------------- Confirmar Senha --------------- */
                  TextFormField(
                    controller: _confirmarSenhaController,
                    obscureText: _obscureConfirmarSenha,
                    decoration: InputDecoration(
                      labelText: 'Confirmar senha',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmarSenha
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed:
                            () => setState(
                              () =>
                                  _obscureConfirmarSenha =
                                      !_obscureConfirmarSenha,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  /* ---------------- Botão ---------------------- */
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _cadastrarUsuario,
                      child: const Text(
                        'Cadastrar',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        /* --------------- Loading Overlay ---------------- */
        if (_isLoading)
          Container(
            color: const Color.fromRGBO(0, 0, 0, .3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
