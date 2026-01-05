# Integração Firebase Cloud Messaging (FCM)

## Estrutura Criada

### 1. `messaging_service.dart`
Serviço singleton responsável por:
- ✅ Registrar dispositivo no FCM e obter token
- ✅ Salvar token no Firestore (`users/{uid}/pushTokens/{platform}`)
- ✅ Listener para refresh automático de tokens
- ✅ Exibir notificações locais quando app está em **primeiro plano**
- ✅ Gerenciar inscrição em tópicos FCM

### 2. `notification_handler.dart`
Serviço para tratar ações de notificações:
- ✅ Interpreta payloads recebidos (orcamento, recibo, agendamento, etc)
- ✅ Navega para a página apropriada com base no payload
- ✅ Usa `NavigationService.navigatorKey` para navegação global

### 3. Modificações no `main.dart`
- ✅ Importado `MessagingService` e `NotificationHandler`
- ✅ Chamada `MessagingService().initialize()` no startup
- ✅ Adicionado `navigatorKey` no `GetMaterialApp`

### 4. Modificações no `pubspec.yaml`
- ✅ Adicionado `firebase_messaging: ^16.1.0`

## Fluxo de Funcionamento

### Quando o App Está em Primeiro Plano
1. FCM recebe mensagem
2. `FirebaseMessaging.onMessage` captura
3. `MessagingService._showLocalNotification()` exibe notificação local
4. Usuário toca: `NotificationHandler` navega para destino

### Quando o App Está em Segundo Plano
1. Sistema Android/iOS exibe notificação automaticamente
2. Usuário toca: `FirebaseMessaging.onMessageOpenedApp` captura
3. `NotificationHandler` navega para destino

### Quando o App Foi Terminado
1. Usuário toca na notificação, app abre
2. `FirebaseMessaging.getInitialMessage()` recupera payload
3. `NotificationHandler` navega para destino

## Estrutura de Payloads

```dart
// Exemplo de payload no data da notificação FCM:
{
  "payload": "orcamento",        // Tipo de ação
  "parametro": "orcamento123"    // ID do documento (opcional)
}
```

### Payloads Suportados:
- `orcamento` - Lista ou detalhes de orçamento
- `recibo` - Lista ou detalhes de recibo
- `agendamento` - Calendário ou detalhes de agendamento
- `cliente` - Lista de clientes
- `chat` - Chat/suporte (placeholder)
- `configuracoes` - Tela de configurações
- `novo_orcamento` - Criar orçamento
- `novo_recibo` - Criar recibo
- `novo_agendamento` - Criar agendamento
- `lembrete_agendamento` - Lembrete 30min antes

## Estrutura Firestore

```
users/{uid}/
  ├── pushTokens/
  │   ├── android: { token, platform, lastUpdate }
  │   └── ios: { token, platform, lastUpdate }
```

## Próximos Passos

1. **Testar no dispositivo real** (emulador não recebe notificações):
```powershell
flutter pub get
flutter run -d <device>
```

2. **Enviar notificação de teste via Firebase Console**:
   - Cloud Messaging → New Campaign → Notifications
   - Target: Token específico ou tópico
   - Additional Options → Custom data: 
     - `payload`: `orcamento`
     - `parametro`: `id123`

3. **Integrar com Cloud Functions**:
   - As functions já criadas (`sendNotification`, etc) devem enviar `data` com estrutura correta
   - Exemplo: `{ payload: 'agendamento', parametro: agendamentoId }`

4. **Permissões Android**:
   - ✅ Já configuradas no `AndroidManifest.xml`
   - `POST_NOTIFICATIONS` para Android 13+

## Troubleshooting

- **Token nulo**: Verificar conexão internet e autenticação Firebase Auth
- **Notificações não aparecem**: Verificar permissões nas configurações do app
- **Navegação falha**: Verificar se rotas existem em `AppRoutes`
- **iOS não recebe**: Configurar APNs no Firebase Console
