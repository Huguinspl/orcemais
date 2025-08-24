import 'package:cloud_firestore/cloud_firestore.dart';
import 'cliente.dart';

class Despesa {
  final String id;
  final int numero; // sequência incremental
  final Timestamp data;
  final double valor;
  final String formaPagamento; // Pix, Dinheiro, Cartão, etc
  final String? orcamentoId;
  final int? orcamentoNumero;
  final Cliente? cliente; // opcional
  final String descricao;
  final Timestamp criadoEm;
  final Timestamp atualizadoEm;

  Despesa({
    required this.id,
    required this.numero,
    required this.data,
    required this.valor,
    required this.formaPagamento,
    required this.orcamentoId,
    required this.orcamentoNumero,
    required this.cliente,
    required this.descricao,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  factory Despesa.fromFirestore(DocumentSnapshot doc) {
    final dataMap = doc.data() as Map<String, dynamic>? ?? {};
    return Despesa(
      id: doc.id,
      numero: dataMap['numero'] ?? 0,
      data: dataMap['data'] ?? Timestamp.now(),
      valor: (dataMap['valor'] ?? 0).toDouble(),
      formaPagamento: dataMap['formaPagamento'] ?? 'Dinheiro',
      orcamentoId: dataMap['orcamentoId'],
      orcamentoNumero: dataMap['orcamentoNumero'],
      cliente:
          dataMap['cliente'] != null
              ? Cliente.fromMap(Map<String, dynamic>.from(dataMap['cliente']))
              : null,
      descricao: dataMap['descricao'] ?? '',
      criadoEm: dataMap['criadoEm'] ?? Timestamp.now(),
      atualizadoEm: dataMap['atualizadoEm'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'numero': numero,
    'data': data,
    'valor': valor,
    'formaPagamento': formaPagamento,
    'orcamentoId': orcamentoId,
    'orcamentoNumero': orcamentoNumero,
    'cliente': cliente?.toMap(),
    'descricao': descricao,
    'criadoEm': criadoEm,
    'atualizadoEm': atualizadoEm,
  };

  Despesa copyWith({
    String? id,
    int? numero,
    Timestamp? data,
    double? valor,
    String? formaPagamento,
    String? orcamentoId,
    int? orcamentoNumero,
    Cliente? cliente,
    String? descricao,
    Timestamp? criadoEm,
    Timestamp? atualizadoEm,
  }) => Despesa(
    id: id ?? this.id,
    numero: numero ?? this.numero,
    data: data ?? this.data,
    valor: valor ?? this.valor,
    formaPagamento: formaPagamento ?? this.formaPagamento,
    orcamentoId: orcamentoId ?? this.orcamentoId,
    orcamentoNumero: orcamentoNumero ?? this.orcamentoNumero,
    cliente: cliente ?? this.cliente,
    descricao: descricao ?? this.descricao,
    criadoEm: criadoEm ?? this.criadoEm,
    atualizadoEm: atualizadoEm ?? this.atualizadoEm,
  );
}
