import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:orcemais/services/notification_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Serviço singleton para gerenciamento de FCM tokens e notificações push
class MessagingService {
  static MessagingService? _instance;

  factory MessagingService() {
    _instance ??= MessagingService._internal();
    return _instance!;
  }

  MessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String _tokenFcm = '';
  String? _cacheDirectory;

  /// Inicializa o serviço de mensagens e notificações
  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await registerOnFirebase();
    _setupMessageListeners();
  }

  /// Configura notificações locais
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Diretório para cache de imagens
    if (!kIsWeb) {
      final directory = await getTemporaryDirectory();
      _cacheDirectory = directory.path;
    }
  }

  /// Registra o dispositivo no Firebase Cloud Messaging
  Future<void> registerOnFirebase() async {
    // Solicitar permissões
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Permissão de notificação negada pelo usuário');
      return;
    }

    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      debugPrint('Usuário não autenticado, cancelando registro FCM');
      return;
    }

    final userid = firebaseUser.uid;
    final prefs = await SharedPreferences.getInstance();
    _tokenFcm = prefs.getString('pushToken') ?? '';

    // Obter token FCM
    final token = await _firebaseMessaging.getToken();

    if (token != null && token != _tokenFcm && token.isNotEmpty) {
      _tokenFcm = token;
      await prefs.setString('pushToken', _tokenFcm);

      // Salvar no Firestore
      final platform = Platform.isIOS ? 'ios' : 'android';
      await _firestore
          .collection('usuarios')
          .doc(userid)
          .collection('pushTokens')
          .doc(platform)
          .set({
            'token': _tokenFcm,
            'platform': platform,
            'lastUpdate': FieldValue.serverTimestamp(),
          });

      debugPrint('Token FCM registrado: ${_tokenFcm.substring(0, 20)}...');
    }

    // Listener para refresh do token
    _firebaseMessaging.onTokenRefresh
        .listen((newToken) {
          _onTokenRefresh(newToken, userid);
        })
        .onError((error) {
          debugPrint('Erro no refresh do token: $error');
        });
  }

  /// Atualiza token quando ele é renovado
  Future<void> _onTokenRefresh(String newToken, String userid) async {
    if (_tokenFcm != newToken) {
      _tokenFcm = newToken;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pushToken', _tokenFcm);

      final platform = Platform.isIOS ? 'ios' : 'android';
      await _firestore
          .collection('usuarios')
          .doc(userid)
          .collection('pushTokens')
          .doc(platform)
          .set({
            'token': _tokenFcm,
            'platform': platform,
            'lastUpdate': FieldValue.serverTimestamp(),
          });

      debugPrint('Token FCM atualizado: ${_tokenFcm.substring(0, 20)}...');
    }
  }

  /// Configura listeners para mensagens FCM
  void _setupMessageListeners() {
    // App foi aberto por uma notificação (terminado)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message.data);
      }
    });

    // App em primeiro plano - exibe notificação local
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Mensagem recebida em primeiro plano: ${message.messageId}');
      _showLocalNotification(message);
    });

    // App em segundo plano - usuário tocou na notificação
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        'Notificação tocada (app em background): ${message.messageId}',
      );
      _handleNotificationTap(message.data);
    });
  }

  /// Exibe notificação local quando app está em primeiro plano
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final data = message.data;
    final payload = data['payload'] ?? '';
    final parametro = data['parametro'] ?? '';

    // Gerar ID único para a notificação
    final prefs = await SharedPreferences.getInstance();
    final notificationId = prefs.getInt('lastNotificationId') ?? 0;
    await prefs.setInt('lastNotificationId', notificationId + 1);

    // Configuração Android
    final androidDetails = AndroidNotificationDetails(
      'orcemais_channel',
      'Orcemais Notificações',
      channelDescription: 'Notificações de orçamentos, recibos e agendamentos',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF2196F3),
    );

    // Configuração iOS
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notificationId,
      notification.title,
      notification.body,
      notificationDetails,
      payload: '$payload|$parametro',
    );
  }

  /// Trata o toque em uma notificação local
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      final parts = payload.split('|');
      final action = parts.isNotEmpty ? parts[0] : null;
      final parametro = parts.length > 1 ? parts[1] : null;

      if (action != null) {
        NotificationHandler().handleNotification(action, parametro: parametro);
      }
    }
  }

  /// Trata o toque em uma notificação FCM
  void _handleNotificationTap(Map<String, dynamic> data) {
    final payload = data['payload'];
    final parametro = data['parametro'];

    if (payload != null) {
      NotificationHandler().handleNotification(payload, parametro: parametro);
    }
  }

  /// Download de imagem para notificação (se necessário no futuro)
  Future<String?> _downloadImage(String url) async {
    if (_cacheDirectory == null) return null;

    try {
      final fileName = url.split('/').last;
      final filePath = '$_cacheDirectory/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        return filePath;
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      }
    } catch (e) {
      debugPrint('Erro ao baixar imagem para notificação: $e');
    }

    return null;
  }

  /// Inscreve em um tópico do FCM
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('Inscrito no tópico: $topic');
  }

  /// Cancela inscrição em um tópico do FCM
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('Desincrito do tópico: $topic');
  }
}
