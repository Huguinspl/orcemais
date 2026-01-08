import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_links/app_links.dart';
import '../routes/app_routes.dart';

/// Serviço para lidar com deep links e verificação de email
class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  BuildContext? _context;
  StreamSubscription? _linkSubscription;
  late AppLinks _appLinks;

  /// Inicializa o handler de deep links
  Future<void> initialize(BuildContext context) async {
    _context = context;
    _appLinks = AppLinks();

    // Verifica se o app foi aberto através de um link
    await _checkInitialLink();

    // Escuta links enquanto o app está aberto
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (error) {
        debugPrint('❌ Erro ao processar deep link: $error');
      },
    );
  }

  /// Verifica o link inicial ao abrir o app
  Future<void> _checkInitialLink() async {
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('🔗 Link inicial recebido: $initialUri');
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('❌ Erro ao verificar link inicial: $e');
    }
  }

  /// Processa o deep link recebido
  void _handleDeepLink(Uri? uri) {
    if (uri == null || _context == null) return;

    debugPrint('🔗 Deep link recebido: $uri');
    debugPrint('🔗 Host: ${uri.host}');
    debugPrint('🔗 Path: ${uri.path}');
    debugPrint('🔗 Query: ${uri.query}');

    // Captura qualquer link do Firebase ou links relacionados a verificação
    final isFirebaseLink =
        uri.host.contains('firebaseapp.com') ||
        uri.host.contains('page.link') ||
        uri.host.contains('web.app');

    final isVerificationLink =
        uri.queryParameters.containsKey('mode') ||
        uri.queryParameters.containsKey('oobCode') ||
        uri.path.contains('verify') ||
        uri.path.contains('email');

    if (isFirebaseLink || isVerificationLink) {
      final mode = uri.queryParameters['mode'];

      // Processa diferentes tipos de ações do Firebase Auth
      if (mode == 'verifyEmail' || isVerificationLink) {
        debugPrint('📧 Link de verificação de email detectado!');
        _handleEmailVerification();
      } else if (mode == 'resetPassword') {
        debugPrint('🔐 Link de reset de senha detectado');
        // Futuramente pode adicionar tratamento para reset de senha
      } else {
        // Qualquer outro link do Firebase, tenta processar como verificação
        debugPrint('🔗 Link do Firebase detectado, tentando processar...');
        _handleEmailVerification();
      }
    }
  }

  /// Trata a verificação de email
  Future<void> _handleEmailVerification() async {
    if (_context == null || !_context!.mounted) return;

    debugPrint('📧 Processando verificação de email...');

    // Aguarda um pouco para o Firebase processar
    await Future.delayed(const Duration(seconds: 2));

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Recarrega as informações do usuário
      await user.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;

      if (updatedUser?.emailVerified == true) {
        debugPrint('✅ Email verificado com sucesso!');

        if (_context!.mounted) {
          // Mostra mensagem de sucesso
          ScaffoldMessenger.of(_context!).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Email verificado com sucesso!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );

          // Redireciona para a home
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_context!.mounted) {
              Navigator.of(
                _context!,
              ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
            }
          });
        }
      } else {
        debugPrint('⚠️ Email ainda não verificado');
        if (_context!.mounted) {
          ScaffoldMessenger.of(_context!).showSnackBar(
            const SnackBar(
              content: Text('Aguarde, processando verificação...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      // Usuário não está logado, redireciona para login
      debugPrint('⚠️ Usuário não autenticado, redirecionando para login');
      if (_context!.mounted) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          const SnackBar(
            content: Text('Por favor, faça login novamente'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          if (_context!.mounted) {
            Navigator.of(
              _context!,
            ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
          }
        });
      }
    }
  }

  /// Limpa os recursos ao desmontar
  void dispose() {
    _linkSubscription?.cancel();
    _context = null;
  }
}
