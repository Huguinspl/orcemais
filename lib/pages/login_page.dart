import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../providers/user_provider.dart';
import 'package:gestorfy/pages/home/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _obscureText = true;
  bool _isLoading = false;

  /* ─────────────────────────── LOGIN ─────────────────────────── */
  Future<void> _fazerLogin() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final userProv = context.read<UserProvider>(); // capturado antes de awaits

    try {
      final email = _emailController.text.trim();
      final senha = _senhaController.text.trim();

      // 1) Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      // 2) SharedPrefs → flag de sessão
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      // 3) Provider: email fixo + carga completa do Firestore
      userProv.setEmailCadastro(email);
      await userProv.carregarDoFirestore();

      // 4) UX extra
      if (mounted) {
        FocusScope.of(context).unfocus();
        await precacheImage(
          const AssetImage('assets/gestorfy_logo_principal.png'),
          context,
        );
      }

      // 5) Navega p/ Home
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (_, __, ___) => const HomePage(),
            transitionsBuilder:
                (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao fazer login: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  /* ───────────────────────────────────────────────────────────── */

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  Image.asset(
                    'assets/gestorfy_logo_principal.png',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Entre com sua conta',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ainda não tem conta?',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  TextButton(
                    onPressed:
                        () => Navigator.pushNamed(context, AppRoutes.cadastro),
                    child: const Text(
                      'Criar conta nova',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _senhaController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed:
                            () => setState(() => _obscureText = !_obscureText),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _fazerLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Entrar',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed:
                        () => Navigator.pushNamed(
                          context,
                          AppRoutes.recuperarSenha,
                        ),
                    child: const Text(
                      'Recuperar minha senha',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: const Color.fromRGBO(0, 0, 0, 0.30), // evita .withOpacity()
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
