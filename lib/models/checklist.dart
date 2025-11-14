import 'package:cloud_firestore/cloud_firestore.dart';

class ChecklistItem {
  final String id;
  final String descricao;
  bool concluido;

  ChecklistItem({
    required this.id,
    required this.descricao,
    this.concluido = false,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'descricao': descricao, 'concluido': concluido};
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] ?? '',
      descricao: map['descricao'] ?? '',
      concluido: map['concluido'] ?? false,
    );
  }

  ChecklistItem copyWith({String? id, String? descricao, bool? concluido}) {
    return ChecklistItem(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      concluido: concluido ?? this.concluido,
    );
  }
}

class Checklist {
  final String id;
  final String nome;
  final List<ChecklistItem> itens;
  final Timestamp criadoEm;
  final Timestamp? atualizadoEm;

  Checklist({
    required this.id,
    required this.nome,
    required this.itens,
    required this.criadoEm,
    this.atualizadoEm,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'itens': itens.map((item) => item.toMap()).toList(),
      'criadoEm': criadoEm,
      'atualizadoEm': atualizadoEm,
    };
  }

  factory Checklist.fromMap(Map<String, dynamic> map) {
    return Checklist(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      itens:
          (map['itens'] as List<dynamic>?)
              ?.map(
                (item) => ChecklistItem.fromMap(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      criadoEm: map['criadoEm'] ?? Timestamp.now(),
      atualizadoEm: map['atualizadoEm'],
    );
  }

  Checklist copyWith({
    String? id,
    String? nome,
    List<ChecklistItem>? itens,
    Timestamp? criadoEm,
    Timestamp? atualizadoEm,
  }) {
    return Checklist(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      itens: itens ?? this.itens,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }

  int get totalItens => itens.length;
  int get itensConcluidos => itens.where((item) => item.concluido).length;
  double get progresso => totalItens > 0 ? itensConcluidos / totalItens : 0.0;
}
