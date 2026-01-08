import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/receita.dart';

/// Provider para gerenciar transações financeiras (receitas e despesas)
class TransacoesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Transacao> _transacoes = [];
  bool _isLoading = false;
  String? _erro;

  List<Transacao> get transacoes => _transacoes;
  bool get isLoading => _isLoading;
  String? get erro => _erro;

  /// Retorna apenas receitas (não futuras)
  List<Transacao> get receitas =>
      _transacoes
          .where((t) => t.tipo == TipoTransacao.receita && !t.isFutura)
          .toList();

  /// Retorna apenas despesas (não futuras)
  List<Transacao> get despesas =>
      _transacoes
          .where((t) => t.tipo == TipoTransacao.despesa && !t.isFutura)
          .toList();

  /// Retorna receitas a receber (futuras)
  List<Transacao> get receitasAReceber =>
      _transacoes
          .where((t) => t.tipo == TipoTransacao.receita && t.isFutura)
          .toList();

  /// Retorna despesas a pagar (futuras)
  List<Transacao> get despesasAPagar =>
      _transacoes
          .where((t) => t.tipo == TipoTransacao.despesa && t.isFutura)
          .toList();

  /// Calcula total de receitas (não futuras)
  double get totalReceitas => receitas.fold(0, (sum, t) => sum + t.valor);

  /// Calcula total de despesas (não futuras)
  double get totalDespesas => despesas.fold(0, (sum, t) => sum + t.valor);

  /// Calcula total de receitas a receber
  double get totalReceitasAReceber =>
      receitasAReceber.fold(0, (sum, t) => sum + t.valor);

  /// Calcula total de despesas a pagar
  double get totalDespesasAPagar =>
      despesasAPagar.fold(0, (sum, t) => sum + t.valor);

  /// Calcula saldo (receitas - despesas)
  double get saldo => totalReceitas - totalDespesas;

  /// Calcula saldo futuro (receitas a receber - despesas a pagar)
  double get saldoFuturo => totalReceitasAReceber - totalDespesasAPagar;

  /// Carrega transações do Firestore para um usuário específico
  Future<void> carregarTransacoes(String userId) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      final querySnapshot =
          await _firestore
              .collection('transacoes')
              .where('userId', isEqualTo: userId)
              .orderBy('data', descending: true)
              .get();

      _transacoes =
          querySnapshot.docs
              .map((doc) => Transacao.fromFirestore(doc))
              .toList();

      _erro = null;
    } catch (e) {
      // Se o erro for de índice faltando, usa consulta simples sem ordenação
      if (e.toString().contains('failed-precondition') ||
          e.toString().contains('index')) {
        try {
          debugPrint('⚠️ Índice não encontrado, carregando sem ordenação...');
          final querySnapshot =
              await _firestore
                  .collection('transacoes')
                  .where('userId', isEqualTo: userId)
                  .get();

          _transacoes =
              querySnapshot.docs
                  .map((doc) => Transacao.fromFirestore(doc))
                  .toList();

          // Ordena localmente
          _transacoes.sort((a, b) => b.data.compareTo(a.data));

          _erro =
              'Índice do Firestore pendente. Funcionalidade limitada temporariamente.';
          debugPrint('✅ Transações carregadas sem índice (ordenação local)');
        } catch (e2) {
          _erro = 'Erro ao carregar transações: $e2';
          debugPrint(_erro);
        }
      } else {
        _erro = 'Erro ao carregar transações: $e';
        debugPrint(_erro);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adiciona uma nova transação
  Future<bool> adicionarTransacao(Transacao transacao) async {
    try {
      final docRef = await _firestore
          .collection('transacoes')
          .add(transacao.toMap());

      final novaTransacao = transacao.copyWith(id: docRef.id);
      _transacoes.insert(0, novaTransacao);
      notifyListeners();
      return true;
    } catch (e) {
      _erro = 'Erro ao adicionar transação: $e';
      debugPrint(_erro);
      notifyListeners();
      return false;
    }
  }

  /// Atualiza uma transação existente
  Future<bool> atualizarTransacao(Transacao transacao) async {
    if (transacao.id == null) return false;

    try {
      await _firestore
          .collection('transacoes')
          .doc(transacao.id)
          .update(transacao.toMap());

      final index = _transacoes.indexWhere((t) => t.id == transacao.id);
      if (index != -1) {
        _transacoes[index] = transacao;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _erro = 'Erro ao atualizar transação: $e';
      debugPrint(_erro);
      notifyListeners();
      return false;
    }
  }

  /// Remove uma transação
  Future<bool> removerTransacao(String transacaoId) async {
    try {
      await _firestore.collection('transacoes').doc(transacaoId).delete();

      _transacoes.removeWhere((t) => t.id == transacaoId);
      notifyListeners();
      return true;
    } catch (e) {
      _erro = 'Erro ao remover transação: $e';
      debugPrint(_erro);
      notifyListeners();
      return false;
    }
  }

  /// Retorna transações de um período específico
  List<Transacao> transacoesPorPeriodo(DateTime inicio, DateTime fim) {
    return _transacoes.where((t) {
      return t.data.isAfter(inicio.subtract(const Duration(days: 1))) &&
          t.data.isBefore(fim.add(const Duration(days: 1)));
    }).toList();
  }

  /// Retorna receitas agrupadas por categoria
  Map<CategoriaTransacao, double> receitasPorCategoria() {
    final Map<CategoriaTransacao, double> resultado = {};
    for (var transacao in receitas) {
      resultado[transacao.categoria] =
          (resultado[transacao.categoria] ?? 0) + transacao.valor;
    }
    return resultado;
  }

  /// Retorna despesas agrupadas por categoria
  Map<CategoriaTransacao, double> despesasPorCategoria() {
    final Map<CategoriaTransacao, double> resultado = {};
    for (var transacao in despesas) {
      resultado[transacao.categoria] =
          (resultado[transacao.categoria] ?? 0) + transacao.valor;
    }
    return resultado;
  }

  /// Retorna receitas a receber agrupadas por categoria
  Map<CategoriaTransacao, double> receitasAReceberPorCategoria() {
    final Map<CategoriaTransacao, double> resultado = {};
    for (var transacao in receitasAReceber) {
      resultado[transacao.categoria] =
          (resultado[transacao.categoria] ?? 0) + transacao.valor;
    }
    return resultado;
  }

  /// Retorna despesas a pagar agrupadas por categoria
  Map<CategoriaTransacao, double> despesasAPagarPorCategoria() {
    final Map<CategoriaTransacao, double> resultado = {};
    for (var transacao in despesasAPagar) {
      resultado[transacao.categoria] =
          (resultado[transacao.categoria] ?? 0) + transacao.valor;
    }
    return resultado;
  }

  /// Retorna transações do mês atual
  List<Transacao> transacoesDoMes() {
    final agora = DateTime.now();
    final inicioMes = DateTime(agora.year, agora.month, 1);
    final fimMes = DateTime(agora.year, agora.month + 1, 0);
    return transacoesPorPeriodo(inicioMes, fimMes);
  }

  /// Limpa o erro
  void limparErro() {
    _erro = null;
    notifyListeners();
  }
}
