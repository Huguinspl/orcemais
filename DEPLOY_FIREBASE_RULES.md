# Como Fazer Deploy das Regras do Firebase

## 🔥 Firestore Rules (NECESSÁRIO)

As regras do Firestore foram criadas no arquivo `firestore.rules`. Para aplicá-las ao Firebase, siga os passos:

### Opção 1: Via Firebase Console (Recomendado)

1. Acesse o [Firebase Console](https://console.firebase.google.com/)
2. Selecione o projeto **gestorfy-app**
3. No menu lateral, vá em **Firestore Database**
4. Clique na aba **Regras** (Rules)
5. **Cole o conteúdo do arquivo `firestore.rules`** no editor
6. Clique em **Publicar** (Publish)

### Opção 2: Via Firebase CLI

Se você tem o Firebase CLI instalado:

```bash
# Instalar Firebase CLI (se ainda não tiver)
npm install -g firebase-tools

# Fazer login
firebase login

# Deploy apenas das regras do Firestore
firebase deploy --only firestore:rules

# Ou deploy completo (regras + indexes)
firebase deploy --only firestore
```

## 📋 Conteúdo das Regras do Firestore

O arquivo `firestore.rules` contém:

- ✅ **Usuários**: Cada usuário só pode ler/escrever seus próprios dados
- ✅ **Negócio**: Dados do negócio isolados por userId
- ✅ **Subcoleções**:
  - `clientes`: Gerenciamento de clientes
  - `servicos`: Catálogo de serviços
  - `pecas`: Peças e materiais
  - `orcamentos`: Orçamentos criados
  - `agendamentos`: Agendamentos de serviços ⭐ (necessário para notificações)
  - `recibos`: Recibos emitidos
  - `despesas`: Controle de despesas

## ⚠️ IMPORTANTE

**Sem as regras do Firestore publicadas, o app não conseguirá:**
- ❌ Criar agendamentos
- ❌ Salvar orçamentos
- ❌ Adicionar clientes
- ❌ Qualquer operação de escrita no Firestore

## ✅ Verificando se as Regras Funcionam

Após publicar as regras:

1. Teste criando um agendamento no app
2. Verifique no console do app se não há erros de permissão
3. Confirme no Firebase Console que os dados foram salvos

## 🔒 Segurança

As regras implementadas garantem:
- ✅ Apenas usuários autenticados podem acessar dados
- ✅ Cada usuário só acessa seus próprios dados
- ✅ Isolamento completo entre usuários diferentes
- ✅ Proteção contra acesso não autorizado

---

**Próximo passo:** Faça o deploy das regras usando uma das opções acima!
