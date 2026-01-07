# ✅ Guia Completo: Configuração do Email Personalizado

## 🎯 O que foi criado

✅ Página web customizada de redefinição de senha (`web/action-handler.html`)
- Interface em **português brasileiro**
- Nome **Orcemais** em destaque
- **2 campos de senha** (senha + confirmação)
- Validação em tempo real
- Visual bonito e profissional
- Botão para mostrar/ocultar senha

## 📋 Passo a Passo para Ativar

### Etapa 1: Deploy da Página Web

**Execute os comandos:**

```powershell
# Na pasta Orcemais
cd C:\Users\hugui\desenvolvimento\Orcemais

# Build do projeto web
flutter build web --release

# Deploy para Firebase Hosting
firebase deploy --only hosting
```

**Resultado esperado:**
```
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/gestorfy-app/overview
Hosting URL: https://gestorfy-app.web.app
```

### Etapa 2: Configurar o Firebase Console

**1. Acesse o Firebase Console:**
```
https://console.firebase.google.com/project/gestorfy-app
```

**2. Vá em Authentication > Templates:**
```
Menu lateral > Authentication > Aba "Templates"
```

**3. Configure o Template de Redefinição de Senha:**

Clique em **"Redefinição de senha"** e configure:

**Nome do remetente:**
```
Orcemais
```

**Assunto do email:**
```
Recuperação de Senha - Orcemais
```

**Corpo do email em português:**
```
Olá,

Recebemos uma solicitação para redefinir a senha da sua conta no Orcemais.

Para criar uma nova senha, clique no link abaixo:

%LINK%

Se você não solicitou a redefinição de senha, ignore este e-mail. Seu acesso permanecerá seguro.

Este link é válido por 1 hora.

Atenciosamente,
Equipe Orcemais

---
Este é um e-mail automático, não responda a esta mensagem.
```

**4. Configure a URL de Ação Personalizada:**

Na mesma tela, procure por **"Personalizar ação URL"** ou **"Action URL"**:

```
https://gestorfy-app.web.app/action-handler.html
```

⚠️ **IMPORTANTE:** Sem essa configuração, o Firebase continuará usando a página padrão!

**5. Salve todas as alterações** ✅

### Etapa 3: Testar

**1. No app, vá para recuperação de senha**

**2. Digite um email cadastrado e envie**

**3. Abra o email recebido** (verifique spam)

**4. Clique no link**

**Resultado esperado:**
- ✅ Abre página customizada em português
- ✅ Logo/ícone do Orcemais
- ✅ 2 campos de senha
- ✅ Validação em tempo real
- ✅ Mensagem de sucesso
- ✅ Redireciona para o app/login

## 📊 Recursos da Página Customizada

### 🎨 Visual
- Gradiente verde (cores do app)
- Logo circular com ícone de segurança
- Design responsivo (funciona em celular)
- Animações suaves

### ✔️ Validações
- Senha mínimo 6 caracteres
- Senhas devem ser iguais
- Indicador de força da senha
- Mensagens de erro em português

### 🔒 Segurança
- Valida código do Firebase
- Verifica expiração do link
- Trata links inválidos
- Confirmação antes de alterar

### 📱 Funcionalidades
- Mostrar/ocultar senha (botão 👁️)
- Validação em tempo real
- Loading ao processar
- Mensagem de sucesso
- Redireciona automaticamente

## 🔧 Personalizar ainda mais

### Mudar cores:

Edite no arquivo `web/action-handler.html`:

```css
/* Linha ~12 - Gradiente de fundo */
background: linear-gradient(135deg, #006d5b 0%, #4db6ac 100%);

/* Linha ~56 - Cor do título */
color: #006d5b;

/* Linha ~95 - Cor do foco do input */
border-color: #006d5b;
```

### Adicionar logo real:

Substitua o ícone SVG (linha ~82) por uma imagem:

```html
<div class="logo">
    <img src="https://seu-dominio.com/logo.png" alt="Orcemais" style="width: 60px;">
</div>
```

## 🚨 Troubleshooting

### Problema: Link ainda abre página padrão do Firebase

**Solução:**
1. Verifique se fez o deploy: `firebase deploy --only hosting`
2. Confirme a Action URL no Firebase Console
3. Limpe cache do navegador
4. Aguarde 5-10 minutos para propagação

### Problema: Página não carrega

**Solução:**
1. Verifique se o arquivo está em `web/action-handler.html`
2. Confirme o deploy com sucesso
3. Teste a URL diretamente: `https://gestorfy-app.web.app/action-handler.html?mode=resetPassword&oobCode=teste`
4. Verifique erros no console do navegador (F12)

### Problema: Erro de configuração do Firebase

**Solução:**
Verifique as credenciais no arquivo `action-handler.html` (linha ~244):
```javascript
const firebaseConfig = {
    apiKey: "AIzaSyB6XnB5jv9loZf6mTTYghFPIcIDNnW7g3o",
    authDomain: "gestorfy-app.firebaseapp.com",
    projectId: "gestorfy-app",
    // ...
};
```

## ✅ Checklist Final

- [x] Arquivo `web/action-handler.html` criado ✅
- [x] Configuração de hosting adicionada ao `firebase.json` ✅
- [x] `flutter build web --release` executado ✅
- [x] `firebase deploy --only hosting` executado ✅
- [ ] Firebase Console > Authentication > Templates configurado **← FAZER AGORA**
- [ ] Nome do remetente: "Orcemais"
- [ ] Assunto em português configurado
- [ ] Corpo do email em português configurado
- [ ] Action URL configurada: `https://gestorfy-app.web.app/action-handler.html`
- [ ] Todas as alterações salvas no Firebase Console
- [ ] Teste realizado com sucesso

## 🎉 Resultado Final

### Antes:
```
Email: [Firebase] Reset Password
Página: Básica em inglês com 1 campo
```

### Depois:
```
Email: Recuperação de Senha - Orcemais (em português)
Página: Bonita, profissional, 2 campos, validações
```

## 📞 Suporte

Se tiver dúvidas:
1. Verifique o console do navegador (F12)
2. Verifique logs do Firebase
3. Teste a URL da action-handler diretamente
4. Confirme que o deploy foi bem-sucedido

