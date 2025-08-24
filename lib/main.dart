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
import 'providers/agendamentos_provider.dart';
import 'pages/home/agendamentos/agendamentos_page.dart';
import 'pages/home/agendamentos/novo_agendamento_page.dart';
import 'providers/recibos_provider.dart';
import 'pages/home/recibos/recibos_page.dart';
import 'pages/home/recibos/novo_recibo_page.dart';
import 'pages/home/recibos/novo_valor_recebido_page.dart';
import 'providers/despesas_provider.dart';
import 'pages/home/despesas/despesas_page.dart';
import 'pages/home/despesas/nova_despesa_page.dart';

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
        ChangeNotifierProvider(create: (_) => AgendamentosProvider()),
        ChangeNotifierProvider(create: (_) => RecibosProvider()),
        ChangeNotifierProvider(create: (_) => DespesasProvider()),
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
        AppRoutes.agendamentos: (_) => const AgendamentosPage(),
        AppRoutes.novoPecaMaterial: (context) {
          final peca =
              ModalRoute.of(context)!.settings.arguments as PecaMaterial?;
          return NovoPecaMaterialPage(peca: peca);
        },
        AppRoutes.novoOrcamento: (_) => const NovoOrcamentoPage(),
        AppRoutes.selecionarServicos: (_) => const SelecionarServicosPage(),
        AppRoutes.novoAgendamento: (_) => const NovoAgendamentoPage(),
        AppRoutes.recibos: (_) => const RecibosPage(),
        AppRoutes.novoRecibo: (_) => const NovoReciboPage(),
        AppRoutes.novoValorRecebido: (_) => const NovoValorRecebidoPage(),
        AppRoutes.despesas: (_) => const DespesasPage(),
        AppRoutes.novaDespesa: (_) => const NovaDespesaPage(),
      },
    );
  }
}
