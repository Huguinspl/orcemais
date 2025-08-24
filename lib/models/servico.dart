import 'package:cloud_firestore/cloud_firestore.dart';

class Servico {
  final String id;
  final String titulo;
  final String descricao;
  final double preco;
  final String? duracao;
  final String? categoria;
  final String? unidade;
  final double? custo;

  Servico({
    this.id = '',
    required this.titulo,
    this.descricao = '',
    required this.preco,
    this.duracao,
    this.categoria,
    this.unidade,
    this.custo,
  });

  factory Servico.fromMap(Map<String, dynamic> map) {
    return Servico(
      id: map['id'] ?? '',
      titulo: map['nome'] ?? map['titulo'] ?? '',
      preco: (map['preco'] as num?)?.toDouble() ?? 0.0,
      descricao: map['descricao'] ?? '',
      unidade: map['unidade'],
      custo: (map['custo'] as num?)?.toDouble(),
      categoria: map['categoria'],
      duracao: map['duracao'],
    );
  }

  factory Servico.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Servico(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      descricao: data['descricao'] ?? '',
      preco: (data['preco'] ?? 0).toDouble(),
      duracao: data['duracao'],
      categoria: data['categoria'],
      unidade: data['unidade'],
      custo: (data['custo'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descricao': descricao,
      'preco': preco,
      'duracao': duracao,
      'categoria': categoria,
      'unidade': unidade,
      'custo': custo,
    };
  }

  // ✅ CORREÇÃO: Adicionar o método 'copyWith'
  Servico copyWith({
    String? id,
    String? titulo,
    String? descricao,
    double? preco,
    String? duracao,
    String? categoria,
    String? unidade,
    double? custo,
  }) {
    return Servico(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      preco: preco ?? this.preco,
      duracao: duracao ?? this.duracao,
      categoria: categoria ?? this.categoria,
      unidade: unidade ?? this.unidade,
      custo: custo ?? this.custo,
    );
  }
}
