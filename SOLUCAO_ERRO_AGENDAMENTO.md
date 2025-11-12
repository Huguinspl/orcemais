# 🚨 SOLUÇÃO DO ERRO AO CRIAR AGENDAMENTO

## Problema Identificado

O erro ao criar agendamento ocorre porque **as regras do Firestore não estão configuradas** no Firebase Console.

## ✅ Solução Rápida (5 minutos)

### Passo 1: Acesse o Firebase Console

1. Abra o navegador e vá para: https://console.firebase.google.com/
2. Faça login com sua conta Google
3. Selecione o projeto: **gestorfy-app**

### Passo 2: Configure as Regras do Firestore

1. No menu lateral esquerdo, clique em **"Firestore Database"**
2. Clique na aba **"Regras"** (Rules) no topo
3. **DELETE TODO O CONTEÚDO** que está lá
4. **COPIE E COLE** o código abaixo:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // Regras para usuários (dados pessoais)
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Regras para dados de negócio
    match /business/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Subcolleção de clientes
      match /clientes/{clienteId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Subcolleção de serviços
      match /servicos/{servicoId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Subcolleção de peças/materiais
      match /pecas/{pecaId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Subcolleção de orçamentos
      match /orcamentos/{orcamentoId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Subcolleção de agendamentos
      match /agendamentos/{agendamentoId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Subcolleção de recibos
      match /recibos/{reciboId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Subcolleção de despesas
      match /despesas/{despesaId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Nega acesso a qualquer outro documento
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

5. Clique no botão **"Publicar"** (Publish) no topo da página
6. Aguarde a confirmação "Regras publicadas com sucesso!"

### Passo 3: Teste o App

1. Feche e reabra o app no celular
2. Tente criar um novo agendamento
3. Deve funcionar perfeitamente agora! ✅

## 🎯 O que Essas Regras Fazem?

- ✅ Permite que cada usuário acesse **APENAS seus próprios dados**
- ✅ Garante que usuários autenticados possam criar/ler/atualizar/deletar:
  - Agendamentos
  - Orçamentos
  - Clientes
  - Serviços
  - Peças/Materiais
  - Recibos
  - Despesas
- ✅ **Bloqueia** acesso não autorizado
- ✅ **Impede** que um usuário veja dados de outro usuário

## ⚠️ IMPORTANTE

**Sem essas regras:**
- ❌ Nenhum dado pode ser salvo no Firestore
- ❌ Agendamentos não podem ser criados
- ❌ App mostra erros de permissão

**Com essas regras:**
- ✅ Tudo funciona perfeitamente
- ✅ Dados protegidos e isolados por usuário
- ✅ Notificações de agendamentos funcionam

## 📸 Referência Visual

Procure por essas seções no Firebase Console:

```
Firebase Console
  └── Firestore Database (menu lateral)
       └── Regras (aba no topo)
            └── Editor de texto (cole as regras aqui)
            └── Botão "Publicar" (clique para salvar)
```

## 🆘 Se Ainda Tiver Problemas

1. Certifique-se que está no projeto correto: **gestorfy-app**
2. Verifique se clicou em "Publicar" após colar as regras
3. Feche completamente o app e reabra
4. Verifique se está logado no app

---

**Depois de publicar as regras, o app funcionará 100%!** 🎉
