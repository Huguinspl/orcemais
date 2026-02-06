import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../routes/app_routes.dart';
import '../../providers/user_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/agendamentos_provider.dart';
import '../../services/notification_service.dart';
import '../../services/tutorial_service.dart';
import '../../widgets/home_menu.dart';
import '../../widgets/loading_screen.dart';
import '../../widgets/tutorial_overlay.dart';
import 'home_body.dart';
import 'home_navbar.dart';
import 'tabs/meu_negocio_page.dart';
import 'tabs/clientes_page.dart';
import 'tabs/catalogo_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  int _currentIdx = 0; // 0‑Início | 1‑Meu negócio | 2‑Catálogo | 3‑Clientes
  bool _showTutorial = false;

  // PageController para swipe entre abas
  late PageController _pageController;

  // GlobalKey para o tutorial
  final GlobalKey _bottomNavKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIdx);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final prov = context.read<UserProvider>();
        await Future.wait([
          prov.carregarDoFirestore(),
          Future.delayed(const Duration(seconds: 2)),
        ]);
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);

          // Aguarda mais um frame para garantir que tudo está renderizado
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            // Aguarda um pouco mais para garantir que os widgets estão prontos
            await Future.delayed(const Duration(milliseconds: 500));

            // Verifica se deve mostrar o tutorial
            final tutorialConcluido =
                await TutorialService.isTutorialConcluido();
            if (!tutorialConcluido && mounted) {
              setState(() => _showTutorial = true);
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /* ------------------- NAVEGAÇÃO ENTRE ABAS ------------------- */
  void _navigateToTab(int index) {
    setState(() => _currentIdx = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /* ------------------- NOTIFICAÇÕES ------------------- */
  Future<void> _testarNotificacao() async {
    final notificationService = NotificationService();

    // Mostra notificação imediata
    await notificationService.mostrarNotificacaoImediata(
      titulo: '🧪 Teste de Notificação',
      corpo: 'Se você viu isso, as notificações estão funcionando!',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.science, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Notificação de teste enviada! Verifique se apareceu.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _solicitarPermissaoNotificacoes() async {
    final notificationService = NotificationService();

    // Inicializa o serviço se ainda não foi
    if (!notificationService.isInitialized) {
      await notificationService.initialize();
    }

    // Se já tem permissão, apenas mostra feedback
    if (notificationService.permissionGranted) {
      if (!mounted) return;
      _mostrarDialogoNotificacoes(
        context: context,
        titulo: 'Notificações Ativas',
        mensagem:
            'Você receberá alertas 30 minutos antes dos seus agendamentos confirmados.',
        icone: Icons.notifications_active,
        corIcone: Colors.teal,
      );
      return;
    }

    // Solicita permissão
    final permitido = await notificationService.requestPermission();

    if (!mounted) return;

    if (permitido) {
      // Reagenda todas as notificações dos agendamentos
      final agendamentosProvider = context.read<AgendamentosProvider>();
      await notificationService.reagendarNotificacoes(
        agendamentosProvider.agendamentos,
      );

      _mostrarDialogoNotificacoes(
        context: context,
        titulo: 'Notificações Ativadas! ✓',
        mensagem:
            'Você receberá alertas 30 minutos antes dos seus agendamentos confirmados.',
        icone: Icons.check_circle,
        corIcone: Colors.green,
      );
    } else {
      _mostrarDialogoNotificacoes(
        context: context,
        titulo: 'Permissão Negada',
        mensagem:
            'Para receber notificações dos seus agendamentos, ative as permissões nas configurações do app.',
        icone: Icons.notifications_off,
        corIcone: Colors.orange,
      );
    }
  }

  void _mostrarDialogoNotificacoes({
    required BuildContext context,
    required String titulo,
    required String mensagem,
    required IconData icone,
    required Color corIcone,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, corIcone.withOpacity(0.1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: corIcone,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icone, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  mensagem,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: corIcone.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: corIcone,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Entendi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /* ------------------- LOGOUT ------------------- */
  Future<void> _logout() async {
    final nav = Navigator.of(context);
    final userProv = context.read<UserProvider>();
    final businessProv = context.read<BusinessProvider>(); // ✅ novo

    try {
      (await SharedPreferences.getInstance()).setBool('isLoggedIn', false);
      userProv.limparDados();
      businessProv.limparDados(); // ✅ limpa dados da empresa também
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Erro durante logout: $e');
    } finally {
      if (mounted) {
        nav.pushNamedAndRemoveUntil(AppRoutes.apresentacao, (_) => false);
      }
    }
  }

  /* ---------------- AppBar dinâmico --------------- */
  PreferredSizeWidget? _buildHomeAppBar() {
    // AppBar agora está dentro de cada página como SliverAppBar
    return null;
  }

  /* ----------------------- UI --------------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildHomeAppBar(), // ← AppBar global controlado aqui

      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIdx = index);
            },
            children: [
              HomeBody(
                onNotificationPressed: _solicitarPermissaoNotificacoes,
                onNotificationLongPressed: _testarNotificacao,
                onLogout: _logout,
              ), // 0 – Início (SliverAppBar próprio)
              MeuNegocioPage(
                onBack: () => _navigateToTab(0),
              ), // 1 – Meu negócio (volta para Início)
              CatalogoPage(
                onBack: () => _navigateToTab(1),
              ), // 2 – Catálogo (volta para Meu negócio)
              ClientesPage(
                onBack: () => _navigateToTab(2),
              ), // 3 – Clientes (volta para Catálogo)
            ],
          ),
          if (_isLoading) const LoadingScreen(),

          // Overlay do tutorial
          if (_showTutorial)
            TutorialOverlay(
              bottomNavKey: _bottomNavKey,
              onComplete: () {
                setState(() => _showTutorial = false);
              },
            ),
        ],
      ),

      bottomNavigationBar: HomeNavBar(
        key: _bottomNavKey,
        selectedIndex: _currentIdx,
        onItemTapped: (idx) {
          setState(() => _currentIdx = idx);
          _pageController.animateToPage(
            idx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }
}
