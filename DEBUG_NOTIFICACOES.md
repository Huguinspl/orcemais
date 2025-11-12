# 🔧 DEBUG DE NOTIFICAÇÕES

## Problema Relatado
Agendamento criado às 17:50, mas notificação não apareceu às 17:20.

## Possíveis Causas

### 1. ⚠️ Permissão Não Concedida
**Sintoma:** Notificações nunca aparecem
**Verificação:**
- Pressione o ícone de sino (🔔) na home
- Veja se aparece "Notificações Ativas" ou "Permissão Negada"

**Solução:**
1. Vá em Configurações do Android > Apps > Gestorfy
2. Ative "Notificações"
3. Volte ao app, clique no sino novamente

### 2. 🕐 Notificação Agendada no Passado
**Sintoma:** Logs mostram "horário no passado"
**Causa:** O agendamento foi criado para um horário que já passou

**Exemplo:**
- Hora atual: 17:22
- Agendamento: 17:50
- Notificação seria em: 17:20 (já passou!)

**Solução:** Criar agendamento com pelo menos 35-40 minutos de antecedência

### 3. ⚡ Economia de Bateria do Android
**Sintoma:** Notificações não aparecem quando app está fechado
**Causa:** Android pode bloquear notificações para economizar bateria

**Solução:**
1. Configurações > Bateria > Otimização de bateria
2. Encontre "Gestorfy"
3. Selecione "Não otimizar"

### 4. 📱 Modo Não Perturbe Ativo
**Sintoma:** Notificações silenciosas ou não aparecem
**Verificação:** Veja se o ícone de lua está na barra de status

**Solução:**
- Desative o modo "Não Perturbe"
- Ou configure exceções para o Gestorfy

### 5. 🔄 App Reiniciado Após Criar Agendamento
**Sintoma:** Notificações perdidas após reiniciar app
**Causa:** Notificações não persistem entre reinícios (ainda)

**Solução:** Manter app aberto ou implementar reagendamento no boot

## 🧪 Como Testar Notificações

### Teste Imediato (Novo!)
1. Pressione **LONGO** no ícone de sino (🔔) na home
2. Deve aparecer uma notificação instantânea
3. Se aparecer = sistema funcionando! ✅

### Teste com Agendamento Real
1. Crie um agendamento para **daqui 35 minutos**
   - Exemplo: Agora são 18:00, crie para 18:35
   - Notificação deve aparecer às 18:05

2. Aguarde os 5 minutos

3. Verifique se a notificação apareceu

## 📊 Logs de Debug

### Como Ver os Logs (Desenvolvedor)
```bash
flutter run
```

Procure por estas mensagens:
```
=== AGENDANDO NOTIFICAÇÃO ===
Permissão concedida: true
Data/Hora do agendamento: 2025-11-12 17:50:00.000
Data/Hora da notificação: 2025-11-12 17:20:00.000
Agora: 2025-11-12 17:22:00.000
❌ Notificação NÃO agendada: horário no passado
```

### Interpretando os Logs

✅ **Sucesso:**
```
✅ Notificação agendada com SUCESSO!
ID da notificação: 12345678
Minutos até notificação: 5
```

❌ **Erro - Permissão:**
```
Permissão concedida: false
❌ Notificação NÃO agendada: permissão não concedida
```

❌ **Erro - Horário Passado:**
```
❌ Notificação NÃO agendada: horário no passado
Diferença: -2 minutos atrás
```

## ✅ Checklist de Verificação

Antes de criar um agendamento, verifique:

- [ ] Permissão de notificação concedida (clique no sino 🔔)
- [ ] Agendamento tem pelo menos 35 minutos no futuro
- [ ] Modo "Não Perturbe" está desligado
- [ ] App não está em "Otimização de bateria"
- [ ] Status do agendamento é "Confirmado" ou "Pendente"

## 🔍 Diagnóstico Passo a Passo

### Passo 1: Teste Básico
1. Pressione LONGO no sino 🔔
2. Viu notificação imediata? 
   - **SIM** → Sistema OK, vá para Passo 2
   - **NÃO** → Problema de permissão, veja Seção 1

### Passo 2: Teste Agendamento
1. Crie agendamento para **daqui 35 minutos**
2. Veja os logs no terminal (se estiver rodando `flutter run`)
3. Viu "✅ Notificação agendada com SUCESSO!"?
   - **SIM** → Aguarde aparecer
   - **NÃO** → Veja qual erro apareceu nos logs

### Passo 3: Aguarde
- Mantenha o celular **desbloqueado** por alguns minutos
- Se aparecer = tudo OK! 🎉
- Se não aparecer = verifique seções 3 e 4 (bateria e não perturbe)

## 💡 Dicas

### Para Desenvolvedores
- Use `flutter run` para ver logs em tempo real
- Teste com horários próximos (5-10 minutos no futuro)
- Verifique `adb logcat` para erros do sistema Android

### Para Usuários
- Sempre crie agendamentos com antecedência mínima de 40 minutos
- Verifique se o sino mostra "Notificações Ativas"
- Se não funcionar, reinicie o app e tente novamente

## 🚀 Melhorias Futuras

- [ ] Reagendar notificações ao reiniciar o app
- [ ] Persistir notificações no boot do dispositivo
- [ ] Adicionar página de configurações de notificações
- [ ] Opção de escolher antecedência (15, 30, 60 minutos)
- [ ] Histórico de notificações enviadas

---

**Atualizado em:** 12 de novembro de 2025
