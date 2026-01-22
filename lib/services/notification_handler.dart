import 'package:flutter/material.dart';
import 'package:orcemais/routes/app_routes.dart';

/// Serviço para tratar ações de notificações e navegar para páginas específicas
class NotificationHandler {
  static NotificationHandler? _instance;

  factory NotificationHandler() {
    _instance ??= NotificationHandler._internal();
    return _instance!;
  }

  NotificationHandler._internal();

  /// Trata o payload da notificação e navega para a página apropriada
  void handleNotification(String payload, {String? parametro}) {
    debugPrint(
      'Tratando notificação - Payload: $payload, Parametro: $parametro',
    );

    // Aguarda um pouco para garantir que o app está pronto
    Future.delayed(const Duration(milliseconds: 500), () {
      _navigateToDestination(payload, parametro);
    });
  }

  /// Navega para o destino com base no payload
  void _navigateToDestination(String payload, String? parametro) {
    final context = _getNavigatorContext();
    if (context == null) {
      debugPrint('Navigator context não disponível');
      return;
    }

    switch (payload) {
      case 'orcamento':
        // Navegar para lista de orçamentos
        Navigator.of(context).pushNamed(AppRoutes.orcamentos);
        break;

      case 'recibo':
        // Navegar para lista de recibos
        Navigator.of(context).pushNamed(AppRoutes.recibos);
        break;

      case 'agendamento':
        // Navegar para lista de agendamentos
        Navigator.of(context).pushNamed(AppRoutes.agendamentos);
        break;

      case 'cliente':
        // Navegar para lista de clientes (usar detalheCliente se tiver parametro)
        if (parametro != null) {
          Navigator.of(
            context,
          ).pushNamed(AppRoutes.detalheCliente, arguments: parametro);
        } else {
          // Não tem rota de lista de clientes, volta pra home
          Navigator.of(context).pushNamed(AppRoutes.home);
        }
        break;

      case 'chat':
        // Navegar para chat/suporte
        Navigator.of(context).pushNamed(AppRoutes.chat);
        break;

      case 'configuracoes':
        // Navegar para perfil (mais próximo de configurações)
        Navigator.of(context).pushNamed(AppRoutes.perfil);
        break;

      case 'novo_orcamento':
        // Criar novo orçamento
        Navigator.of(context).pushNamed(AppRoutes.novoOrcamento);
        break;

      case 'novo_recibo':
        // Criar novo recibo
        Navigator.of(context).pushNamed(AppRoutes.novoRecibo);
        break;

      case 'novo_agendamento':
        // Criar novo agendamento
        Navigator.of(context).pushNamed(AppRoutes.novoAgendamento);
        break;

      case 'lembrete_agendamento':
        // Lembrete de agendamento próximo - vai para lista de agendamentos
        Navigator.of(context).pushNamed(AppRoutes.agendamentos);
        break;

      case 'despesas':
        // Navegar para despesas
        Navigator.of(context).pushNamed(AppRoutes.despesas);
        break;

      case 'checklists':
        // Navegar para checklists
        Navigator.of(context).pushNamed(AppRoutes.checklists);
        break;

      default:
        // Verifica se o payload pode ser um ID de agendamento
        // IDs do Firestore geralmente têm 20+ caracteres alfanuméricos
        if (payload.length >= 20 &&
            RegExp(r'^[a-zA-Z0-9]+$').hasMatch(payload)) {
          debugPrint('Payload parece ser um ID de agendamento: $payload');
          Navigator.of(
            context,
          ).pushNamed(AppRoutes.detalhesAgendamento, arguments: payload);
        } else {
          debugPrint('Payload não reconhecido: $payload');
          // Voltar para home por padrão
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
        }
    }
  }

  /// Obtém o contexto do Navigator principal
  BuildContext? _getNavigatorContext() {
    try {
      // Tentar obter o contexto através da chave global do Navigator
      // (precisa ser configurado no MaterialApp)
      return NavigationService.navigatorKey.currentContext;
    } catch (e) {
      debugPrint('Erro ao obter navigator context: $e');
      return null;
    }
  }

  /// Exibe um diálogo informativo
  void _showInfo(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}

/// Serviço global para acesso à chave do Navigator
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
