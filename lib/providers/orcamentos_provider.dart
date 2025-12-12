import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/orcamento.dart';

class OrcamentosProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Orcamento> _orcamentos = [];
  List<Orcamento> get orcamentos => _orcamentos;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Controle de paginação - carrega apenas os 15 mais recentes inicialmente
  static const int _limitePorPagina = 15;
  bool _temMaisAntigos = false;
  bool get temMaisAntigos => _temMaisAntigos;

  // Flag para indicar se está buscando mais antigos
  bool _buscandoMais = false;
  bool get buscandoMais => _buscandoMais;

  // Total real de orçamentos no banco de dados
  int _totalOrcamentos = 0;
  int get totalOrcamentos => _totalOrcamentos;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');
    return user.uid;
  }

  // Referências do Firestore para simplificar o código
  DocumentReference get _businessDocRef =>
      _firestore.collection('business').doc(_uid);
  CollectionReference get _orcamentosRef =>
      _businessDocRef.collection('orcamentos');

  // ✅ IMPLEMENTAÇÃO 1: Lógica de numeração automática com transação
  Future<Orcamento> adicionarOrcamento(Orcamento orcamento) async {
    // Uma transação garante que a leitura do contador e a gravação do novo número
    // aconteçam de forma atômica, evitando números duplicados.
    return await _firestore.runTransaction((transaction) async {
      // 1. Pega os dados do negócio para ler o contador atual
      final businessDoc = await transaction.get(_businessDocRef);
      final ultimoNumero = businessDoc.data() as Map<String, dynamic>?;
      final novoNumero = (ultimoNumero?['ultimoOrcamentoNum'] as int? ?? 0) + 1;

      // 2. Cria a referência para o novo orçamento
      final docRef = _orcamentosRef.doc();

      final novoOrcamento = Orcamento(
        id: docRef.id,
        numero: novoNumero, // Atribui o novo número sequencial
        cliente: orcamento.cliente,
        itens: orcamento.itens,
        subtotal: orcamento.subtotal,
        desconto: orcamento.desconto,
        valorTotal: orcamento.valorTotal,
        status: orcamento.status,
        dataCriacao: orcamento.dataCriacao,
        metodoPagamento: orcamento.metodoPagamento,
        parcelas: orcamento.parcelas,
        laudoTecnico: orcamento.laudoTecnico,
        condicoesContratuais: orcamento.condicoesContratuais,
        garantia: orcamento.garantia,
        informacoesAdicionais: orcamento.informacoesAdicionais,
        fotos: orcamento.fotos, // ✅ ADICIONADO: Inclui as fotos
      );

      // 3. Dentro da mesma transação, salva o novo orçamento e atualiza o contador
      transaction.set(docRef, novoOrcamento.toMap());
      transaction.update(_businessDocRef, {'ultimoOrcamentoNum': novoNumero});

      // Adiciona na lista local para atualização instantânea da UI
      _orcamentos.insert(0, novoOrcamento);
      _totalOrcamentos++;
      notifyListeners();

      return novoOrcamento;
    });
  }

  // ✅ IMPLEMENTAÇÃO 2: Novo método para atualizar apenas o status
  Future<void> atualizarStatus(String orcamentoId, String novoStatus) async {
    await _orcamentosRef.doc(orcamentoId).update({'status': novoStatus});

    // Atualiza também o snapshot compartilhado (se existir)
    await atualizarStatusSnapshot(orcamentoId, novoStatus);

    // Atualiza o item na lista local para a UI refletir a mudança instantaneamente
    final index = _orcamentos.indexWhere((o) => o.id == orcamentoId);
    if (index != -1) {
      final orcamentoAntigo = _orcamentos[index];
      // Cria uma nova instância com o status atualizado
      _orcamentos[index] = Orcamento(
        id: orcamentoAntigo.id,
        numero: orcamentoAntigo.numero,
        cliente: orcamentoAntigo.cliente,
        itens: orcamentoAntigo.itens,
        subtotal: orcamentoAntigo.subtotal,
        desconto: orcamentoAntigo.desconto,
        valorTotal: orcamentoAntigo.valorTotal,
        status: novoStatus, // <-- novo status
        dataCriacao: orcamentoAntigo.dataCriacao,
        metodoPagamento: orcamentoAntigo.metodoPagamento,
        parcelas: orcamentoAntigo.parcelas,
        laudoTecnico: orcamentoAntigo.laudoTecnico,
        condicoesContratuais: orcamentoAntigo.condicoesContratuais,
        garantia: orcamentoAntigo.garantia,
        informacoesAdicionais: orcamentoAntigo.informacoesAdicionais,
        fotos: orcamentoAntigo.fotos, // ✅ ADICIONADO: Mantém as fotos
      );
      notifyListeners();
    }
  }

  Future<void> atualizarOrcamento(Orcamento orcamento) async {
    await _orcamentosRef.doc(orcamento.id).update(orcamento.toMap());
    final index = _orcamentos.indexWhere((o) => o.id == orcamento.id);
    if (index != -1) {
      _orcamentos[index] = orcamento;
      notifyListeners();
    }
  }

  // Método para atualizar apenas o link web do orçamento
  Future<void> atualizarLinkWeb(String orcamentoId, String linkWeb) async {
    await _orcamentosRef.doc(orcamentoId).update({'linkWeb': linkWeb});

    final index = _orcamentos.indexWhere((o) => o.id == orcamentoId);
    if (index != -1) {
      final orcamentoAntigo = _orcamentos[index];
      _orcamentos[index] = Orcamento(
        id: orcamentoAntigo.id,
        numero: orcamentoAntigo.numero,
        cliente: orcamentoAntigo.cliente,
        itens: orcamentoAntigo.itens,
        subtotal: orcamentoAntigo.subtotal,
        desconto: orcamentoAntigo.desconto,
        valorTotal: orcamentoAntigo.valorTotal,
        status: orcamentoAntigo.status,
        dataCriacao: orcamentoAntigo.dataCriacao,
        metodoPagamento: orcamentoAntigo.metodoPagamento,
        parcelas: orcamentoAntigo.parcelas,
        laudoTecnico: orcamentoAntigo.laudoTecnico,
        condicoesContratuais: orcamentoAntigo.condicoesContratuais,
        garantia: orcamentoAntigo.garantia,
        informacoesAdicionais: orcamentoAntigo.informacoesAdicionais,
        fotos: orcamentoAntigo.fotos,
        linkWeb: linkWeb, // ✅ Atualiza apenas o link web
      );
      notifyListeners();
    }
  }

  Future<void> excluirOrcamento(String orcamentoId) async {
    await _orcamentosRef.doc(orcamentoId).delete();
    _orcamentos.removeWhere((o) => o.id == orcamentoId);
    _totalOrcamentos = _totalOrcamentos > 0 ? _totalOrcamentos - 1 : 0;
    notifyListeners();
  }

  Future<void> carregarOrcamentos() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Busca o total de orçamentos primeiro (apenas contagem)
      final totalSnapshot = await _orcamentosRef.count().get();
      _totalOrcamentos = totalSnapshot.count ?? 0;

      // Carrega apenas os 15 mais recentes + 1 para verificar se há mais
      final snapshot =
          await _orcamentosRef
              .orderBy('dataCriacao', descending: true)
              .limit(_limitePorPagina + 1)
              .get();

      final docs = snapshot.docs;

      // Verifica se há mais orçamentos além dos 15
      if (docs.length > _limitePorPagina) {
        _temMaisAntigos = true;
        _orcamentos =
            docs
                .take(_limitePorPagina)
                .map((doc) => Orcamento.fromFirestore(doc))
                .toList();
      } else {
        _temMaisAntigos = false;
        _orcamentos = docs.map((doc) => Orcamento.fromFirestore(doc)).toList();
      }
    } catch (e) {
      debugPrint("Erro ao carregar orçamentos: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Busca orçamentos por termo (cliente nome ou número)
  Future<List<Orcamento>> buscarOrcamentos(String termo) async {
    if (termo.isEmpty) return [];

    _buscandoMais = true;
    notifyListeners();

    try {
      // Busca todos os orçamentos para filtrar localmente
      final snapshot =
          await _orcamentosRef.orderBy('dataCriacao', descending: true).get();

      final todosOrcamentos =
          snapshot.docs.map((doc) => Orcamento.fromFirestore(doc)).toList();

      // Filtra por nome do cliente ou número do orçamento
      final termoLower = termo.toLowerCase();
      final resultados =
          todosOrcamentos.where((o) {
            final nomeMatch = o.cliente.nome.toLowerCase().contains(termoLower);
            final numeroMatch = o.numero.toString().contains(termo);
            return nomeMatch || numeroMatch;
          }).toList();

      _buscandoMais = false;
      notifyListeners();

      return resultados;
    } catch (e) {
      debugPrint("Erro ao buscar orçamentos: $e");
      _buscandoMais = false;
      notifyListeners();
      return [];
    }
  }

  /// Carrega mais orçamentos antigos (todos)
  Future<void> carregarTodosOrcamentos() async {
    _buscandoMais = true;
    notifyListeners();

    try {
      final snapshot =
          await _orcamentosRef.orderBy('dataCriacao', descending: true).get();

      _orcamentos =
          snapshot.docs.map((doc) => Orcamento.fromFirestore(doc)).toList();
      _temMaisAntigos = false;
    } catch (e) {
      debugPrint("Erro ao carregar todos orçamentos: $e");
    }

    _buscandoMais = false;
    notifyListeners();
  }

  /// Salva um snapshot completo do orçamento para carregamento rápido no link web
  /// Inclui todos os dados do orçamento + dados do negócio
  Future<void> salvarSnapshotCompartilhamento({
    required Orcamento orcamento,
    required Map<String, dynamic> businessInfo,
    required String linkWeb,
  }) async {
    final sharedDocRef = _firestore
        .collection('shared_documents')
        .doc(orcamento.id);

    await sharedDocRef.set({
      'userId': _uid,
      'tipoDocumento': 'orcamento',
      'linkWeb': linkWeb,
      'criadoEm': FieldValue.serverTimestamp(),
      // Dados do orçamento
      'orcamento': {
        'id': orcamento.id,
        'numero': orcamento.numero,
        'cliente': orcamento.cliente.toMap(),
        'itens': orcamento.itens,
        'subtotal': orcamento.subtotal,
        'desconto': orcamento.desconto,
        'valorTotal': orcamento.valorTotal,
        'status': orcamento.status,
        'dataCriacao': orcamento.dataCriacao,
        'metodoPagamento': orcamento.metodoPagamento,
        'parcelas': orcamento.parcelas,
        'laudoTecnico': orcamento.laudoTecnico,
        'condicoesContratuais': orcamento.condicoesContratuais,
        'garantia': orcamento.garantia,
        'informacoesAdicionais': orcamento.informacoesAdicionais,
        'fotos': orcamento.fotos,
      },
      // Dados do negócio (snapshot no momento do compartilhamento)
      'businessInfo': businessInfo,
    });

    debugPrint(
      '✅ Snapshot de compartilhamento salvo para orçamento ${orcamento.id}',
    );
  }

  /// Atualiza o status do orçamento no snapshot compartilhado
  Future<void> atualizarStatusSnapshot(
    String orcamentoId,
    String novoStatus,
  ) async {
    try {
      final sharedDocRef = _firestore
          .collection('shared_documents')
          .doc(orcamentoId);
      final doc = await sharedDocRef.get();

      if (doc.exists) {
        await sharedDocRef.update({
          'orcamento.status': novoStatus,
          'atualizadoEm': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Status do snapshot atualizado para: $novoStatus');
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao atualizar status do snapshot: $e');
    }
  }
}
