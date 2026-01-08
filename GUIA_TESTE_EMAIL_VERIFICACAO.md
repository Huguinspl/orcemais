# 🧪 Guia de Teste: Verificação de Email de Boas-Vindas

## 📝 Preparação do Teste

### 1. Limpar o ambiente
```powershell
cd c:\Users\hugui\desenvolvimento\Orcemais
flutter clean
flutter pub get
```

### 2. Executar em modo debug
```powershell
# Para Android (recomendado)
flutter run -d 22101320G

# OU para Windows
flutter run -d windows

# OU para Chrome (web)
flutter run -d chrome
```

## 🔍 Executar o Teste

### Passo 1: Preparar Email de Teste
- Use um **email novo** que nunca foi cadastrado no Gestorfy
- Recomendações:
  - ✅ Gmail pessoal (ex: seunome+teste1@gmail.com)
  - ✅ Outlook pessoal
  - ❌ Evite email corporativo/universitário (podem bloquear)

### Passo 2: Fazer Cadastro
1. Abra o app
2. Clique em "Criar Conta" ou "Cadastrar"
3. Preencha:
   - **Email:** seu email de teste
   - **Senha:** mínimo 6 caracteres
   - **Confirmar Senha:** mesma senha
4. Clique em **"Cadastrar"**

### Passo 3: Observar os Logs no Terminal
Procure por uma destas mensagens no terminal:

**✅ SUCESSO:**
```
✅ Email de boas-vindas enviado para: seuemail@exemplo.com
```

**❌ ERRO:**
```
⚠️ Erro ao enviar email de boas-vindas: [detalhes do erro]
```

### Passo 4: Verificar Dialog no App
Após o cadastro, você deve ver um dos seguintes dialogs:

**✅ Email Enviado com Sucesso:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📧 Email de Verificação Enviado

Um email de verificação foi enviado para:
seuemail@exemplo.com

Por favor, verifique sua caixa de entrada
e também a pasta de spam/lixo eletrônico.

               [OK, ENTENDI]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**⚠️ Erro ao Enviar:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ Atenção

Não foi possível enviar o email de 
verificação no momento.

Você pode reenviar depois nas 
configurações do app.

Detalhes técnicos: [erro]

                    [OK]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Passo 5: Verificar Email Recebido
Aguarde até 5-10 minutos e verifique:

1. **Caixa de Entrada** principal
2. **Pasta de Spam/Lixo Eletrônico** ⚠️ IMPORTANTE
3. **Pasta de Promoções** (Gmail)

**Como o email deve aparecer:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
De: Orcemais <noreply@gestorfy-app.firebaseapp.com>
Para: seuemail@exemplo.com
Assunto: Bem-vindo ao Orcemais! Confirme seu email

Olá,

Clique no link abaixo para verificar seu endereço de email:

[Verificar Endereço de Email]

Se você não solicitou esta verificação, ignore este email.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🐛 Problemas Comuns e Soluções

### Problema 1: Dialog não aparece
**Causa:** Código pode ter erro de compilação
**Solução:**
```powershell
flutter analyze
```

### Problema 2: Email não chega (mesmo sem erro)
**Possíveis causas:**
1. Email está na **pasta de spam** ⚠️
2. Provedor de email bloqueou (teste com Gmail)
3. Firebase demora para enviar (aguarde 10 min)
4. Template não configurado no Firebase Console

**Solução:**
- Verifique Firebase Console: https://console.firebase.google.com/project/gestorfy-app/authentication/emails
- Certifique-se que "Email address verification" está configurado

### Problema 3: Erro no terminal mostra problemas de permissão
**Solução:**
- Verifique se o Firebase App Check não está bloqueando
- Desative temporariamente comentando o bloco do App Check em [main.dart](lib/main.dart)

### Problema 4: Usuário já existe
**Erro no log:**
```
[firebase_auth/email-already-in-use] The email address is already in use
```

**Solução:**
1. Vá em Firebase Console → Authentication → Users
2. Procure pelo email
3. Delete o usuário
4. Tente cadastrar novamente com email novo

## 📊 Resultados Esperados

| Cenário | Log no Terminal | Dialog no App | Email Recebido |
|---------|----------------|---------------|----------------|
| ✅ Tudo OK | `✅ Email de boas-vindas enviado` | Dialog verde | Email em 5-10 min |
| ⚠️ Erro Firebase | `⚠️ Erro ao enviar email` | Dialog laranja | Não recebe |
| 🔒 Email bloqueado | `✅ Email enviado` (mas Firebase bloqueou) | Dialog verde | Não recebe |

## 🎯 Checklist do Teste

- [ ] Flutter clean e pub get executados
- [ ] App rodando em modo debug
- [ ] Terminal aberto e visível
- [ ] Email de teste preparado (Gmail recomendado)
- [ ] Cadastro realizado com sucesso
- [ ] Log verificado no terminal
- [ ] Dialog apareceu no app
- [ ] Aguardado 10 minutos
- [ ] Caixa de entrada verificada
- [ ] **Pasta de SPAM verificada** ⚠️
- [ ] Firebase Console verificado (templates configurados)

## 📝 Registrar Resultados

Anote aqui os resultados do seu teste:

```
Data/Hora do Teste: _______________________
Email Usado: _______________________________
Device/Plataforma: _________________________

Terminal mostrou:
[ ] ✅ Email enviado
[ ] ⚠️ Erro ao enviar (anotar erro abaixo)

Dialog apareceu:
[ ] Sim - Verde (sucesso)
[ ] Sim - Laranja (erro)
[ ] Não apareceu

Email recebido:
[ ] Sim - Caixa de entrada
[ ] Sim - Pasta de spam
[ ] Não recebido após 10 min

Observações/Erros:
_________________________________________
_________________________________________
_________________________________________
```

## 🚀 Próximos Passos

Após o teste:

1. Se **tudo funcionou**: 
   - ✅ Problema resolvido!
   - Agora o usuário vê feedback claro sobre o email

2. Se **email não foi enviado**:
   - Copie o erro do terminal
   - Verifique Firebase Console → Authentication → Templates
   - Teste com outro provedor de email (Gmail)

3. Se **email foi enviado mas não chegou**:
   - Problema é do provedor de email ou configuração do Firebase
   - Adicione `noreply@gestorfy-app.firebaseapp.com` aos contatos
   - Verifique se domínio não está bloqueado

---

**Criado em:** 7 de janeiro de 2026  
**Melhorias implementadas:**
- ✅ Dialog de feedback ao usuário
- ✅ Mensagens detalhadas de sucesso/erro
- ✅ Logs mais claros no terminal
