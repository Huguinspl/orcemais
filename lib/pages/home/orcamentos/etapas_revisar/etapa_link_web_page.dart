import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:deep_link/models/link_model.dart';
import 'package:deep_link/services/link_service.dart';
import '../../../../models/orcamento.dart';
import '../../../../providers/business_provider.dart';
import '../../../../providers/user_provider.dart';
import '../../../../providers/orcamentos_provider.dart';

class EtapaLinkWebPage extends StatefulWidget {
  final Orcamento orcamento;

  const EtapaLinkWebPage({super.key, required this.orcamento});

  @override
  State<EtapaLinkWebPage> createState() => _EtapaLinkWebPageState();
}

class _EtapaLinkWebPageState extends State<EtapaLinkWebPage> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _linkWeb;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarOuGerarLinkWeb();
    });
  }

  Future<void> _verificarOuGerarLinkWeb() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ✅ Verificar se o link já foi gerado
      if (widget.orcamento.linkWeb != null &&
          widget.orcamento.linkWeb!.isNotEmpty) {
        debugPrint('✅ Link web já existe: ${widget.orcamento.linkWeb}');

        // 🔧 CORREÇÃO: Ao invés de carregar o link curto (que redireciona e expira),
        // carregamos diretamente a URL do cliente com os parâmetros
        final urlCliente = await _construirUrlClienteWeb();

        setState(() {
          _linkWeb = widget.orcamento.linkWeb;
          _isLoading = false;
        });

        // Configurar o WebViewController com a URL direta do cliente
        _controller =
            WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..setNavigationDelegate(
                NavigationDelegate(
                  onProgress: (int progress) {
                    debugPrint('🔄 Carregando Link Web: $progress%');
                  },
                  onPageStarted: (String url) {
                    debugPrint('🌐 Iniciando carregamento: $url');
                  },
                  onPageFinished: (String url) {
                    debugPrint('✅ Página carregada: $url');
                  },
                  onWebResourceError: (WebResourceError error) {
                    debugPrint(
                      '❌ Erro ao carregar Link Web: ${error.description}',
                    );
                    if (mounted) {
                      setState(() {
                        _errorMessage = 'Erro ao carregar visualização.';
                      });
                    }
                  },
                ),
              )
              ..loadRequest(Uri.parse(urlCliente));
        return;
      }

      // Se não existe, gerar novo link
      debugPrint('🌐 Link web não existe, gerando novo...');
      await _gerarLinkWeb();
    } catch (e) {
      debugPrint('❌ Erro ao verificar/gerar Link Web: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Constrói a URL direta do cliente web para visualização no WebView
  Future<String> _construirUrlClienteWeb() async {
    final businessProvider = context.read<BusinessProvider>();
    final userProvider = context.read<UserProvider>();

    // Carregar dados do negócio se necessário
    if (businessProvider.nomeEmpresa.isEmpty) {
      await businessProvider.carregarDoFirestore();
    }

    final pdfTheme = businessProvider.pdfTheme;
    final parametros = StringBuffer();
    parametros.write('?userId=${userProvider.uid}');
    parametros.write('&documentoId=${widget.orcamento.id}');
    parametros.write('&tipoDocumento=orcamento');

    // Adicionar cores personalizadas
    if (pdfTheme != null) {
      if (pdfTheme['primary'] != null) {
        parametros.write('&primary=${pdfTheme['primary']}');
      }
      if (pdfTheme['laudoBackground'] != null) {
        parametros.write('&laudoBackground=${pdfTheme['laudoBackground']}');
      }
      if (pdfTheme['laudoText'] != null) {
        parametros.write('&laudoText=${pdfTheme['laudoText']}');
      }
    }

    final urlFinal = 'https://gestorfy-cliente.web.app$parametros';
    debugPrint('🌐 URL construída para WebView: $urlFinal');
    return urlFinal;
  }

  Future<void> _gerarLinkWeb() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final businessProvider = context.read<BusinessProvider>();
      final userProvider = context.read<UserProvider>();

      // Carregar dados do negócio se necessário
      if (businessProvider.nomeEmpresa.isEmpty) {
        await businessProvider.carregarDoFirestore();
      }

      // Obter cores personalizadas do PDF
      final pdfTheme = businessProvider.pdfTheme;
      final Map<String, dynamic> parametrosPersonalizados = {
        'userId': userProvider.uid,
        'documentoId': widget.orcamento.id,
        'tipoDocumento': 'orcamento',
      };

      debugPrint('📋 DEBUG etapa_link_web: Gerando link com parâmetros:');
      debugPrint('  userId: ${userProvider.uid}');
      debugPrint('  documentoId: ${widget.orcamento.id}');
      debugPrint('  tipoDocumento: orcamento');

      // Adicionar cores personalizadas se existirem
      if (pdfTheme != null) {
        if (pdfTheme['primary'] != null) {
          parametrosPersonalizados['primary'] = pdfTheme['primary'].toString();
        }
        if (pdfTheme['laudoBackground'] != null) {
          parametrosPersonalizados['laudoBackground'] =
              pdfTheme['laudoBackground'].toString();
        }
        if (pdfTheme['laudoText'] != null) {
          parametrosPersonalizados['laudoText'] =
              pdfTheme['laudoText'].toString();
        }
        if (pdfTheme['garantiaBackground'] != null) {
          parametrosPersonalizados['garantiaBackground'] =
              pdfTheme['garantiaBackground'].toString();
        }
        if (pdfTheme['garantiaText'] != null) {
          parametrosPersonalizados['garantiaText'] =
              pdfTheme['garantiaText'].toString();
        }
        if (pdfTheme['contratoBackground'] != null) {
          parametrosPersonalizados['contratoBackground'] =
              pdfTheme['contratoBackground'].toString();
        }
        if (pdfTheme['contratoText'] != null) {
          parametrosPersonalizados['contratoText'] =
              pdfTheme['contratoText'].toString();
        }
        if (pdfTheme['fotosBackground'] != null) {
          parametrosPersonalizados['fotosBackground'] =
              pdfTheme['fotosBackground'].toString();
        }
        if (pdfTheme['fotosText'] != null) {
          parametrosPersonalizados['fotosText'] =
              pdfTheme['fotosText'].toString();
        }
        if (pdfTheme['pagamentoBackground'] != null) {
          parametrosPersonalizados['pagamentoBackground'] =
              pdfTheme['pagamentoBackground'].toString();
        }
        if (pdfTheme['pagamentoText'] != null) {
          parametrosPersonalizados['pagamentoText'] =
              pdfTheme['pagamentoText'].toString();
        }
        if (pdfTheme['valoresBackground'] != null) {
          parametrosPersonalizados['valoresBackground'] =
              pdfTheme['valoresBackground'].toString();
        }
        if (pdfTheme['valoresText'] != null) {
          parametrosPersonalizados['valoresText'] =
              pdfTheme['valoresText'].toString();
        }
      }

      // Gerar o link usando o deep_link
      final link = await DeepLink.createLink(
        LinkModel(
          dominio: 'link.orcemais.com',
          titulo:
              'Orçamento ${widget.orcamento.numero} - ${businessProvider.nomeEmpresa}',
          slug: widget.orcamento.id,
          onlyWeb: true,
          urlImage: businessProvider.logoUrl,
          urlDesktop: 'https://gestorfy-cliente.web.app',
          parametrosPersonalizados: parametrosPersonalizados,
        ),
      );

      debugPrint('✅ Link Web gerado: ${link.link}');

      setState(() {
        _linkWeb = link.link;
        _isLoading = false;
      });

      // ✅ Salvar o link no orçamento
      await context.read<OrcamentosProvider>().atualizarLinkWeb(
        widget.orcamento.id,
        link.link,
      );
      debugPrint('✅ Link salvo no orçamento');

      // 🔧 CORREÇÃO: Carregar URL direta do cliente ao invés do link curto
      final urlCliente = await _construirUrlClienteWeb();

      // Configurar o WebViewController
      _controller =
          WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setNavigationDelegate(
              NavigationDelegate(
                onProgress: (int progress) {
                  debugPrint('🔄 Carregando Link Web: $progress%');
                },
                onPageStarted: (String url) {
                  debugPrint('🌐 Iniciando carregamento: $url');
                },
                onPageFinished: (String url) {
                  debugPrint('✅ Página carregada: $url');
                },
                onWebResourceError: (WebResourceError error) {
                  debugPrint(
                    '❌ Erro ao carregar Link Web: ${error.description}',
                  );
                },
              ),
            )
            ..loadRequest(Uri.parse(urlCliente));
    } catch (e) {
      debugPrint('❌ Erro ao gerar Link Web: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Gerando Link Web...'),
            SizedBox(height: 8),
            Text(
              'Aguarde enquanto preparamos a visualização',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Erro ao gerar Link Web',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _verificarOuGerarLinkWeb,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_linkWeb == null) {
      return const Center(child: Text('Link não disponível'));
    }

    // Mostrar o link web em um WebView
    return WebViewWidget(controller: _controller);
  }
}
