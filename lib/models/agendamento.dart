import 'package:cloud_firestore/cloud_firestore.dart';

class Agendamento {
  final String id;
  final String orcamentoId; // Referência ao orçamento vinculado
  final int?
  orcamentoNumero; // Número do orçamento (denormalizado p/ exibição rápida)
  final String? clienteNome; // Nome do cliente (denormalizado)
  final Timestamp dataHora; // Data e hora do agendamento
  final String status; // Pendente, Confirmado, Concluido, Cancelado
  final String observacoes;
  final Timestamp criadoEm;
  final Timestamp atualizadoEm;

  Agendamento({
    required this.id,
    required this.orcamentoId,
    required this.dataHora,
    required this.status,
    required this.observacoes,
    required this.criadoEm,
    required this.atualizadoEm,
    this.orcamentoNumero,
    this.clienteNome,
  });

  factory Agendamento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Agendamento(
      id: doc.id,
      orcamentoId: data['orcamentoId'] ?? '',
      orcamentoNumero: data['orcamentoNumero'],
      clienteNome: data['clienteNome'],
      dataHora: data['dataHora'] ?? Timestamp.now(),
      status: data['status'] ?? 'Pendente',
      observacoes: data['observacoes'] ?? '',
      criadoEm: data['criadoEm'] ?? Timestamp.now(),
      atualizadoEm: data['atualizadoEm'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orcamentoId': orcamentoId,
      'orcamentoNumero': orcamentoNumero,
      'clienteNome': clienteNome,
      'dataHora': dataHora,
      'status': status,
      'observacoes': observacoes,
      'criadoEm': criadoEm,
      'atualizadoEm': atualizadoEm,
    };
  }

  Agendamento copyWith({
    String? id,
    String? orcamentoId,
    int? orcamentoNumero,
    String? clienteNome,
    Timestamp? dataHora,
    String? status,
    String? observacoes,
    Timestamp? criadoEm,
    Timestamp? atualizadoEm,
  }) {
    return Agendamento(
      id: id ?? this.id,
      orcamentoId: orcamentoId ?? this.orcamentoId,
      orcamentoNumero: orcamentoNumero ?? this.orcamentoNumero,
      clienteNome: clienteNome ?? this.clienteNome,
      dataHora: dataHora ?? this.dataHora,
      status: status ?? this.status,
      observacoes: observacoes ?? this.observacoes,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}
