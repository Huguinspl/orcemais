# 🔥 Instruções para Buscar Dados do Firestore no App Cliente

## 📋 Visão Geral

Este documento contém as instruções detalhadas para buscar os dados de **orçamento** e **negócio** no Firebase Firestore a partir do app web do cliente (`gestorfy-client`).

---

## 🎯 Objetivo

O app cliente receberá uma URL no formato:
```
https://orcamentos.gestorfy.com/view?u={userId}&o={orcamentoId}
```

Com esses parâmetros, o app deve:
1. Buscar os dados do **orçamento**
2. Buscar os dados do **negócio** (empresa)
3. Validar se o orçamento tem status "Enviado"
4. Exibir as informações para o cliente

---

## 📂 Estrutura do Firestore

### Hierarquia de Coleções

```
Firestore
└── users (coleção)
    └── {userId} (documento)
        ├── business (subcocoleção)
        │   └── info (documento único)
        └── orcamentos (subcoleção)
            └── {orcamentoId} (documento)
```

---

## 🔍 1. Buscar Dados do Orçamento

### Caminho Completo
```
users/{userId}/orcamentos/{orcamentoId}
```

### Exemplo de Código Dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<Map<String, dynamic>?> buscarOrcamento(String userId, String orcamentoId) async {
  try {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('orcamentos')
        .doc(orcamentoId);
    
    final docSnapshot = await docRef.get();
    
    if (!docSnapshot.exists) {
      print('❌ Orçamento não encontrado');
      return null;
    }
    
    final data = docSnapshot.data();
    
    // Validar se o status é "Enviado"
    if (data?['status'] != 'Enviado') {
      print('❌ Orçamento não está disponível (status: ${data?['status']})');
      return null;
    }
    
    print('✅ Orçamento encontrado: ${data?['numero']}');
    return data;
    
  } catch (e) {
    print('❌ Erro ao buscar orçamento: $e');
    return null;
  }
}
```

### Estrutura do Documento de Orçamento

```json
{
  "numero": 1,
  "status": "Enviado",
  "dataCriacao": Timestamp,
  "cliente": {
    "id": "string",
    "nome": "João Silva",
    "celular": "(11) 98765-4321",
    "telefone": "(11) 3456-7890",
    "email": "joao@email.com",
    "cpfCnpj": "123.456.789-00",
    "observacoes": "Cliente preferencial"
  },
  "itens": [
    {
      "tipo": "servico",
      "nome": "Manutenção de Ar Condicionado",
      "descricao": "Limpeza completa e carga de gás",
      "quantidade": 1,
      "preco": 250.00,
      "custo": 150.00,
      "unidade": "unidade"
    },
    {
      "tipo": "peca",
      "nome": "Filtro de Ar",
      "marca": "Komeco",
      "modelo": "F-123",
      "quantidade": 2,
      "preco": 45.00,
      "custo": 30.00
    }
  ],
  "subtotal": 340.00,
  "desconto": 40.00,
  "valorTotal": 300.00,
  "metodoPagamento": "pix",
  "parcelas": null,
  "laudoTecnico": "Equipamento apresentava baixa refrigeração...",
  "condicoesContratuais": "Garantia de 90 dias para serviços...",
  "garantia": "90 dias para mão de obra e 1 ano para peças",
  "informacoesAdicionais": "Recomendamos manutenção semestral",
  "fotos": [
    "https://firebasestorage.googleapis.com/v0/b/gestorfy-app.appspot.com/o/orcamentos%2Ffoto1.jpg?alt=media",
    "https://firebasestorage.googleapis.com/v0/b/gestorfy-app.appspot.com/o/orcamentos%2Ffoto2.jpg?alt=media"
  ]
}
```

### Campos Importantes do Orçamento

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `numero` | int | ✅ | Número sequencial do orçamento |
| `status` | string | ✅ | Status: "Aberto", "Enviado", "Aprovado", "Recusado", "Cancelado" |
| `dataCriacao` | Timestamp | ✅ | Data de criação do orçamento |
| `cliente` | Map | ✅ | Dados completos do cliente |
| `itens` | Array | ✅ | Lista de serviços/produtos |
| `subtotal` | double | ✅ | Soma dos itens sem desconto |
| `desconto` | double | ✅ | Valor do desconto aplicado |
| `valorTotal` | double | ✅ | Valor final a pagar |
| `metodoPagamento` | string? | ❌ | dinheiro, pix, debito, credito, boleto |
| `parcelas` | int? | ❌ | Número de parcelas (quando crédito) |
| `laudoTecnico` | string? | ❌ | Observações técnicas |
| `condicoesContratuais` | string? | ❌ | Termos e condições |
| `garantia` | string? | ❌ | Informações de garantia |
| `informacoesAdicionais` | string? | ❌ | Informações extras |
| `fotos` | Array? | ❌ | URLs das fotos do Firebase Storage |

### Validação do Status

**⚠️ IMPORTANTE**: Apenas orçamentos com `status == "Enviado"` devem ser exibidos!

```dart
if (data?['status'] != 'Enviado') {
  // Mostrar página de erro: "Este orçamento não está disponível"
  return;
}
```

---

## 🏢 2. Buscar Dados do Negócio

### Caminho Completo
```
users/{userId}/business/info
```

### Exemplo de Código Dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<Map<String, dynamic>?> buscarDadosNegocio(String userId) async {
  try {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('business')
        .doc('info');
    
    final docSnapshot = await docRef.get();
    
    if (!docSnapshot.exists) {
      print('❌ Dados do negócio não encontrados');
      return null;
    }
    
    final data = docSnapshot.data();
    print('✅ Negócio encontrado: ${data?['nomeEmpresa']}');
    return data;
    
  } catch (e) {
    print('❌ Erro ao buscar dados do negócio: $e');
    return null;
  }
}
```

### Estrutura do Documento de Negócio

```json
{
  "nomeEmpresa": "Minha Empresa LTDA",
  "telefone": "(11) 3456-7890",
  "ramo": "Assistência Técnica",
  "endereco": "Rua Exemplo, 123 - São Paulo, SP",
  "cnpj": "12.345.678/0001-90",
  "emailEmpresa": "contato@minhaempresa.com",
  "logoUrl": "https://firebasestorage.googleapis.com/v0/b/gestorfy-app.appspot.com/o/logos%2Flogo.png?alt=media",
  "pixTipo": "cnpj",
  "pixChave": "12.345.678/0001-90",
  "assinaturaUrl": "https://firebasestorage.googleapis.com/v0/b/gestorfy-app.appspot.com/o/assinaturas%2Fassinatura.png?alt=media",
  "descricao": "Empresa especializada em manutenção de ar condicionado",
  "pdfTheme": {
    "primaryColor": "#2196F3",
    "secondaryColor": "#FF9800"
  }
}
```

### Campos Importantes do Negócio

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `nomeEmpresa` | string | ✅ | Nome da empresa |
| `telefone` | string | ✅ | Telefone de contato |
| `ramo` | string | ✅ | Ramo de atividade |
| `endereco` | string | ✅ | Endereço completo |
| `cnpj` | string | ✅ | CNPJ da empresa |
| `emailEmpresa` | string | ✅ | Email de contato |
| `logoUrl` | string? | ❌ | URL do logo no Firebase Storage |
| `pixTipo` | string? | ❌ | Tipo: cpf, cnpj, email, celular, aleatoria |
| `pixChave` | string? | ❌ | Chave PIX para pagamento |
| `assinaturaUrl` | string? | ❌ | URL da assinatura digital |
| `descricao` | string? | ❌ | Descrição do negócio |
| `pdfTheme` | Map? | ❌ | Cores personalizadas para PDF |

---

## 🔒 Regras de Segurança do Firestore

Para que o app cliente consiga ler os dados **SEM AUTENTICAÇÃO**, as seguintes regras devem estar configuradas no Firebase:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir leitura pública de orçamentos com status "Enviado"
    match /users/{userId}/orcamentos/{orcamentoId} {
      allow read: if resource.data.status == 'Enviado';
    }
    
    // Permitir leitura pública dos dados do negócio
    match /users/{userId}/business/{document=**} {
      allow read: if true;
    }
  }
}
```

### ⚠️ Importante sobre as Regras

1. **Orçamentos**: Apenas orçamentos com `status == "Enviado"` podem ser lidos
2. **Negócio**: Dados do negócio são públicos (leitura livre)
3. **Escrita**: Nenhuma operação de escrita é permitida no app cliente

---

## 📝 Fluxo Completo de Implementação

### Passo 1: Extrair Parâmetros da URL

```dart
import 'dart:html' as html;

void initDeepLink() {
  final uri = Uri.parse(html.window.location.href);
  final userId = uri.queryParameters['u'];
  final orcamentoId = uri.queryParameters['o'];
  
  if (userId == null || orcamentoId == null) {
    // Mostrar erro: Parâmetros inválidos
    return;
  }
  
  carregarDados(userId, orcamentoId);
}
```

### Passo 2: Buscar Dados em Paralelo

```dart
Future<void> carregarDados(String userId, String orcamentoId) async {
  setState(() => _loading = true);
  
  try {
    // Buscar dados em paralelo para melhor performance
    final results = await Future.wait([
      buscarOrcamento(userId, orcamentoId),
      buscarDadosNegocio(userId),
    ]);
    
    final orcamento = results[0];
    final negocio = results[1];
    
    if (orcamento == null) {
      // Mostrar erro: Orçamento não encontrado ou não disponível
      setState(() => _erro = 'Orçamento não disponível');
      return;
    }
    
    if (negocio == null) {
      // Mostrar aviso: Dados da empresa não encontrados
      setState(() => _erro = 'Dados da empresa não encontrados');
      return;
    }
    
    // Sucesso! Exibir dados
    setState(() {
      _orcamento = orcamento;
      _negocio = negocio;
      _loading = false;
    });
    
  } catch (e) {
    setState(() {
      _erro = 'Erro ao carregar dados: $e';
      _loading = false;
    });
  }
}
```

### Passo 3: Validar e Exibir

```dart
@override
Widget build(BuildContext context) {
  if (_loading) {
    return Center(child: CircularProgressIndicator());
  }
  
  if (_erro != null) {
    return ErroPage(mensagem: _erro!);
  }
  
  return VisualizarOrcamentoPage(
    orcamento: _orcamento!,
    negocio: _negocio!,
  );
}
```

---

## 🎨 Exemplo de UI para Exibição

### Cabeçalho da Empresa

```dart
Widget buildCabecalhoEmpresa() {
  return Column(
    children: [
      if (negocio['logoUrl'] != null)
        CachedNetworkImage(
          imageUrl: negocio['logoUrl'],
          height: 80,
        ),
      const SizedBox(height: 16),
      Text(
        negocio['nomeEmpresa'],
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      Text('${negocio['telefone']} • ${negocio['emailEmpresa']}'),
      if (negocio['endereco'] != null)
        Text(negocio['endereco'], style: TextStyle(fontSize: 12)),
    ],
  );
}
```

### Card do Orçamento

```dart
Widget buildCardOrcamento() {
  final numero = orcamento['numero'];
  final numeroFormatado = '#${numero.toString().padLeft(4, '0')}';
  
  return Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Orçamento $numeroFormatado'),
              _buildStatusBadge(orcamento['status']),
            ],
          ),
          const SizedBox(height: 8),
          Text('Data: ${_formatarData(orcamento['dataCriacao'])}'),
        ],
      ),
    ),
  );
}
```

### Lista de Itens

```dart
Widget buildListaItens() {
  final itens = List<Map<String, dynamic>>.from(orcamento['itens']);
  
  return ListView.builder(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    itemCount: itens.length,
    itemBuilder: (context, index) {
      final item = itens[index];
      final preco = item['preco'] as num;
      final qtd = item['quantidade'] as num;
      final total = preco * qtd;
      
      return Card(
        child: ListTile(
          leading: Icon(
            item['tipo'] == 'servico' 
                ? Icons.build 
                : Icons.shopping_bag,
          ),
          title: Text(item['nome']),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item['descricao'] != null)
                Text(item['descricao']),
              Text('Qtd: $qtd × R\$ ${preco.toStringAsFixed(2)}'),
            ],
          ),
          trailing: Text(
            'R\$ ${total.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    },
  );
}
```

### Resumo Financeiro

```dart
Widget buildResumoFinanceiro() {
  final subtotal = orcamento['subtotal'] as num;
  final desconto = orcamento['desconto'] as num;
  final total = orcamento['valorTotal'] as num;
  
  return Card(
    color: Colors.green[50],
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildLinhaValor('Subtotal', subtotal),
          if (desconto > 0)
            _buildLinhaValor('Desconto', desconto, isNegative: true),
          Divider(),
          _buildLinhaValor(
            'TOTAL', 
            total, 
            isBold: true,
            fontSize: 20,
          ),
        ],
      ),
    ),
  );
}

Widget _buildLinhaValor(
  String label, 
  num valor, 
  {bool isNegative = false, bool isBold = false, double? fontSize}
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: fontSize,
        ),
      ),
      Text(
        '${isNegative ? '- ' : ''}R\$ ${valor.toStringAsFixed(2)}',
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: fontSize,
          color: isNegative ? Colors.red : null,
        ),
      ),
    ],
  );
}
```

### Informações de Pagamento

```dart
Widget buildInformacoesPagamento() {
  final metodoPagamento = orcamento['metodoPagamento'];
  final parcelas = orcamento['parcelas'];
  
  if (metodoPagamento == null) return SizedBox.shrink();
  
  return Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Forma de Pagamento',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(_getNomePagamento(metodoPagamento)),
          if (metodoPagamento == 'credito' && parcelas != null)
            Text('Em $parcelas× sem juros'),
          
          // Se tiver PIX, exibir chave
          if (metodoPagamento == 'pix' && negocio['pixChave'] != null) ...[
            const SizedBox(height: 16),
            Text(
              'Chave PIX',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            SelectableText(negocio['pixChave']),
            Text(
              'Tipo: ${negocio['pixTipo']}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    ),
  );
}

String _getNomePagamento(String metodo) {
  const nomes = {
    'dinheiro': '💵 Dinheiro',
    'pix': '🔑 PIX',
    'debito': '💳 Débito',
    'credito': '💳 Crédito',
    'boleto': '📄 Boleto',
  };
  return nomes[metodo] ?? metodo;
}
```

---

## 🚨 Tratamento de Erros

### Erros Comuns e Soluções

| Erro | Causa | Solução |
|------|-------|---------|
| **Orçamento não encontrado** | userId ou orcamentoId inválido | Mostrar página de erro amigável |
| **Status diferente de "Enviado"** | Orçamento ainda não foi enviado | Informar que orçamento não está disponível |
| **Permissão negada** | Regras de segurança incorretas | Verificar Firebase Security Rules |
| **Dados do negócio vazios** | Empresa não preencheu os dados | Exibir com dados limitados ou erro |
| **Timeout** | Problemas de conexão | Implementar retry ou mensagem de erro |

### Exemplo de Página de Erro

```dart
class ErroPage extends StatelessWidget {
  final String mensagem;
  
  const ErroPage({required this.mensagem});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                'Ops! Algo deu errado',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                mensagem,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => html.window.location.reload(),
                child: Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 📱 Responsividade

### Breakpoints Recomendados

```dart
class Breakpoints {
  static const mobile = 600.0;
  static const tablet = 1024.0;
  
  static bool isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width < mobile;
  
  static bool isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width >= mobile && 
      MediaQuery.of(context).size.width < tablet;
  
  static bool isDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width >= tablet;
}
```

### Layout Responsivo

```dart
Widget buildLayoutResponsivo() {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 600) {
        // Layout Mobile
        return Column(children: [...]);
      } else if (constraints.maxWidth < 1024) {
        // Layout Tablet
        return Row(children: [
          Expanded(flex: 2, child: ...),
          Expanded(flex: 1, child: ...),
        ]);
      } else {
        // Layout Desktop
        return Container(
          constraints: BoxConstraints(maxWidth: 1200),
          child: Row(children: [...]),
        );
      }
    },
  );
}
```

---

## ✅ Checklist de Implementação

- [ ] Configurar Firebase (firebase_core, cloud_firestore)
- [ ] Implementar função `buscarOrcamento()`
- [ ] Implementar função `buscarDadosNegocio()`
- [ ] Extrair parâmetros da URL (`u` e `o`)
- [ ] Validar status do orçamento == "Enviado"
- [ ] Criar página de loading
- [ ] Criar página de erro
- [ ] Criar UI para exibir cabeçalho da empresa
- [ ] Criar UI para exibir card do orçamento
- [ ] Criar UI para exibir lista de itens
- [ ] Criar UI para exibir resumo financeiro
- [ ] Criar UI para exibir informações de pagamento
- [ ] Implementar seções opcionais (laudo, garantia, fotos)
- [ ] Tornar layout responsivo (mobile, tablet, desktop)
- [ ] Testar em diferentes dispositivos
- [ ] Implementar tratamento de erros
- [ ] Adicionar analytics (opcional)

---

## 🔗 Links Úteis

- **Firebase Firestore Docs**: https://firebase.google.com/docs/firestore
- **Flutter Firebase**: https://firebase.flutter.dev/
- **Security Rules**: https://firebase.google.com/docs/firestore/security/get-started

---

## 📞 Suporte

Em caso de dúvidas ou problemas:
1. Verifique se as regras de segurança do Firestore estão corretas
2. Confirme que os parâmetros `u` e `o` estão na URL
3. Valide se o orçamento tem status "Enviado"
4. Verifique os logs de erro no console do navegador

---

**Última Atualização**: 08/11/2025  
**Versão**: 1.0  
**Status**: ✅ Pronto para implementação
