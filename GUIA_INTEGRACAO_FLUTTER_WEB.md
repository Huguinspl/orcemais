# 🎨 Guia de Integração - Cores Personalizadas no Flutter Web (gestorfy-cliente)

## 📋 Visão Geral

Como o `gestorfy-cliente.web.app` também é Flutter, você pode **reutilizar o mesmo código** das páginas de Link Web que já criamos!

---

## 🔗 Como Funciona

### **1. App Gestorfy (Mobile/Desktop)**
```
Usuário personaliza cores → Salva no Firestore → Gera link com parâmetros
```

### **2. Deep Link / URL**
```
https://gestorfy-cliente.web.app/?
  userId=abc123&
  documentoId=xyz789&
  tipoDocumento=orcamento&
  corPrimaria=4280391909&
  corSecundaria=4293718525&
  ...
```

### **3. Gestorfy-Cliente (Flutter Web)**
```
Lê parâmetros da URL → Busca dados do Firestore → Aplica cores → Renderiza
```

---

## 🛠️ Implementação no gestorfy-cliente

### **Passo 1: Ler Parâmetros da URL**

Crie um arquivo `lib/utils/url_params_helper.dart`:

```dart
import 'dart:html' as html;
import 'package:flutter/material.dart';

class UrlParamsHelper {
  /// Obtém todos os parâmetros da URL atual
  static Map<String, String> obterParametros() {
    final uri = Uri.parse(html.window.location.href);
    return uri.queryParameters;
  }

  /// Obtém as cores personalizadas da URL
  static Map<String, int>? obterCoresPersonalizadas() {
    final params = obterParametros();
    
    if (params['corPrimaria'] == null) {
      return null; // Sem personalização
    }

    return {
      'primary': int.tryParse(params['corPrimaria'] ?? '') ?? 0,
      'secondaryContainer': int.tryParse(params['corSecundaria'] ?? '') ?? 0,
      'tertiaryContainer': int.tryParse(params['corTerciaria'] ?? '') ?? 0,
      'onSecondaryContainer': int.tryParse(params['corTextoSecundario'] ?? '') ?? 0,
      'onTertiaryContainer': int.tryParse(params['corTextoTerciario'] ?? '') ?? 0,
    };
  }

  /// Obtém as cores em formato Color do Flutter
  static Map<String, Color>? obterCoresComoColor() {
    final coresInt = obterCoresPersonalizadas();
    
    if (coresInt == null) return null;

    return {
      'primary': Color(coresInt['primary']!),
      'secondaryContainer': Color(coresInt['secondaryContainer']!),
      'tertiaryContainer': Color(coresInt['tertiaryContainer']!),
      'onSecondaryContainer': Color(coresInt['onSecondaryContainer']!),
      'onTertiaryContainer': Color(coresInt['onTertiaryContainer']!),
    };
  }

  /// Obtém informações do documento
  static String? get userId => obterParametros()['userId'];
  static String? get documentoId => obterParametros()['documentoId'];
  static String? get tipoDocumento => obterParametros()['tipoDocumento'];
}
```

---

### **Passo 2: Criar Página de Visualização**

Crie `lib/pages/visualizar_orcamento_page.dart`:

```dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/url_params_helper.dart';
import '../models/orcamento.dart';
import '../models/business_info.dart';

class VisualizarOrcamentoPage extends StatefulWidget {
  const VisualizarOrcamentoPage({super.key});

  @override
  State<VisualizarOrcamentoPage> createState() => _VisualizarOrcamentoPageState();
}

class _VisualizarOrcamentoPageState extends State<VisualizarOrcamentoPage> {
  bool _carregando = true;
  String? _erro;
  Orcamento? _orcamento;
  BusinessInfo? _businessInfo;
  Map<String, Color>? _coresPersonalizadas;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      // 1. Obter parâmetros da URL
      final userId = UrlParamsHelper.userId;
      final documentoId = UrlParamsHelper.documentoId;
      
      if (userId == null || documentoId == null) {
        throw Exception('Parâmetros inválidos na URL');
      }

      // 2. Obter cores personalizadas
      _coresPersonalizadas = UrlParamsHelper.obterCoresComoColor();

      // 3. Buscar orçamento no Firestore
      final orcamentoDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('orcamentos')
          .doc(documentoId)
          .get();

      if (!orcamentoDoc.exists) {
        throw Exception('Orçamento não encontrado');
      }

      _orcamento = Orcamento.fromFirestore(orcamentoDoc);

      // 4. Buscar informações do negócio
      final businessDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('business')
          .doc('info')
          .get();

      if (businessDoc.exists) {
        _businessInfo = BusinessInfo.fromFirestore(businessDoc);
      }

      setState(() {
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = e.toString();
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_erro != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erro ao carregar orçamento', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text(_erro!, style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // Cores (personalizadas ou padrão)
    final primaryColor = _coresPersonalizadas?['primary'] ?? Colors.blue.shade600;
    final secondaryContainerColor = _coresPersonalizadas?['secondaryContainer'] ?? Colors.blue.shade50;
    final tertiaryContainerColor = _coresPersonalizadas?['tertiaryContainer'] ?? Colors.blue.shade100;
    final onSecondaryContainerColor = _coresPersonalizadas?['onSecondaryContainer'] ?? Colors.blue.shade900;
    final onTertiaryContainerColor = _coresPersonalizadas?['onTertiaryContainer'] ?? Colors.blue.shade900;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho com cores personalizadas
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildHeader(_businessInfo),
              ),
              
              const Divider(height: 40, thickness: 1),
              
              _sectionLabel(
                'Dados do Cliente',
                bg: secondaryContainerColor,
                fg: onSecondaryContainerColor,
              ),
              const SizedBox(height: 12),
              _buildClientInfo(_orcamento!),
              
              const SizedBox(height: 24),
              
              _sectionLabel(
                'Itens do Orçamento',
                bg: tertiaryContainerColor,
                fg: onTertiaryContainerColor,
              ),
              const SizedBox(height: 16),
              _buildItemsList(_orcamento!, primaryColor),
              
              const SizedBox(height: 24),
              
              Container(
                decoration: BoxDecoration(
                  color: secondaryContainerColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                padding: const EdgeInsets.all(16),
                child: _buildTotals(_orcamento!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BusinessInfo? info) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info?.logoUrl != null && info!.logoUrl!.isNotEmpty)
          Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.only(right: 12),
            child: Image.network(info.logoUrl!, fit: BoxFit.contain),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info?.nomeEmpresa ?? 'Minha Empresa',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              if (info?.telefone != null && info!.telefone.isNotEmpty)
                _buildInfoLinha(Icons.phone_outlined, info.telefone),
              if (info?.emailEmpresa != null && info!.emailEmpresa.isNotEmpty)
                _buildInfoLinha(Icons.email_outlined, info.emailEmpresa),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoLinha(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfo(Orcamento orcamento) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cliente:',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          orcamento.cliente.nome,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        if (orcamento.cliente.celular.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(orcamento.cliente.celular),
        ],
        if (orcamento.cliente.email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(orcamento.cliente.email),
        ],
      ],
    );
  }

  Widget _buildItemsList(Orcamento orcamento, Color primaryColor) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Column(
      children: List.generate(orcamento.itens.length, (index) {
        final item = orcamento.itens[index];
        final nome = item['nome'] ?? 'Item';
        final descricao = item['descricao'] as String? ?? '';
        final preco = (item['preco'] ?? 0).toDouble();
        final quantidade = (item['quantidade'] ?? 1).toDouble();
        final totalItem = preco * quantidade;

        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.2), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.1),
                          primaryColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            nome,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (descricao.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.description_outlined, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  descricao,
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total do Item', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                            Text(currencyFormat.format(totalItem), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (index < orcamento.itens.length - 1) const SizedBox(height: 16),
          ],
        );
      }),
    );
  }

  Widget _buildTotals(Orcamento orcamento) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _totalRow('Subtotal', currencyFormat.format(orcamento.subtotal)),
            if (orcamento.desconto > 0)
              _totalRow('Desconto', '- ${currencyFormat.format(orcamento.desconto)}'),
            const Divider(height: 20),
            _totalRow('Valor Total', currencyFormat.format(orcamento.valorTotal), isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, {required Color bg, required Color fg}) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool isTotal = false}) {
    final style = TextStyle(
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      fontSize: isTotal ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
```

---

### **Passo 3: Configurar Roteamento**

No `main.dart` do `gestorfy-cliente`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/visualizar_orcamento_page.dart';
import 'pages/visualizar_recibo_page.dart';
import 'utils/url_params_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Determinar qual página mostrar baseado nos parâmetros
    final tipoDocumento = UrlParamsHelper.tipoDocumento;
    
    Widget home;
    if (tipoDocumento == 'recibo') {
      home = const VisualizarReciboPage();
    } else {
      home = const VisualizarOrcamentoPage();
    }

    return MaterialApp(
      title: 'Gestorfy Cliente',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: home,
    );
  }
}
```

---

## ✅ Vantagens desta Abordagem

1. ✅ **Reutilização total** do código Flutter
2. ✅ **Visual idêntico** ao preview do app
3. ✅ **Menos manutenção** - um código só
4. ✅ **Cores automáticas** da URL
5. ✅ **Suporte a orçamentos e recibos**

---

## 🧪 Teste

1. Deploy do `gestorfy-cliente` no Firebase Hosting
2. Compartilhe um orçamento do app `gestorfy`
3. Abra o link gerado
4. As cores devem aparecer automaticamente!

---

## 📦 Dependências Necessárias

No `pubspec.yaml` do `gestorfy-cliente`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.0
  cloud_firestore: ^4.14.0
  intl: ^0.18.0
```

---

## 🚀 Pronto!

Agora você tem:
- ✅ Leitura automática de cores da URL
- ✅ Busca de dados no Firestore
- ✅ Renderização com cores personalizadas
- ✅ Layout moderno e responsivo

**Alguma dúvida sobre a implementação?** 😊
