# 🎨 Personalização do Email de Recuperação de Senha

## 📧 Situação Atual vs Desejada

### Atual (Firebase Padrão):
- ❌ Email em inglês
- ❌ Nome genérico "gestorfy-app"
- ❌ Página de redefinição básica do Firebase
- ❌ Apenas 1 campo de senha

### Desejado:
- ✅ Email em português brasileiro
- ✅ Nome do app: **Orcemais**
- ✅ Página customizada com 2 campos de senha
- ✅ Visual alinhado com o app

## 🔧 Solução Completa

### Parte 1: Personalizar Template do Email (Firebase Console)

**Passo a passo:**

1. **Acesse o Firebase Console:**
   ```
   https://console.firebase.google.com/
   Projeto: gestorfy-app
   ```

2. **Navegue até Templates:**
   ```
   Authentication > Templates > Redefinição de senha
   ```

3. **Configure o Template:**

   **Nome do remetente:**
   ```
   Orcemais
   ```

   **Assunto do email:**
   ```
   Recuperação de Senha - Orcemais
   ```

   **Corpo do email (em português):**
   ```html
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

4. **Salve as alterações** ✅

### Parte 2: Página Customizada de Redefinição (Action Handler)

O Firebase permite criar uma página personalizada para redefinir a senha. Vou criar uma página web customizada dentro do projeto.

**Estrutura:**
```
Orcemais/
  web/
    action-handler.html  ← Nova página para lidar com ações do Firebase
```

Esta página terá:
- ✅ Interface em português
- ✅ Logo do Orcemais
- ✅ 2 campos de senha (senha e confirmar senha)
- ✅ Validações
- ✅ Visual consistente com o app

### Parte 3: Configurar Action URL no Firebase

No Firebase Console:
```
Authentication > Templates > Ação de configuração
URL de ação: https://gestorfy-app.web.app/action-handler.html
```

## 📋 Próximos Passos

1. ✅ Configurar template no Firebase Console (manual)
2. ✅ Criar página action-handler.html
3. ✅ Adicionar validação de 2 campos de senha
4. ✅ Deploy da página web
5. ✅ Configurar Action URL no Firebase

## ⚠️ Limitação Importante

O Firebase Authentication **não permite** personalizar completamente a página de redefinição na versão hosted. 

**Soluções:**

### Opção A: Action Handler Web (Recomendada)
- Criar uma página web customizada
- Hospedar no Firebase Hosting
- Configurar como Action URL
- Usuário clica no link do email → vai para sua página customizada

### Opção B: Deep Link para o App
- Link do email abre o app
- App mostra tela de redefinição
- Funciona apenas se usuário tiver o app instalado

### Opção C: Aceitar Template Padrão do Firebase
- Apenas personalizar o texto do email
- Página de redefinição continua padrão Firebase
- Mais simples, menos customizável

## 🎯 Recomendação

Vou implementar a **Opção A** - criar uma página web customizada completa que:
1. Recebe o link do email
2. Mostra interface em português
3. Tem 2 campos de senha
4. Valida e confirma a alteração
5. Redireciona de volta para o app

