import 'package:cloud_firestore/cloud_firestore.dart';
import 'cliente.dart';
import 'valor_recebido.dart';

class Recibo {
  final String id;
  final int numero;
  final String? orcamentoId; // Opcional: permite recibo sem orçamento
  final int? orcamentoNumero;
  final Cliente cliente; // snapshot do cliente no momento
  final List<Map<String, dynamic>> itens; // serviços/produtos opcionais
  final List<ValorRecebido> valoresRecebidos;
  final double subtotalItens; // soma itens
  final double totalValoresRecebidos; // soma recebimentos
  final double
  valorTotal; // regra: se itens >0 usa subtotalItens, senão totalValoresRecebidos
  final String status; // Aberto, Emitido, Cancelado
  final Timestamp criadoEm;
  final Timestamp atualizadoEm;

  Recibo({
    required this.id,
    required this.numero,
    this.orcamentoId, // Opcional
    this.orcamentoNumero,
    required this.cliente,
    required this.itens,
    required this.valoresRecebidos,
    required this.subtotalItens,
    required this.totalValoresRecebidos,
    required this.valorTotal,
    required this.status,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  factory Recibo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Recibo(
      id: doc.id,
      numero: data['numero'] ?? 0,
      orcamentoId: data['orcamentoId'], // Pode ser null
      orcamentoNumero: data['orcamentoNumero'],
      cliente: Cliente.fromMap(data['cliente'] ?? {}),
      itens: List<Map<String, dynamic>>.from(data['itens'] ?? []),
      valoresRecebidos:
          (data['valoresRecebidos'] as List? ?? [])
              .map((e) => ValorRecebido.fromMap(Map<String, dynamic>.from(e)))
              .toList(),
      subtotalItens: (data['subtotalItens'] ?? 0).toDouble(),
      totalValoresRecebidos: (data['totalValoresRecebidos'] ?? 0).toDouble(),
      valorTotal: (data['valorTotal'] ?? 0).toDouble(),
      status: data['status'] ?? 'Aberto',
      criadoEm: data['criadoEm'] ?? Timestamp.now(),
      atualizadoEm: data['atualizadoEm'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'numero': numero,
    'orcamentoId': orcamentoId,
    'orcamentoNumero': orcamentoNumero,
    'cliente': cliente.toMap(),
    'itens': itens,
    'valoresRecebidos': valoresRecebidos.map((e) => e.toMap()).toList(),
    'subtotalItens': subtotalItens,
    'totalValoresRecebidos': totalValoresRecebidos,
    'valorTotal': valorTotal,
    'status': status,
    'criadoEm': criadoEm,
    'atualizadoEm': atualizadoEm,
  };

  Recibo copyWith({
    String? id,
    int? numero,
    String? orcamentoId,
    int? orcamentoNumero,
    Cliente? cliente,
    List<Map<String, dynamic>>? itens,
    List<ValorRecebido>? valoresRecebidos,
    double? subtotalItens,
    double? totalValoresRecebidos,
    double? valorTotal,
    String? status,
    Timestamp? criadoEm,
    Timestamp? atualizadoEm,
  }) => Recibo(
    id: id ?? this.id,
    numero: numero ?? this.numero,
    orcamentoId: orcamentoId ?? this.orcamentoId,
    orcamentoNumero: orcamentoNumero ?? this.orcamentoNumero,
    cliente: cliente ?? this.cliente,
    itens: itens ?? this.itens,
    valoresRecebidos: valoresRecebidos ?? this.valoresRecebidos,
    subtotalItens: subtotalItens ?? this.subtotalItens,
    totalValoresRecebidos: totalValoresRecebidos ?? this.totalValoresRecebidos,
    valorTotal: valorTotal ?? this.valorTotal,
    status: status ?? this.status,
    criadoEm: criadoEm ?? this.criadoEm,
    atualizadoEm: atualizadoEm ?? this.atualizadoEm,
  );
}
