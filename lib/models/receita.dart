import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum para tipo de transação
enum TipoTransacao { receita, despesa }

/// Enum para categoria de transação
enum CategoriaTransacao {
  // Receitas
  vendas,
  servicos,
  investimentos,
  outros,

  // Despesas
  fornecedores,
  salarios,
  aluguel,
  marketing,
  equipamentos,
  impostos,
  utilities,
  manutencao,
}

/// Modelo para representar uma transação financeira (receita ou despesa)
class Transacao {
  final String? id;
  final String descricao;
  final double valor;
  final TipoTransacao tipo;
  final CategoriaTransacao categoria;
  final DateTime data;
  final String? observacoes;
  final String userId;
  final DateTime criadoEm;
  final bool isFutura; // true = receita a receber / despesa a pagar

  Transacao({
    this.id,
    required this.descricao,
    required this.valor,
    required this.tipo,
    required this.categoria,
    required this.data,
    this.observacoes,
    required this.userId,
    DateTime? criadoEm,
    this.isFutura = false,
  }) : criadoEm = criadoEm ?? DateTime.now();

  /// Converte para Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'descricao': descricao,
      'valor': valor,
      'tipo': tipo.name,
      'categoria': categoria.name,
      'data': Timestamp.fromDate(data),
      'observacoes': observacoes,
      'userId': userId,
      'criadoEm': Timestamp.fromDate(criadoEm),
      'isFutura': isFutura,
    };
  }

  /// Cria uma instância a partir do Firestore
  factory Transacao.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Transacao(
      id: doc.id,
      descricao: data['descricao'] ?? '',
      valor: (data['valor'] ?? 0).toDouble(),
      tipo: TipoTransacao.values.firstWhere(
        (e) => e.name == data['tipo'],
        orElse: () => TipoTransacao.receita,
      ),
      categoria: CategoriaTransacao.values.firstWhere(
        (e) => e.name == data['categoria'],
        orElse: () => CategoriaTransacao.outros,
      ),
      data: (data['data'] as Timestamp).toDate(),
      observacoes: data['observacoes'],
      userId: data['userId'] ?? '',
      criadoEm: (data['criadoEm'] as Timestamp).toDate(),
      isFutura: data['isFutura'] ?? false,
    );
  }

  /// Cria uma cópia com valores alterados
  Transacao copyWith({
    String? id,
    String? descricao,
    double? valor,
    TipoTransacao? tipo,
    CategoriaTransacao? categoria,
    DateTime? data,
    String? observacoes,
    String? userId,
    DateTime? criadoEm,
    bool? isFutura,
  }) {
    return Transacao(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      valor: valor ?? this.valor,
      tipo: tipo ?? this.tipo,
      categoria: categoria ?? this.categoria,
      data: data ?? this.data,
      observacoes: observacoes ?? this.observacoes,
      userId: userId ?? this.userId,
      criadoEm: criadoEm ?? this.criadoEm,
      isFutura: isFutura ?? this.isFutura,
    );
  }
}

/// Extensões para facilitar uso das enums
extension CategoriaTransacaoExtension on CategoriaTransacao {
  String get nome {
    switch (this) {
      case CategoriaTransacao.vendas:
        return 'Vendas';
      case CategoriaTransacao.servicos:
        return 'Serviços';
      case CategoriaTransacao.investimentos:
        return 'Investimentos';
      case CategoriaTransacao.outros:
        return 'Outros';
      case CategoriaTransacao.fornecedores:
        return 'Fornecedores';
      case CategoriaTransacao.salarios:
        return 'Salários';
      case CategoriaTransacao.aluguel:
        return 'Aluguel';
      case CategoriaTransacao.marketing:
        return 'Marketing';
      case CategoriaTransacao.equipamentos:
        return 'Equipamentos';
      case CategoriaTransacao.impostos:
        return 'Impostos';
      case CategoriaTransacao.utilities:
        return 'Contas (Água, Luz, etc)';
      case CategoriaTransacao.manutencao:
        return 'Manutenção';
    }
  }

  bool get isReceita {
    return [
      CategoriaTransacao.vendas,
      CategoriaTransacao.servicos,
      CategoriaTransacao.investimentos,
      CategoriaTransacao.outros,
    ].contains(this);
  }

  bool get isDespesa => !isReceita;
}
