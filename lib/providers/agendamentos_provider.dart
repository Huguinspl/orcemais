import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/agendamento.dart';
import '../services/notification_service.dart';

class AgendamentosProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<Agendamento> _agendamentos = [];
  List<Agendamento> get agendamentos => _agendamentos;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');
    return user.uid;
  }

  DocumentReference get _businessDocRef =>
      _firestore.collection('business').doc(_uid);
  CollectionReference get _agendamentosRef =>
      _businessDocRef.collection('agendamentos');

  Future<void> carregarAgendamentos() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot =
          await _agendamentosRef.orderBy('dataHora', descending: false).get();
      _agendamentos =
          snapshot.docs.map((d) => Agendamento.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('Erro ao carregar agendamentos: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Agendamento> adicionarAgendamento({
    required String orcamentoId,
    required int? orcamentoNumero,
    required String? clienteNome,
    required Timestamp dataHora,
    String status = 'Pendente',
    String observacoes = '',
  }) async {
    final docRef = _agendamentosRef.doc();
    final agora = Timestamp.now();
    final agendamento = Agendamento(
      id: docRef.id,
      orcamentoId: orcamentoId,
      orcamentoNumero: orcamentoNumero,
      clienteNome: clienteNome,
      dataHora: dataHora,
      status: status,
      observacoes: observacoes,
      criadoEm: agora,
      atualizadoEm: agora,
    );
    await docRef.set(agendamento.toMap());
    _agendamentos.add(agendamento);
    _agendamentos.sort((a, b) => a.dataHora.compareTo(b.dataHora));

    // Agenda notificação se o status for Confirmado ou Pendente
    if (status == 'Confirmado' || status == 'Pendente') {
      await NotificationService().agendarNotificacao(agendamento);
    }

    notifyListeners();
    return agendamento;
  }

  Future<void> atualizarAgendamento(Agendamento agendamento) async {
    final docRef = _agendamentosRef.doc(agendamento.id);
    final atualizado = agendamento.copyWith(atualizadoEm: Timestamp.now());
    await docRef.update(atualizado.toMap());
    final idx = _agendamentos.indexWhere((a) => a.id == agendamento.id);
    if (idx != -1) {
      _agendamentos[idx] = atualizado;
      _agendamentos.sort((a, b) => a.dataHora.compareTo(b.dataHora));

      // Reagenda notificação se status for Confirmado ou Pendente
      if (atualizado.status == 'Confirmado' ||
          atualizado.status == 'Pendente') {
        await NotificationService().agendarNotificacao(atualizado);
      } else {
        // Cancela notificação se status mudou para Concluido ou Cancelado
        await NotificationService().cancelarNotificacao(atualizado.id);
      }

      notifyListeners();
    }
  }

  Future<void> atualizarStatus(String id, String status) async {
    final docRef = _agendamentosRef.doc(id);
    final agora = Timestamp.now();
    await docRef.update({'status': status, 'atualizadoEm': agora});
    final idx = _agendamentos.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _agendamentos[idx] = _agendamentos[idx].copyWith(
        status: status,
        atualizadoEm: agora,
      );

      // Reagenda ou cancela notificação baseado no status
      if (status == 'Confirmado' || status == 'Pendente') {
        await NotificationService().agendarNotificacao(_agendamentos[idx]);
      } else {
        await NotificationService().cancelarNotificacao(id);
      }

      notifyListeners();
    }
  }

  Future<void> excluirAgendamento(String id) async {
    await _agendamentosRef.doc(id).delete();

    // Cancela a notificação associada
    await NotificationService().cancelarNotificacao(id);

    _agendamentos.removeWhere((a) => a.id == id);
    notifyListeners();
  }
}
