# Sistema de Notificações - Gestorfy

## ✨ Funcionalidades Implementadas

### 🔔 Notificações de Agendamentos
O app agora possui um sistema completo de notificações que alerta o usuário **30 minutos antes** de cada agendamento confirmado.

### 📱 Como Usar

1. **Ativar Notificações**
   - Na tela inicial (Home), clique no ícone de sino (🔔) no canto superior direito
   - O app solicitará permissão para enviar notificações
   - Aceite a permissão quando solicitado

2. **Criar Agendamento**
   - Vá para a página de Agendamentos
   - Crie um novo agendamento com status "Confirmado" ou "Pendente"
   - O sistema automaticamente agenda uma notificação para 30 minutos antes

3. **Receber Notificações**
   - 30 minutos antes do horário agendado, você receberá uma notificação
   - A notificação mostra:
     - Título: "⏰ Agendamento em 30 minutos!"
     - Descrição: Nome do cliente e horário do serviço

### 🎯 Recursos

- ✅ **Permissão inteligente**: Verifica se o usuário já concedeu permissão
- ✅ **Agendamento automático**: Notificações são criadas automaticamente ao criar/editar agendamentos
- ✅ **Gerenciamento de status**: 
  - Notificações são agendadas para status "Confirmado" e "Pendente"
  - Notificações são canceladas quando status muda para "Concluído" ou "Cancelado"
- ✅ **Exclusão inteligente**: Ao excluir um agendamento, a notificação associada é cancelada
- ✅ **Sincronização**: Ao ativar notificações, todas as notificações pendentes são reagendadas

### 🔧 Detalhes Técnicos

#### Arquivos Criados/Modificados

1. **`lib/services/notification_service.dart`**
   - Serviço completo de gerenciamento de notificações
   - Usa `flutter_local_notifications` e `timezone`
   - Suporta Android e iOS

2. **`lib/providers/agendamentos_provider.dart`**
   - Integrado com NotificationService
   - Agenda notificações ao criar/atualizar agendamentos
   - Cancela notificações ao excluir ou mudar status

3. **`lib/pages/home/home_page.dart`**
   - Botão de notificações funcional
   - Diálogo moderno de solicitação de permissão
   - Feedback visual sobre status das notificações

4. **`lib/main.dart`**
   - Inicialização do serviço de notificações no startup

5. **`android/app/src/main/AndroidManifest.xml`**
   - Permissões Android para notificações
   - Receivers para notificações agendadas
   - Suporte para notificações após reinicialização

6. **`pubspec.yaml`**
   - Adicionado `timezone: ^0.9.4`

### 📋 Dependências

- `flutter_local_notifications: ^18.0.1` ✅ (já estava)
- `timezone: ^0.9.4` ✅ (adicionado)

### 🚀 Próximos Passos Sugeridos

- [ ] Adicionar som personalizado para notificações
- [ ] Permitir usuário escolher o tempo de antecedência (15, 30, 60 minutos)
- [ ] Adicionar notificação adicional 1 dia antes
- [ ] Página de histórico de notificações enviadas
- [ ] Configurações de notificações (ativar/desativar por tipo)

### 🐛 Troubleshooting

**Notificações não aparecem:**
1. Verifique se deu permissão nas configurações do app
2. Certifique-se que o agendamento está com status "Confirmado" ou "Pendente"
3. Verifique se o horário do agendamento não está no passado

**Erro ao agendar:**
- Verifique se o horário do agendamento é futuro
- Notificações com horário no passado não são agendadas

### 📱 Testando

Para testar rapidamente:
1. Crie um agendamento para daqui a 40 minutos com status "Confirmado"
2. O sistema agendará uma notificação para 30 minutos antes (daqui a 10 minutos)
3. Aguarde e a notificação aparecerá

---

**Desenvolvido com ❤️ para Gestorfy**
