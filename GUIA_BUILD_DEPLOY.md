# 🚀 Guia de Build e Deploy - Gestorfy

## 📋 Pré-requisitos

Antes de fazer o build e deploy, certifique-se de que:
- ✅ Flutter SDK instalado e atualizado
- ✅ Firebase CLI instalado (`npm install -g firebase-tools`)
- ✅ Conta Firebase configurada
- ✅ Git para controle de versão

---

## 🔧 1. Preparação do Projeto

### **Passo 1.1: Limpar builds anteriores**

```powershell
# Limpar cache e builds anteriores
flutter clean

# Obter dependências atualizadas
flutter pub get
```

### **Passo 1.2: Verificar se há erros**

```powershell
# Analisar o código
flutter analyze

# Verificar formatação
flutter format --set-exit-if-changed lib/
```

---

## 📱 2. Build para Android (APK)

### **Opção 1: APK para Debug/Testes**

```powershell
# Build APK para debug (mais rápido)
flutter build apk --debug

# Localização: build/app/outputs/flutter-apk/app-debug.apk
```

### **Opção 2: APK de Release (Produção)**

```powershell
# Build APK otimizado para produção
flutter build apk --release

# Localização: build/app/outputs/flutter-apk/app-release.apk
```

### **Opção 3: App Bundle (Para Google Play Store)**

```powershell
# Build App Bundle (recomendado para Play Store)
flutter build appbundle --release

# Localização: build/app/outputs/bundle/release/app-release.aab
```

---

## 🍎 3. Build para iOS

### **Pré-requisitos iOS:**
- Xcode instalado (macOS)
- Certificados de desenvolvedor Apple
- Dispositivo físico ou simulador

```bash
# Build para iOS
flutter build ios --release

# Ou abrir no Xcode para assinar e fazer deploy
open ios/Runner.xcworkspace
```

---

## 🌐 4. Build para Web

### **Passo 4.1: Build da aplicação Web**

```powershell
# Build para Web (produção)
flutter build web --release

# Build com suporte a CanvasKit (melhor performance gráfica)
flutter build web --release --web-renderer canvaskit

# Build com suporte a HTML (menor tamanho, melhor compatibilidade)
flutter build web --release --web-renderer html

# Localização: build/web/
```

### **Passo 4.2: Testar localmente antes do deploy**

```powershell
# Instalar servidor HTTP local
# npm install -g http-server

# Servir a pasta build/web
cd build/web
http-server -p 8080

# Abrir navegador em: http://localhost:8080
```

---

## 🔥 5. Deploy no Firebase Hosting

### **Passo 5.1: Login no Firebase**

```powershell
# Fazer login no Firebase
firebase login

# Verificar projetos disponíveis
firebase projects:list
```

### **Passo 5.2: Inicializar Firebase (se ainda não foi feito)**

```powershell
# Inicializar Firebase no projeto
firebase init hosting

# Configurações recomendadas:
# - Public directory: build/web
# - Configure as single-page app: Yes
# - Set up automatic builds with GitHub: No (ou Yes se quiser CI/CD)
# - Overwrite index.html: No
```

### **Passo 5.3: Deploy para Firebase**

```powershell
# 1. Build da aplicação
flutter build web --release --web-renderer html

# 2. Deploy no Firebase Hosting
firebase deploy --only hosting

# Ou deploy com mensagem personalizada
firebase deploy --only hosting -m "Deploy com cores personalizadas no Deep Link"
```

### **Passo 5.4: Deploy para canais específicos**

```powershell
# Deploy para canal de preview/staging
firebase hosting:channel:deploy staging

# Deploy para produção (canal live)
firebase deploy --only hosting
```

---

## 📦 6. Deploy de Regras do Firestore e Storage

### **Passo 6.1: Deploy das regras do Firestore**

```powershell
# Deploy apenas regras do Firestore
firebase deploy --only firestore:rules

# Deploy com índices do Firestore
firebase deploy --only firestore
```

### **Passo 6.2: Deploy das regras do Storage**

```powershell
# Deploy apenas regras do Storage
firebase deploy --only storage
```

### **Passo 6.3: Deploy completo (tudo)**

```powershell
# Deploy de tudo (hosting + firestore + storage)
firebase deploy
```

---

## 🪟 7. Build para Windows Desktop

```powershell
# Build para Windows
flutter build windows --release

# Localização: build/windows/x64/runner/Release/
```

---

## 🐧 8. Build para Linux Desktop

```bash
# Build para Linux
flutter build linux --release

# Localização: build/linux/x64/release/bundle/
```

---

## 🍎 9. Build para macOS Desktop

```bash
# Build para macOS
flutter build macos --release

# Localização: build/macos/Build/Products/Release/
```

---

## 🔄 10. Fluxo Completo Recomendado

### **Para Desenvolvimento/Testes:**

```powershell
# 1. Limpar e preparar
flutter clean
flutter pub get

# 2. Analisar código
flutter analyze

# 3. Build debug APK
flutter build apk --debug

# 4. Testar no dispositivo
flutter install
```

### **Para Produção (Web):**

```powershell
# 1. Limpar e preparar
flutter clean
flutter pub get

# 2. Analisar e testar
flutter analyze
flutter test

# 3. Build web otimizado
flutter build web --release --web-renderer html

# 4. Deploy no Firebase
firebase deploy --only hosting -m "Versão 1.0.0+2 - Deep Link com cores"

# 5. Verificar deploy
# Abrir: https://gestorfy.web.app (ou seu domínio)
```

### **Para Produção (Android):**

```powershell
# 1. Incrementar versão no pubspec.yaml
# version: 1.0.0+3

# 2. Limpar e preparar
flutter clean
flutter pub get

# 3. Build App Bundle
flutter build appbundle --release

# 4. Fazer upload para Google Play Console
# Arquivo: build/app/outputs/bundle/release/app-release.aab
```

---

## 📊 11. Verificar Tamanho do Build

```powershell
# Analisar tamanho do APK
flutter build apk --analyze-size

# Analisar tamanho do App Bundle
flutter build appbundle --analyze-size

# Ver relatório no navegador
flutter build apk --analyze-size --target-platform android-arm64
```

---

## 🐛 12. Troubleshooting

### **Problema: Erro de dependências**
```powershell
flutter clean
flutter pub get
flutter pub upgrade
```

### **Problema: Build Web não funciona**
```powershell
# Verificar se há erros no console do navegador
# Usar --web-renderer html em vez de canvaskit
flutter build web --release --web-renderer html
```

### **Problema: Firebase deploy falha**
```powershell
# Verificar se está logado
firebase login --reauth

# Verificar projeto correto
firebase use --add

# Limpar cache
firebase hosting:disable
firebase deploy --only hosting
```

### **Problema: APK muito grande**
```powershell
# Build com split por ABI (múltiplos APKs menores)
flutter build apk --split-per-abi --release
```

---

## 🎯 13. Checklist de Deploy

### **Antes do Deploy:**
- [ ] Código revisado e testado
- [ ] Versão incrementada no `pubspec.yaml`
- [ ] `flutter analyze` sem erros críticos
- [ ] Testes passando (`flutter test`)
- [ ] Firebase configurado corretamente
- [ ] Variáveis de ambiente/secrets configuradas
- [ ] Commit e push no Git

### **Durante o Deploy:**
- [ ] Build gerado sem erros
- [ ] Deploy executado com sucesso
- [ ] URL de produção acessível

### **Após o Deploy:**
- [ ] Testar funcionalidades principais
- [ ] Verificar cores personalizadas no Deep Link
- [ ] Testar compartilhamento de orçamento/recibo
- [ ] Verificar links gerados
- [ ] Testar em diferentes dispositivos/navegadores
- [ ] Monitorar logs de erro no Firebase Console

---

## 📱 14. URLs do Projeto

Após o deploy, seus apps estarão disponíveis em:

- **Web (Gestorfy):** `https://gestorfy.web.app` ou seu domínio customizado
- **Web (Gestorfy-Cliente):** `https://gestorfy-cliente.web.app`
- **Deep Links:** `https://link.orcemais.com/...`

---

## 🔑 15. Comandos Rápidos

```powershell
# Build e deploy web em um comando
flutter build web --release && firebase deploy --only hosting

# Build APK e instalar no dispositivo
flutter build apk --debug && flutter install

# Ver logs do Firebase
firebase hosting:logs

# Ver versão atual deployada
firebase hosting:channel:list
```

---

## 🎉 Pronto para Deploy!

Execute os comandos na ordem e seu app estará no ar! 🚀

**Comando mais usado (Web):**
```powershell
flutter clean && flutter pub get && flutter build web --release --web-renderer html && firebase deploy --only hosting
```

**Boa sorte com o deploy! 😊**
