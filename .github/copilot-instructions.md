# Copilot Instructions for gestorfy

## Visão Geral
Este projeto é um aplicativo Flutter multiplataforma (Android, iOS, Web, Desktop) para gestão de negócios, com integração a Firebase (Firestore, Auth, Storage) e uso extensivo de Provider para gerenciamento de estado.

## Estrutura Principal
- `lib/` contém toda a lógica de negócio, modelos, páginas, providers, rotas e widgets reutilizáveis.
  - `models/`: Modelos de dados (ex: usuário, negócio, orçamento)
  - `pages/`: Telas principais do app (ex: perfil, orçamento, personalização)
  - `providers/`: Providers para estado global (ex: `UserProvider`)
  - `services/`: Serviços de integração (ex: Firebase, PDF)
  - `widgets/`: Componentes reutilizáveis
- `assets/`: Imagens e recursos estáticos
- `test/`: Testes unitários e de widget

## Fluxos e Convenções
- **Gerenciamento de estado:** Use sempre Provider (ex: `context.watch<UserProvider>()`).
- **Persistência:** Dados do usuário e negócio são salvos no Firestore. Imagens (ex: logomarca) vão para Firebase Storage e a URL é salva no Firestore.
- **Personalização:** Telas de personalização de negócio/orçamento permitem editar dados e logomarca, que são refletidos no PDF gerado.
- **PDF:** Geração de PDF utiliza o pacote `pdf` e busca a logomarca via URL.
- **Rotas:** Definidas em `lib/routes/app_routes.dart`.
- **Atualização de dados:** Sempre use métodos do Provider para atualizar e persistir dados.

## Exemplos de Padrão
- Upload de imagem:
  - Use `image_picker` para selecionar.
  - Faça upload para Storage e salve a URL no Firestore via Provider.
- Atualização de perfil:
  - Edite via bottom sheet, salve no Provider e persista no Firestore.
- Geração de PDF:
  - Recupere dados do Provider, busque logomarca por URL e insira no PDF.

## Comandos Úteis
- **Build:** `flutter build apk` ou `flutter build web`
- **Testes:** `flutter test`
- **Rodar local:** `flutter run`

## Integrações
- Firebase (Firestore, Auth, Storage): Configurado via `firebase_options.dart` e arquivos de configuração nas pastas `android/`, `ios/`, `web/`.
- Dependências principais: `provider`, `firebase_core`, `cloud_firestore`, `firebase_auth`, `firebase_storage`, `image_picker`, `pdf`.

## Observações
- Siga o padrão de atualização de dados via Provider para garantir sincronização com a UI e persistência.
- Sempre trate URLs de imagens como podendo ser nulas/vazias.
- Para novos fluxos, siga o padrão das páginas e providers existentes.

---
Seções incompletas ou dúvidas? Peça exemplos de uso de Provider, integração com Firebase ou geração de PDF conforme necessário.
