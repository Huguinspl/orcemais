# ⚠️ URGENTE: Como Publicar as Regras do Firestore

## 🚨 ERRO: "permission-denied"

Se você está vendo o erro `FirebaseException ([cloud_firestore/permission-denied])`, significa que as regras do Firestore **NÃO foram publicadas** no Firebase Console ainda!

## ✅ SOLUÇÃO RÁPIDA

### Passo 1: Acesse o Firebase Console
**Link direto:** https://console.firebase.google.com

### Passo 2: Selecione seu projeto
- Procure e clique em **"gestorfy"**

### Passo 3: Vá para Firestore Database
- No menu lateral esquerdo, clique em **"Firestore Database"**
- Clique na aba **"Regras"** (ou **"Rules"** se estiver em inglês)

### Passo 4: Copie as Regras
- Abra o arquivo `firestore.rules` deste projeto
- Selecione **TODO** o conteúdo (Ctrl+A)
- Copie (Ctrl+C)

### Passo 5: Cole no Firebase Console
- No editor do Firebase Console, **delete tudo** que está lá
- Cole o conteúdo copiado (Ctrl+V)

### Passo 6: Publique
- Clique no botão vermelho **"Publicar"** (ou **"Publish"**)
- Aguarde a mensagem de confirmação: "Regras publicadas com sucesso"

### Passo 7: Teste o App
- Volte ao app e tente acessar novamente
- O erro deve desaparecer! 🎉

---

## ⚠️ IMPORTANTE
As regras do Firestore foram atualizadas localmente, mas **PRECISAM ser publicadas no Firebase Console** para funcionar!

## 🔒 Regra Adicionada
- **Coleção `transacoes`**: Permite que usuários autenticados leiam e escrevam apenas suas próprias transações financeiras

## 📝 Passo a Passo para Publicar

### Opção 1: Via Firebase Console (Recomendado)

1. **Acesse o Firebase Console**
   - Vá para: https://console.firebase.google.com
   - Selecione seu projeto `gestorfy`

2. **Navegue até Firestore Database**
   - No menu lateral, clique em **"Firestore Database"**
   - Clique na aba **"Regras"** (Rules)

3. **Copie e Cole as Regras**
   - Abra o arquivo `firestore.rules` deste projeto
   - Copie TODO o conteúdo
   - Cole no editor do Firebase Console

4. **Publique as Regras**
   - Clique no botão **"Publicar"** (Publish)
   - Aguarde a confirmação de sucesso

### Opção 2: Via Firebase CLI

Se você tem o Firebase CLI instalado:

```bash
# No terminal, execute:
firebase deploy --only firestore:rules
```

## ✅ Como Verificar se Funcionou

Após publicar as regras:

1. Abra o app Gestorfy
2. Navegue até **Controle de Despesas**
3. Tente adicionar uma nova transação
4. Se funcionar sem erros de permissão, está tudo certo! 🎉

## 🐛 Problemas Comuns

### Erro: "permission-denied"
- **Causa**: Regras ainda não foram publicadas ou usuário não está autenticado
- **Solução**: Verifique se publicou as regras E se está logado no app

### Erro: "invalid-argument"
- **Causa**: Dados enviados não correspondem à estrutura esperada
- **Solução**: Verifique se todos os campos obrigatórios estão sendo enviados

## 📋 Regras Configuradas

Atualmente, as seguintes coleções têm permissões configuradas:

- ✅ `users` - Dados pessoais do usuário
- ✅ `business` - Dados do negócio
  - ✅ `clientes` - Subcoleção
  - ✅ `servicos` - Subcoleção
  - ✅ `pecas` - Subcoleção
  - ✅ `orcamentos` - Subcoleção
  - ✅ `agendamentos` - Subcoleção
  - ✅ `recibos` - Subcoleção
  - ✅ `despesas` - Subcoleção
- ✅ `transacoes` - **NOVA** - Transações financeiras (receitas/despesas)

## 🔐 Segurança

Todas as regras garantem que:
- ✅ Apenas usuários autenticados podem acessar dados
- ✅ Cada usuário só acessa seus próprios dados
- ✅ Não há acesso a dados de outros usuários

---

**Última atualização:** 12/11/2025
