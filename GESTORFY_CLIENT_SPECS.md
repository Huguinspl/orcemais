# 📋 Gestorfy Client - Especificações do Projeto

## 🎯 Objetivo
Criar um aplicativo Flutter Web independente para que **clientes** possam visualizar orçamentos enviados pelo sistema Gestorfy (app de gestão).

---

## 🏗️ Arquitetura

### Estrutura de Diretórios Recomendada
```
📦 gestorfy-client/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── orcamento.dart
│   │   ├── cliente.dart
│   │   ├── business_info.dart
│   │   └── assinatura_info.dart
│   ├── pages/
│   │   ├── visualizar_orcamento_page.dart
│   │   ├── erro_page.dart
│   │   └── splash_page.dart
│   ├── services/
│   │   └── firestore_service.dart
│   ├── widgets/
│   │   ├── orcamento_card.dart
│   │   ├── item_card.dart
│   │   ├── business_header.dart
│   │   └── loading_widget.dart
│   └── utils/
│       ├── formatters.dart
│       └── constants.dart
├── web/
│   ├── index.html
│   ├── manifest.json
│   └── favicon.png
├── assets/
│   └── logo_placeholder.png
├── pubspec.yaml
└── README.md
```

---

## 🔥 Firebase

### Configuração
- **Projeto Firebase**: `gestorfy-app`
- **Project ID**: `gestorfy-app`
- **Storage Bucket**: `gestorfy-app.firebasestorage.app`

### Credenciais Web
```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyB6XnB5jv9loZf6mTTYghFPIcIDNnW7g3o',
  appId: '1:388082198829:web:080b0e26e2b1a3fd76cba4',
  messagingSenderId: '388082198829',
  projectId: 'gestorfy-app',
  authDomain: 'gestorfy-app.firebaseapp.com',
  storageBucket: 'gestorfy-app.firebasestorage.app',
);
```

### Estrutura do Firestore

#### Coleção: `users/{userId}/business`
Documento único com informações do negócio:
```json
{
  "nomeEmpresa": "string",
  "telefone": "string",
  "ramo": "string",
  "endereco": "string",
  "cnpj": "string",
  "emailEmpresa": "string",
  "logoUrl": "string (opcional)",
  "pixTipo": "string (opcional) - cpf, cnpj, email, celular, aleatoria",
  "pixChave": "string (opcional)",
  "assinaturaUrl": "string (opcional)",
  "descricao": "string (opcional)",
  "pdfTheme": "map (opcional) - cores personalizadas"
}
```

#### Coleção: `users/{userId}/orcamentos`
Documentos de orçamentos:
```json
{
  "id": "string (doc.id)",
  "numero": "int - número sequencial do orçamento",
  "status": "string - Aberto, Enviado, Aprovado, Recusado, Cancelado",
  "dataCriacao": "Timestamp",
  "cliente": {
    "id": "string",
    "nome": "string",
    "celular": "string",
    "telefone": "string",
    "email": "string",
    "cpfCnpj": "string",
    "observacoes": "string"
  },
  "itens": [
    {
      "tipo": "string - servico ou peca",
      "nome": "string",
      "descricao": "string (opcional)",
      "quantidade": "number",
      "preco": "number",
      "custo": "number (opcional)",
      "unidade": "string (opcional) - unidade, hora, m², etc",
      "marca": "string (opcional)",
      "modelo": "string (opcional)",
      "codigoBarras": "string (opcional)"
    }
  ],
  "subtotal": "number",
  "desconto": "number",
  "valorTotal": "number",
  "metodoPagamento": "string (opcional) - dinheiro, pix, debito, credito, boleto",
  "parcelas": "int (opcional) - quando crédito",
  "laudoTecnico": "string (opcional)",
  "condicoesContratuais": "string (opcional)",
  "garantia": "string (opcional)",
  "informacoesAdicionais": "string (opcional)",
  "fotos": ["array de URLs (opcional)"]
}
```

### Regras de Segurança Firestore
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir leitura pública de orçamentos ENVIADOS
    match /users/{userId}/orcamentos/{orcamentoId} {
      allow read: if resource.data.status == 'Enviado';
    }
    
    // Permitir leitura pública de dados do negócio
    match /users/{userId}/business {
      allow read: if true;
    }
  }
}
```

### Regras de Storage (para logos e fotos)
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read: if true; // Leitura pública para logos e fotos
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 📦 Modelos de Dados (Dart)

### 1. Orcamento
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cliente.dart';

class Orcamento {
  final String id;
  final int numero;
  final Cliente cliente;
  final List<Map<String, dynamic>> itens;
  final double subtotal;
  final double desconto;
  final double valorTotal;
  final String status;
  final Timestamp dataCriacao;
  final String? metodoPagamento;
  final int? parcelas;
  final String? laudoTecnico;
  final String? condicoesContratuais;
  final String? garantia;
  final String? informacoesAdicionais;
  final List<String>? fotos;

  Orcamento({
    required this.id,
    this.numero = 0,
    required this.cliente,
    required this.itens,
    required this.subtotal,
    required this.desconto,
    required this.valorTotal,
    required this.status,
    required this.dataCriacao,
    this.metodoPagamento,
    this.parcelas,
    this.laudoTecnico,
    this.condicoesContratuais,
    this.garantia,
    this.informacoesAdicionais,
    this.fotos,
  });

  factory Orcamento.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Orcamento(
      id: doc.id,
      numero: data['numero'] ?? 0,
      cliente: Cliente.fromMap(data['cliente'] ?? {}),
      itens: List<Map<String, dynamic>>.from(data['itens'] ?? []),
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      desconto: (data['desconto'] ?? 0.0).toDouble(),
      valorTotal: (data['valorTotal'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'Aberto',
      dataCriacao: data['dataCriacao'] ?? Timestamp.now(),
      metodoPagamento: data['metodoPagamento'],
      parcelas: data['parcelas'],
      laudoTecnico: data['laudoTecnico'],
      condicoesContratuais: data['condicoesContratuais'],
      garantia: data['garantia'],
      informacoesAdicionais: data['informacoesAdicionais'],
      fotos: data['fotos'] != null ? List<String>.from(data['fotos']) : null,
    );
  }
}
```

### 2. Cliente
```dart
class Cliente {
  final String id;
  final String nome;
  final String celular;
  final String telefone;
  final String email;
  final String cpfCnpj;
  final String observacoes;

  Cliente({
    this.id = '',
    required this.nome,
    this.celular = '',
    this.telefone = '',
    this.email = '',
    this.cpfCnpj = '',
    this.observacoes = '',
  });

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      celular: map['celular'] ?? '',
      telefone: map['telefone'] ?? '',
      email: map['email'] ?? '',
      cpfCnpj: map['cpfCnpj'] ?? '',
      observacoes: map['observacoes'] ?? '',
    );
  }
}
```

### 3. BusinessInfo
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessInfo {
  final String nomeEmpresa;
  final String telefone;
  final String ramo;
  final String endereco;
  final String cnpj;
  final String emailEmpresa;
  final String? logoUrl;
  final String? pixTipo;
  final String? pixChave;
  final String? assinaturaUrl;
  final String? descricao;
  final Map<String, dynamic>? pdfTheme;

  const BusinessInfo({
    required this.nomeEmpresa,
    required this.telefone,
    required this.ramo,
    required this.endereco,
    required this.cnpj,
    required this.emailEmpresa,
    this.logoUrl,
    this.pixTipo,
    this.pixChave,
    this.assinaturaUrl,
    this.descricao,
    this.pdfTheme,
  });

  factory BusinessInfo.fromMap(Map<String, dynamic> map) => BusinessInfo(
    nomeEmpresa: map['nomeEmpresa'] ?? '',
    telefone: map['telefone'] ?? '',
    ramo: map['ramo'] ?? '',
    endereco: map['endereco'] ?? '',
    cnpj: map['cnpj'] ?? '',
    emailEmpresa: map['emailEmpresa'] ?? '',
    logoUrl: map['logoUrl'],
    pixTipo: map['pixTipo'],
    pixChave: map['pixChave'],
    assinaturaUrl: map['assinaturaUrl'],
    descricao: map['descricao'],
    pdfTheme: map['pdfTheme'] as Map<String, dynamic>?,
  );

  factory BusinessInfo.fromDoc(DocumentSnapshot doc) =>
      BusinessInfo.fromMap(doc.data() as Map<String, dynamic>);
}
```

### 4. AssinaturaInfo
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AssinaturaInfo {
  final String? url;
  final DateTime? data;

  AssinaturaInfo({this.url, this.data});

  factory AssinaturaInfo.fromMap(Map<String, dynamic> map) => AssinaturaInfo(
    url: map['url'],
    data: map['data'] != null
        ? (map['data'] is Timestamp
            ? (map['data'] as Timestamp).toDate()
            : DateTime.tryParse(map['data'].toString()))
        : null,
  );
}
```

---

## 🔗 Sistema de URLs

### Formato de URL
```
https://orcamentos.gestorfy.com/view?u={userId}&o={orcamentoId}
```

**Parâmetros:**
- `u` (userId): ID do usuário/negócio no Firebase Auth
- `o` (orcamentoId): ID do documento do orçamento

**Exemplo:**
```
https://orcamentos.gestorfy.com/view?u=ABC123XYZ&o=orcamento456
```

### Geração de Links (no app principal)
```dart
String gerarLinkOrcamento(String userId, String orcamentoId) {
  final baseUrl = 'https://orcamentos.gestorfy.com/view';
  return '$baseUrl?u=$userId&o=$orcamentoId';
}
```

---

## 🎨 Design e UX

### Paleta de Cores (Padrão)
- **Primary**: `#2196F3` (Azul)
- **Secondary**: `#FF9800` (Laranja)
- **Success**: `#4CAF50` (Verde)
- **Error**: `#F44336` (Vermelho)
- **Background**: `#F5F5F5` (Cinza claro)

### Responsividade
- **Mobile**: < 600px
- **Tablet**: 600px - 1024px
- **Desktop**: > 1024px

### Funcionalidades da UI

#### Cabeçalho do Negócio
- Logo da empresa (se disponível)
- Nome da empresa
- Telefone e email
- Endereço (opcional)

#### Card do Orçamento
- Número do orçamento: `#0001`, `#0002`, etc.
- Data de criação
- Status visual (badge colorido)

#### Informações do Cliente
- Nome completo
- Telefone(s) de contato
- Email
- CPF/CNPJ (se informado)

#### Lista de Itens
Para cada item exibir:
- Nome do item
- Descrição (se houver)
- Quantidade
- Preço unitário
- Subtotal do item
- Tipo: Serviço 🔧 ou Produto 📦

#### Resumo Financeiro
- Subtotal dos itens
- Desconto (se aplicado)
- **Valor Total** (destaque)

#### Informações de Pagamento
- Método de pagamento (se informado)
- Parcelamento (se crédito)
- Dados do PIX (se disponível):
  - Tipo de chave
  - Chave PIX

#### Seções Adicionais (se preenchidas)
- Laudo técnico
- Condições contratuais
- Garantia
- Informações adicionais
- Galeria de fotos

#### Rodapé
- Assinatura digital (se disponível)
- Data de emissão
- Informações de contato da empresa

---

## 📱 Fluxo de Navegação

```
1. Cliente clica no link recebido
   ↓
2. App carrega e extrai parâmetros da URL (userId, orcamentoId)
   ↓
3. Exibe splash/loading
   ↓
4. Busca dados do orçamento no Firestore
   ↓
5. Busca dados do negócio (logo, contatos, etc)
   ↓
6. Valida se orçamento tem status "Enviado"
   ↓
7a. [Sucesso] Exibe página completa do orçamento
7b. [Erro] Exibe página de erro apropriada:
    - Orçamento não encontrado
    - Orçamento não disponível (status diferente de "Enviado")
    - Erro de conexão
```

---

## 🔒 Segurança

### Regras de Acesso
1. **Apenas orçamentos com status "Enviado"** podem ser visualizados
2. Não há autenticação de usuário (acesso público via link)
3. Nenhuma operação de escrita é permitida
4. Firebase Security Rules garantem acesso apenas a documentos com status correto

### Proteção de Dados
- Não armazenar dados sensíveis no client-side
- Todas as imagens/logos vêm do Firebase Storage com URLs públicas
- Links não expiram (considerar implementar expiração futura)

---

## 📦 Dependências Necessárias

### pubspec.yaml
```yaml
name: gestorfy_client
description: "Visualizador de orçamentos para clientes Gestorfy"
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ^3.7.0

dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^4.0.0
  cloud_firestore: ^6.0.0
  
  # UI/UX
  cupertino_icons: ^1.0.8
  intl: ^0.20.2              # Formatação de datas e moedas
  cached_network_image: ^3.4.2  # Cache de imagens
  flutter_spinkit: ^5.2.1    # Loading animations
  
  # Utilities
  url_launcher: ^6.3.2        # Abrir links externos (WhatsApp, email)
  share_plus: ^11.0.0         # Compartilhar orçamento
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

---

## 🚀 Deploy

### Opções de Hospedagem

#### 1. Firebase Hosting (Recomendado)
```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Inicializar projeto
firebase init hosting

# Build Flutter Web
flutter build web --release

# Deploy
firebase deploy --only hosting
```

#### 2. Vercel
```bash
# Instalar Vercel CLI
npm install -g vercel

# Build
flutter build web --release

# Deploy
vercel --prod
```

#### 3. Netlify
- Conectar repositório GitHub
- Build command: `flutter build web --release`
- Publish directory: `build/web`

---

## 🧪 Testes

### Cenários de Teste

1. **Orçamento válido (status Enviado)**
   - URL: `/view?u=userId&o=orcamentoId`
   - Resultado esperado: Exibição completa

2. **Orçamento com status diferente de Enviado**
   - Resultado esperado: Erro "Orçamento não disponível"

3. **IDs inválidos**
   - Resultado esperado: Erro "Orçamento não encontrado"

4. **Sem conexão internet**
   - Resultado esperado: Erro de conexão

5. **Responsive Design**
   - Testar em mobile, tablet e desktop
   - Verificar scroll e layout

6. **Galeria de fotos**
   - Com 0, 1, ou múltiplas fotos
   - Zoom e navegação

---

## 📊 Analytics (Opcional - Futuro)

Considerar implementar:
- Google Analytics 4
- Métricas:
  - Visualizações de orçamento
  - Tempo médio de visualização
  - Taxa de bounce
  - Dispositivos mais usados

---

## 🔄 Sincronização com App Principal

### Quando atualizar o app cliente:

1. **Mudanças no modelo Orcamento**
   - Adicionar/remover campos
   - Alterar tipos de dados

2. **Mudanças no modelo Cliente**

3. **Mudanças no modelo BusinessInfo**

4. **Mudanças nas regras de negócio**
   - Novos status de orçamento
   - Novas formas de pagamento

5. **Estrutura do Firestore**
   - Novas coleções relacionadas
   - Alteração de paths

### Versionamento
- Manter versões sincronizadas
- Documentar breaking changes
- Considerar criar uma API REST futuramente para desacoplar

---

## 🎯 Roadmap Futuro

### Fase 1 (MVP)
- [x] Visualização básica do orçamento
- [x] Dados do negócio
- [x] Lista de itens
- [x] Informações de pagamento
- [x] Design responsivo

### Fase 2
- [ ] Aprovação/Recusa de orçamento pelo cliente
- [ ] Sistema de comentários/observações
- [ ] Notificações via email
- [ ] Histórico de interações

### Fase 3
- [ ] Assinatura digital do cliente
- [ ] Download de PDF
- [ ] Sistema de versionamento de orçamentos
- [ ] Chat em tempo real

### Fase 4
- [ ] Multi-idioma (i18n)
- [ ] Dark mode
- [ ] PWA (Progressive Web App)
- [ ] Offline support

---

## 📝 Notas Importantes

1. **Não implementar autenticação** no MVP - links públicos apenas
2. **Validar sempre o status** do orçamento no Firestore
3. **Carregar imagens de forma lazy** para performance
4. **Implementar error boundaries** para melhor UX
5. **Logs de acesso** podem ser úteis para analytics
6. **Considerar rate limiting** se houver abuso
7. **Manter código simples e focado** - é apenas visualização

---

## 👥 Contatos

**Desenvolvedor Principal**: Hugo  
**Projeto**: Gestorfy  
**Repositório Principal**: gestorfy  
**Repositório Cliente**: gestorfy-client (a ser criado)

---

## 📄 Licença

Proprietary - Uso interno apenas

---

**Última Atualização**: 08/11/2025  
**Versão do Documento**: 1.0  
**Status**: Pronto para desenvolvimento ✅
