# 🔍 Diagnóstico: Email de Verificação Não Enviado

## 📋 Problema Relatado
Ao fazer um novo cadastro, o email de boas-vindas com link de verificação não está sendo enviado.

## ✅ Código Atual (Correto)
O código em [signup_page.dart](lib/pages/signup_page.dart) está implementado corretamente:

```dart
/* 1.5) Envia email de boas-vindas/verificação */
if (cred.user != null && !cred.user!.emailVerified) {
  try {
    await cred.user!.sendEmailVerification();
    print('✅ Email de boas-vindas enviado para: $email');
  } catch (e) {
    print('⚠️ Erro ao enviar email de boas-vindas: $e');
    // Não bloqueia o cadastro se falhar o envio do email
  }
}
```

## 🔍 Possíveis Causas

### 1. ⚠️ Configuração do Firebase Console
O template do email de verificação pode não estar configurado no Firebase Console.

**Solução:**
1. Acesse: https://console.firebase.google.com/project/gestorfy-app/authentication/emails
2. Clique em **"Email address verification"** (Verificação de endereço de e-mail)
3. Configure:
   - **Nome do remetente:** `Orcemais`
   - **Assunto:** `Bem-vindo ao Orcemais! Confirme seu email`
4. Clique em **"Salvar"**

### 2. 📧 Email está indo para Spam/Lixeira
Os emails do Firebase Authentication (`noreply@gestorfy-app.firebaseapp.com`) podem ser marcados como spam.

**Solução:**
- Verifique a caixa de **Spam** ou **Lixo Eletrônico**
- Adicione `noreply@gestorfy-app.firebaseapp.com` aos contatos confiáveis

### 3. 🔒 Domínio de Email Bloqueado
Alguns provedores de email (como empresas ou universidades) bloqueiam emails do Firebase.

**Solução:**
- Teste com um email pessoal do Gmail, Outlook ou Yahoo
- Se funcionar, o problema é o domínio corporativo

### 4. ⏱️ Atraso no Envio
O Firebase pode levar alguns minutos para enviar o email, especialmente na primeira vez.

**Solução:**
- Aguarde até 5-10 minutos antes de concluir que não foi enviado

### 5. 🌐 Firebase App Check Bloqueando
Se o App Check estiver ativo sem configuração correta, pode bloquear requisições.

**Solução:**
- Para testes, desative temporariamente o App Check em [main.dart](lib/main.dart):

```dart
// Comentar todo o bloco try-catch do App Check
// try {
//   if (kIsWeb) {
//     ...
//   }
// } catch (e) {
//   debugPrint('Falha ao ativar App Check: $e');
// }
```

### 6. 📊 Logs não aparecem no Console
O erro pode estar acontecendo silenciosamente, mas os logs não aparecem.

**Solução:**
- Execute o app em **modo debug** com terminal aberto:
```powershell
flutter run -d <device>
```
- Observe os logs no terminal para ver a mensagem:
  - `✅ Email de boas-vindas enviado para: ...` (sucesso)
  - `⚠️ Erro ao enviar email de boas-vindas: ...` (falha)

### 7. 🔐 Usuário Já Verificado
Se o email já foi cadastrado e verificado antes (mesmo que a conta tenha sido deletada do Firestore), o Firebase não envia novo email.

**Solução:**
- No Firebase Console → Authentication → Users
- Procure pelo email e **delete o usuário completamente**
- Tente cadastrar novamente

## 🧪 Teste Completo Passo a Passo

### Preparação:
1. **Limpe o cache do app:**
```powershell
flutter clean
flutter pub get
```

2. **Desinstale o app do dispositivo** (para garantir estado limpo)

3. **Execute em modo debug:**
```powershell
flutter run -d windows  # ou android, chrome, etc
```

### Teste:
1. Abra a tela de cadastro
2. Use um **email novo** (nunca cadastrado antes)
3. Preencha os campos e clique em "Cadastrar"
4. **Observe o terminal** buscando por:
   - ✅ `Email de boas-vindas enviado para: ...`
   - ⚠️ `Erro ao enviar email de boas-vindas: ...`

5. Se ver o ✅, **aguarde 5-10 minutos** e verifique:
   - Caixa de entrada do email
   - **Pasta de Spam/Lixo Eletrônico**
   - Pasta de Promoções (Gmail)

## 🔧 Solução Adicional: Melhorar Feedback ao Usuário

Atualmente, o erro ao enviar email não é mostrado ao usuário. Vamos melhorar isso:

**Adicione um Dialog mostrando o resultado:**

```dart
/* 1.5) Envia email de boas-vindas/verificação */
if (cred.user != null && !cred.user!.emailVerified) {
  try {
    await cred.user!.sendEmailVerification();
    print('✅ Email de boas-vindas enviado para: $email');
    
    // NOVO: Mostrar mensagem ao usuário
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('📧 Email de Verificação Enviado'),
          content: Text(
            'Um email de verificação foi enviado para:\n\n$email\n\n'
            'Por favor, verifique sua caixa de entrada e pasta de spam.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    print('⚠️ Erro ao enviar email de boas-vindas: $e');
    
    // NOVO: Mostrar erro ao usuário
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('⚠️ Atenção'),
          content: Text(
            'Não foi possível enviar o email de verificação.\n\n'
            'Erro: $e\n\n'
            'Você pode reenviar depois nas configurações.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
```

## 📝 Checklist de Verificação

- [ ] Verificar Firebase Console → Authentication → Templates
- [ ] Testar com Gmail/Outlook pessoal
- [ ] Verificar pasta de Spam/Lixo
- [ ] Aguardar 5-10 minutos após cadastro
- [ ] Executar em modo debug e observar logs
- [ ] Verificar se usuário já existe no Firebase Auth
- [ ] Tentar desativar App Check temporariamente
- [ ] Implementar feedback visual ao usuário

## 🎯 Próximos Passos

1. **Execute o teste completo** seguindo o roteiro acima
2. **Anote os logs** que aparecem no terminal
3. Se o problema persistir, **compartilhe os logs** para análise mais detalhada

---

**Última atualização:** 7 de janeiro de 2026
