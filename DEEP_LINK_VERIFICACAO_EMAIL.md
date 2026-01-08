# 📱 Deep Link para Verificação de Email

## ✅ O que foi implementado

Agora após verificar o email, o usuário é automaticamente redirecionado para:
- **App instalado** no celular (se existir) ✅
- **App web** como fallback (se não houver app instalado)

---

## 🎯 Como Funciona

### 1. **Envio do Email com Deep Link**
Quando o usuário se cadastra, o email de verificação é enviado com uma URL especial configurada em [signup_page.dart](lib/pages/signup_page.dart):

```dart
final actionCodeSettings = ActionCodeSettings(
  // URL que será aberta após verificar o email
  url: 'https://gestorfy-app.firebaseapp.com/email-verified',
  
  // Configurações para Android
  androidPackageName: 'com.orcemais.orcemais',
  androidInstallApp: true, // Oferece instalar o app se não estiver instalado
  androidMinimumVersion: '1',
  
  // Configurações para iOS
  iOSBundleId: 'com.orcemais.orcemais',
);

await cred.user!.sendEmailVerification(actionCodeSettings);
```

### 2. **Android Manifest com Deep Links**
O [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) foi configurado para capturar os links:

```xml
<!-- Deep Link para capturar verificação de email -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data
        android:scheme="https"
        android:host="gestorfy-app.firebaseapp.com"
        android:pathPrefix="/email-verified"/>
</intent-filter>
```

### 3. **Handler de Deep Links**
O serviço [deep_link_handler.dart](lib/services/deep_link_handler.dart) escuta os deep links e processa a verificação:

```dart
- Escuta links quando o app está aberto
- Verifica se é um link de verificação de email
- Recarrega os dados do usuário no Firebase
- Mostra mensagem de sucesso
- Redireciona para a home do app
```

### 4. **Integração no App**
O [main.dart](lib/main.dart) inicializa o handler quando o app abre:

```dart
class _GestorfyAppState extends State<GestorfyApp> {
  final _deepLinkHandler = DeepLinkHandler();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deepLinkHandler.initialize(context);
    });
  }
}
```

---

## 🧪 Como Testar

### **Passo 1: Instalar Dependências**
```powershell
cd c:\Users\hugui\desenvolvimento\Orcemais
flutter pub get
```

### **Passo 2: Compilar e Instalar no Android**
```powershell
flutter build apk --debug
# OU para testar direto
flutter run -d 22101320G
```

### **Passo 3: Fazer Cadastro no App**
1. Abra o app instalado no celular
2. Faça um novo cadastro com email válido
3. Anote o email usado

### **Passo 4: Verificar Email**
1. Abra o email no **mesmo dispositivo** onde o app está instalado
2. Clique no link "Verificar Email"

### **Passo 5: Observar Comportamento**

#### ✅ Cenário 1: App Instalado
- O link abre o **app Orcemais** automaticamente
- Aparece mensagem: "Email verificado com sucesso!"
- Usuário é redirecionado para a home do app

#### 🌐 Cenário 2: App Não Instalado
- O link abre no **navegador web**
- Mostra página do Firebase confirmando verificação
- Oferece opção para instalar o app (se configurado na Play Store)

---

## 📊 Fluxo Completo

```
┌─────────────────────────────────────────────────────────┐
│  1. Usuário se cadastra no app                          │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  2. Firebase envia email com link especial              │
│     https://gestorfy-app.firebaseapp.com/email-verified │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  3. Usuário clica no link do email                      │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
         ┌───────┴────────┐
         │                │
    App Instalado?        │
         │                │
    ┌────┴────┐      ┌────┴────┐
    │   SIM   │      │   NÃO   │
    └────┬────┘      └────┬────┘
         │                │
         ▼                ▼
┌─────────────────┐  ┌─────────────────┐
│ Abre o APP      │  │ Abre NAVEGADOR  │
│ automaticamente │  │ (fallback)      │
└────┬────────────┘  └─────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────┐
│  4. DeepLinkHandler processa o link                     │
│     - Recarrega dados do usuário                        │
│     - Verifica se email foi confirmado                  │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  5. Mostra mensagem de sucesso                          │
│     "✅ Email verificado com sucesso!"                  │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  6. Redireciona para HOME do app                        │
└─────────────────────────────────────────────────────────┘
```

---

## 🛠️ Configurações Necessárias

### **1. Firebase Console - Domínios Autorizados**
Adicione o domínio no Firebase Console:

1. Acesse: https://console.firebase.google.com/project/gestorfy-app/authentication/settings
2. Role até "Authorized domains"
3. Verifique se está listado:
   - ✅ `gestorfy-app.firebaseapp.com`

### **2. Android - Verificação de App Links**
Para que o Android abra automaticamente o app (sem perguntar), é necessário:

1. Adicionar arquivo `.well-known/assetlinks.json` no domínio
2. Ou usar Firebase Hosting para hospedar automaticamente

**Arquivo assetlinks.json:**
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.orcemais.orcemais",
    "sha256_cert_fingerprints": [
      "SHA256_DO_SEU_APP"
    ]
  }
}]
```

**Obter SHA256:**
```powershell
# Para debug
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# Para release
keytool -list -v -keystore caminho\para\sua\keystore.jks -alias seu_alias
```

---

## 🐛 Troubleshooting

### Problema 1: Link abre no navegador mesmo com app instalado

**Causa:** Android não conseguiu verificar os App Links

**Solução:**
```powershell
# Forçar o app a ser o handler padrão
adb shell pm set-app-links com.orcemais.orcemais --package com.orcemais.orcemais 0

# Verificar status
adb shell pm get-app-links com.orcemais.orcemais
```

### Problema 2: Deep link não está funcionando

**Verificar logs:**
```powershell
flutter run -d 22101320G
# Procure por logs:
# 🔗 Deep link recebido: ...
# 📧 Processando verificação de email...
# ✅ Email verificado com sucesso!
```

### Problema 3: Email já foi verificado mas app não reconhece

**Solução:**
1. No app, vá em Perfil/Configurações
2. Faça logout
3. Faça login novamente
4. O Firebase atualizará o status automaticamente

---

## 📦 Dependências Adicionadas

```yaml
dependencies:
  uni_links: ^0.5.1  # Para capturar deep links
```

---

## 🔐 Segurança

- ✅ Apenas links do domínio `gestorfy-app.firebaseapp.com` são aceitos
- ✅ Verificação de autenticação antes de processar
- ✅ Recarregamento dos dados do usuário do Firebase
- ✅ Validação do status `emailVerified`

---

## 🚀 Próximos Passos (Opcional)

### 1. **Firebase Dynamic Links** (Recomendado)
Para melhor controle e analytics:
```yaml
dependencies:
  firebase_dynamic_links: ^6.0.10
```

### 2. **Branch.io ou OneLink**
Para deep links mais avançados com atribuição

### 3. **Play Store Integration**
Configurar na Play Store para oferecer instalação do app

---

## ✅ Checklist de Implementação

- [x] ActionCodeSettings configurado no signup
- [x] AndroidManifest.xml com intent-filters
- [x] DeepLinkHandler criado e testado
- [x] Integração no main.dart
- [x] Pacote uni_links instalado
- [x] Tratamento de erros implementado
- [x] Mensagens de feedback ao usuário
- [ ] Testar no dispositivo físico
- [ ] Configurar assetlinks.json (para auto-open)
- [ ] Testar com app não instalado (fallback web)

---

**Criado em:** 7 de janeiro de 2026  
**Última atualização:** 7 de janeiro de 2026

**Status:** ✅ Implementado e pronto para testes
