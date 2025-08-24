// lib/main.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'conditional_desktop.dart' if (dart.library.html) 'stub_desktop.dart';

// Providers
import 'providers/user_provider.dart';
import 'providers/business_provider.dart';
import 'providers/clients_provider.dart';
import 'providers/services_provider.dart';
import 'providers/pecas_provider.dart';

// Rotas & páginas
import 'routes/app_routes.dart';
import 'pages/splash_page.dart';
import 'pages/apresentacao_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/home/home_page.dart';
import 'pages/recuperar_senha_page.dart';
import 'pages/perfil_page.dart';
import 'pages/termos_page.dart';
import 'pages/tutorial_page.dart';
import 'pages/informacoes_orcamento_page.dart';
import 'pages/home/tabs/dados_negocio_page.dart';
import 'pages/home/tabs/novo_cliente_page.dart';
import 'pages/home/tabs/detalhe_cliente_page.dart';
import 'pages/home/tabs/servicos_page.dart';
import 'pages/home/tabs/pecas_materiais_page.dart';
import 'pages/home/tabs/novo_peca_material_page.dart';
import 'models/peca_material.dart';
import 'pages/home/orcamentos/orcamentos_page.dart';
import 'pages/home/orcamentos/novo_orcamento_page.dart';
import 'pages/home/orcamentos/novo_orcamento/selecionar_servicos_page.dart';
import 'package:gestorfy/providers/orcamentos_provider.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    configureDesktopWindow();
  }

  runApp(const GestorfyRoot());
}

class GestorfyRoot extends StatelessWidget {
  const GestorfyRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserProvider()..carregarDoFirestore(),
        ),
        ChangeNotifierProvider(
          create: (_) => BusinessProvider()..carregarDoFirestore(),
        ),
        ChangeNotifierProvider(create: (_) => ClientsProvider()),
        ChangeNotifierProvider(create: (_) => ServicesProvider()),
        ChangeNotifierProvider(create: (_) => PecasProvider()),
        ChangeNotifierProvider(create: (_) => OrcamentosProvider()),
      ],
      child: const GestorfyApp(),
    );
  }
}

class GestorfyApp extends StatelessWidget {
  const GestorfyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestorfy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashPage(),
        AppRoutes.apresentacao: (_) => const ApresentacaoPage(),
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.cadastro: (_) => const SignupPage(),
        AppRoutes.home: (_) => const HomePage(),
        AppRoutes.recuperarSenha: (_) => const RecuperarSenhaPage(),
        AppRoutes.perfil: (_) => const PerfilPage(),
        AppRoutes.termos: (_) => const TermosPage(),
        AppRoutes.tutorial: (_) => const TutorialPage(),
        AppRoutes.informacoesOrcamento: (_) => const InformacoesOrcamentoPage(),
        AppRoutes.dadosNegocio: (_) => const DadosNegocioPage(),
        AppRoutes.novoCliente: (_) => const NovoClientePage(),
        AppRoutes.detalheCliente: (_) => const DetalheClientePage(),
        '/servicos': (_) => const ServicosPage(),
        AppRoutes.pecasMateriais: (_) => const PecasMateriaisPage(),
        AppRoutes.orcamentos: (_) => const OrcamentosPage(), // ✅ adicionada
        AppRoutes.novoPecaMaterial: (context) {
          final peca =
              ModalRoute.of(context)!.settings.arguments as PecaMaterial?;
          return NovoPecaMaterialPage(peca: peca);
        },
        AppRoutes.novoOrcamento: (_) => const NovoOrcamentoPage(),
        AppRoutes.selecionarServicos: (_) => const SelecionarServicosPage(),
      },
    );
  }
}
