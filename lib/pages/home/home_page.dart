import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../routes/app_routes.dart';
import '../../providers/user_provider.dart';
import '../../providers/business_provider.dart'; // ✅ Importado
import '../../widgets/home_menu.dart';
import '../../widgets/loading_screen.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final prov = context.read<UserProvider>();
        await Future.wait([
          prov.carregarDoFirestore(),
          Future.delayed(const Duration(seconds: 2)),
        ]);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    });
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
    // Exibir AppBar global apenas na aba 0 (Início)
    if (_currentIdx != 0) return null;

    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade600, Colors.blue.shade400],
          ),
        ),
      ),
      title: Row(
        children: [
          const Icon(Icons.account_circle, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Consumer<UserProvider>(
            builder:
                (_, u, __) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.nome.isNotEmpty
                          ? 'Olá, ${u.nome.split(' ').first}!'
                          : 'Olá, Usuário!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Bem-vindo de volta',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
          tooltip: 'Notificações',
          color: Colors.white,
        ),
        HomeMenu(onLogout: _logout),
        const SizedBox(width: 8),
      ],
    );
  }

  /* ----------------------- UI --------------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildHomeAppBar(), // ← AppBar global controlado aqui

      body: Stack(
        children: [
          IndexedStack(
            index: _currentIdx,
            children: const [
              HomeBody(), // 0 – Início
              MeuNegocioPage(), // 1 – Meu negócio (AppBar próprio)
              CatalogoPage(), // 2 – Catálogo (AppBar próprio)
              ClientesPage(), // 3 – Clientes (AppBar próprio)
            ],
          ),
          if (_isLoading) const LoadingScreen(),
        ],
      ),

      bottomNavigationBar: HomeNavBar(
        selectedIndex: _currentIdx,
        onItemTapped: (idx) => setState(() => _currentIdx = idx),
      ),
    );
  }
}
