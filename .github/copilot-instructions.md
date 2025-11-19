# Copilot Instructions for Gestorfy

## Arquitetura e Estrutura

### Sistema Multi-Projeto
**Gestorfy** é dividido em dois projetos Flutter:
1. **`gestorfy/`** - App principal (mobile/desktop/web) para gestores criarem orçamentos, recibos, agendamentos
2. **`gestorfy_cliente/`** - App web simplificado para clientes visualizarem orçamentos compartilhados via deep link

### Organização Principal (`gestorfy/`)
```
lib/
├── models/          # Dados: Orcamento, Cliente, Recibo, Agendamento, etc
├── providers/       # Estado global com ChangeNotifier (12+ providers)
├── pages/           # UI organizadas por feature (home/orcamentos/, home/recibos/)
├── services/        # FirestoreService, NotificationService, TutorialService
├── routes/          # AppRoutes com constantes de rotas
├── widgets/         # Componentes reutilizáveis
├── conditional_desktop.dart  # Lógica de janela Windows (conditional import)
└── stub_desktop.dart         # Stub vazio para web
```

### Firebase como Backend
- **Firestore:** Estrutura hierárquica `users/{uid}`, `business/{uid}/orcamentos/{id}`
- **Auth:** Login/cadastro com Firebase Authentication
- **Storage:** Upload de logos e assinaturas em `logos/{uid}/...`
- **App Check:** Web usa reCAPTCHA (variável de ambiente `APP_CHECK_WEB_RECAPTCHA_KEY`)
- **Regras:** Usuário só acessa seus próprios dados (`isOwner(userId)` em `firestore.rules`)

## Padrões Críticos de Desenvolvimento

### Gerenciamento de Estado com Provider
**Sempre use `context.read<>()` para ações e `context.watch<>()` para reatividade:**
```dart
// ❌ Evitar em callbacks assíncronos
final user = context.watch<UserProvider>(); 
await someAsyncTask();
user.update(); // context pode estar desmontado

// ✅ Correto: capturar antes de async
final userProv = context.read<UserProvider>();
await someAsyncTask();
userProv.updateDados(nome, email, cpf);
```

**Providers principais:**
- `UserProvider` - dados do usuário autenticado, expõe `.uid`
- `BusinessProvider` - logo, nome empresa, cores personalizadas (`pdfTheme`)
- `OrcamentosProvider` - lista de orçamentos, usa transação para numeração sequencial
- `ClientsProvider`, `AgendamentosProvider`, `RecibosProvider` - coleções similares

### Fluxo de Persistência Firestore
1. Usuário edita dados na UI
2. Provider recebe alteração via método `atualizar*()`
3. Provider atualiza Firestore **E** notifica listeners (`notifyListeners()`)
4. UI reage automaticamente via `context.watch<>()`

**Exemplo de atualização atômica (orçamentos):**
```dart
// OrcamentosProvider usa runTransaction para garantir número único
await _firestore.runTransaction((transaction) async {
  final novoNumero = (ultimoNumero ?? 0) + 1;
  transaction.set(docRef, orcamento.toMap());
  transaction.update(_businessDocRef, {'ultimoOrcamentoNum': novoNumero});
});
```

### Upload de Imagens (Padrão Storage)
```dart
// 1. Selecionar com image_picker
final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

// 2. Upload para Firebase Storage
final ref = FirebaseStorage.instance.ref().child('logos/${uid}/logo.png');
await ref.putFile(File(pickedFile.path));
final url = await ref.getDownloadURL();

// 3. Salvar URL no Firestore via Provider
businessProvider.atualizarLogo(url);
```

### Deep Links e Compartilhamento
**Pacote personalizado:** `deep_link` (fork do GitHub `REU8ER/deep-link`)
- Usado para gerar links curtos (`link.orcemais.com`) que redirecionam para `gestorfy-cliente.web.app`
- **Parâmetros na URL:** `userId`, `documentoId`, `tipoDocumento` + cores personalizadas (`corPrimaria`, etc)
- Implementado em `compartilhar_orcamento.dart` e `compartilhar_recibo_page.dart`
- Deep link inicializado em `main.dart` com `DeepLink.init()`

### Geração de PDFs
- Usa pacote `pdf` e `printing`
- Busca logomarca via HTTP da URL no Firebase Storage
- Cores personalizadas vêm de `BusinessProvider.pdfTheme` (Map com `primary`, `secondary`, etc)
- Tratamento defensivo: sempre verificar se URLs e dados existem antes de renderizar

### Sistema de Notificações Locais
- **Service:** `NotificationService` (singleton) com `flutter_local_notifications`
- **Timezone:** `America/Sao_Paulo` configurado em `main.dart`
- **Fluxo:** Ao criar agendamento confirmado, agenda notificação 30min antes
- **Permissões:** Android 13+ requer `requestNotificationsPermission()`, solicitado via botão 🔔 na home
- **Cancelamento:** Notificações são canceladas ao excluir agendamento ou mudar status

### Plataformas e Builds

**Desenvolvimento:**
```powershell
flutter run -d windows    # Desktop (pode ter erro de .pdb, use Android)
flutter run -d chrome     # Web (PDF não funciona completamente)
flutter run -d <device>   # Android/iOS (recomendado para testar PDF)
```

**Produção Web:**
```powershell
flutter clean
flutter build web --release --web-renderer html
firebase deploy --only hosting -m "Versão X.X.X"
```

**Troubleshooting Windows:** Se erro `C1041` (.pdb), delete `build/windows/` ou use Android

### Rotas e Navegação
- Rotas nomeadas em `AppRoutes` (`lib/routes/app_routes.dart`)
- Navegação via `Navigator.pushNamed(context, AppRoutes.novoOrcamento)`
- Passos multi-etapa (ex: novo orçamento) usam rotas aninhadas

## Documentação Especializada

Consulte os seguintes arquivos `.md` na raiz para detalhes específicos:
- **GUIA_BUILD_DEPLOY.md** - Comandos de build por plataforma e deploy Firebase
- **PASSO_A_PASSO_DEEP_LINK.md** - Como deep links funcionam e estrutura de parâmetros
- **NOTIFICACOES.md** - Sistema completo de notificações de agendamentos
- **TUTORIAL_PRIMEIRO_ACESSO.md** - Onboarding interativo para novos usuários
- **SOLUCAO_ERRO_*.md** - Troubleshooting para erros comuns (build Windows, imagens, agendamentos)

## Convenções Importantes

1. **Sempre capture Provider com `.read<>()` antes de operações assíncronas**
2. **Numeração automática:** Orçamentos/recibos usam transações Firestore para garantir sequência única
3. **URLs nulas:** Sempre trate `logoUrl`, `assinaturaUrl`, `fotos` como nullable
4. **Cores personalizadas:** Armazenadas como `int` (valor de `Color.value`), reconstrua com `Color(int)`
5. **Testes:** Estrutura básica em `test/`, execute com `flutter test`
6. **App Check:** Web precisa de variável de ambiente para ativar, mobile usa debug provider

## Fluxos Essenciais

**Criar Orçamento:**
1. Selecionar cliente (`ClientsProvider.clientes`)
2. Adicionar itens/serviços (`ServicesProvider`, `PecasProvider`)
3. Calcular subtotal/desconto
4. Adicionar fotos (opcional, upload para Storage)
5. Salvar com `OrcamentosProvider.adicionarOrcamento()` (gera número automático)
6. Compartilhar via deep link ou gerar PDF

**Compartilhar Orçamento:**
1. Preparar `parametrosPersonalizados` (userId, documentoId, cores)
2. Chamar `DeepLink.createLink()` com domínio `link.orcemais.com`
3. Link redireciona para `gestorfy-cliente.web.app` com query params
4. Cliente acessa via app web separado que lê Firestore (read-only)

**Agendamento com Notificação:**
1. Criar agendamento com status "Confirmado"
2. `AgendamentosProvider` chama `NotificationService.agendarNotificacao()`
3. 30min antes, sistema envia notificação local
4. Ao concluir/cancelar, notificação é cancelada automaticamente
