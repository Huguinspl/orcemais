import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/agendamento.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _permissionGranted = false;

  bool get isInitialized => _isInitialized;
  bool get permissionGranted => _permissionGranted;

  /// Inicializa o serviço de notificações
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Inicializa os timezones
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    // Configurações para Android
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // Configurações para iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  /// Solicita permissão ao usuário
  Future<bool> requestPermission() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Android 13+ requer permissão explícita
    final androidPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      _permissionGranted = granted ?? false;
    } else {
      _permissionGranted = true; // Android antigo não precisa
    }

    // iOS requer permissão
    final iosPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      _permissionGranted = granted ?? false;
    }

    return _permissionGranted;
  }

  /// Callback quando notificação é tocada
  void _onNotificationTapped(NotificationResponse response) {
    // Aqui você pode navegar para a página de agendamentos
    // ou exibir detalhes do agendamento
    print('Notificação tocada: ${response.payload}');
  }

  /// Agenda notificação para um agendamento (30 minutos antes)
  Future<void> agendarNotificacao(Agendamento agendamento) async {
    print('=== AGENDANDO NOTIFICAÇÃO ===');
    print('Permissão concedida: $_permissionGranted');

    if (!_permissionGranted) {
      print('❌ Notificação NÃO agendada: permissão não concedida');
      return;
    }

    // Converte Timestamp para DateTime
    final dataHoraAgendamento = agendamento.dataHora.toDate();
    print('Data/Hora do agendamento: $dataHoraAgendamento');

    // Calcula 30 minutos antes
    final dataHoraNotificacao = dataHoraAgendamento.subtract(
      const Duration(minutes: 30),
    );
    print('Data/Hora da notificação: $dataHoraNotificacao');

    // Verifica se a notificação não está no passado
    final agora = DateTime.now();
    print('Agora: $agora');

    if (dataHoraNotificacao.isBefore(agora)) {
      print('❌ Notificação NÃO agendada: horário no passado');
      print(
        'Diferença: ${agora.difference(dataHoraNotificacao).inMinutes} minutos atrás',
      );
      return;
    }

    // Converte para timezone
    final tzDateTime = tz.TZDateTime.from(dataHoraNotificacao, tz.local);
    print('TZDateTime: $tzDateTime');

    // Detalhes da notificação para Android
    final androidDetails = AndroidNotificationDetails(
      'agendamentos_channel',
      'Agendamentos',
      channelDescription: 'Notificações de agendamentos de serviços',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    // Detalhes da notificação para iOS
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification.aiff',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Formata a hora do agendamento
    final hora =
        '${dataHoraAgendamento.hour.toString().padLeft(2, '0')}:${dataHoraAgendamento.minute.toString().padLeft(2, '0')}';

    // Agenda a notificação
    try {
      await _notifications.zonedSchedule(
        agendamento.id.hashCode, // ID único baseado no ID do agendamento
        '⏰ Agendamento em 30 minutos!',
        'Serviço${agendamento.clienteNome != null ? ' para ${agendamento.clienteNome}' : ''} às $hora',
        tzDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: agendamento.id,
      );

      print('✅ Notificação agendada com SUCESSO!');
      print('ID da notificação: ${agendamento.id.hashCode}');
      print(
        'Minutos até notificação: ${dataHoraNotificacao.difference(agora).inMinutes}',
      );
    } catch (e) {
      print('❌ ERRO ao agendar notificação: $e');
    }
  }

  /// Cancela notificação de um agendamento específico
  Future<void> cancelarNotificacao(String agendamentoId) async {
    await _notifications.cancel(agendamentoId.hashCode);
    print('Notificação cancelada: $agendamentoId');
  }

  /// Cancela todas as notificações
  Future<void> cancelarTodasNotificacoes() async {
    await _notifications.cancelAll();
    print('Todas as notificações canceladas');
  }

  /// Reagenda todas as notificações ativas
  Future<void> reagendarNotificacoes(List<Agendamento> agendamentos) async {
    if (!_permissionGranted) return;

    // Cancela todas as notificações existentes
    await cancelarTodasNotificacoes();

    // Reagenda notificações para agendamentos confirmados e pendentes
    for (final agendamento in agendamentos) {
      if (agendamento.status == 'Confirmado' ||
          agendamento.status == 'Pendente') {
        await agendarNotificacao(agendamento);
      }
    }
  }

  /// Mostra notificação imediata (para testes)
  Future<void> mostrarNotificacaoImediata({
    required String titulo,
    required String corpo,
  }) async {
    if (!_permissionGranted) return;

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Testes',
      channelDescription: 'Canal para notificações de teste',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecond,
      titulo,
      corpo,
      notificationDetails,
    );
  }
}
