import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BusinessProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ---- estado local ----
  String nomeEmpresa = '';
  String telefone = '';
  String ramo = '';
  String endereco = '';
  String cnpj = '';
  String emailEmpresa = '';

  String get _uid => _auth.currentUser?.uid ?? '';

  /* ================== LER do Firestore ================== */
  Future<void> carregarDoFirestore() async {
    if (_uid.isEmpty) return;

    final doc = await _db.doc('users/$_uid/meta/business').get();

    if (doc.exists) {
      final d = doc.data()!;
      nomeEmpresa = d['nomeEmpresa'] ?? '';
      telefone = d['telefone'] ?? '';
      ramo = d['ramo'] ?? '';
      endereco = d['endereco'] ?? '';
      cnpj = d['cnpj'] ?? '';
      emailEmpresa = d['emailEmpresa'] ?? '';
    } else {
      limparDados(); // <- limpa os dados ao logar com conta nova
    }

    notifyListeners();
  }

  /* ================== GRAVAR no Firestore ================== */
  Future<void> salvarNoFirestore({
    required String nomeEmpresa,
    required String telefone,
    required String ramo,
    required String endereco,
    required String cnpj,
    required String emailEmpresa,
  }) async {
    if (_uid.isEmpty) return;

    await _db.doc('users/$_uid/meta/business').set({
      'nomeEmpresa': nomeEmpresa,
      'telefone': telefone,
      'ramo': ramo,
      'endereco': endereco,
      'cnpj': cnpj,
      'emailEmpresa': emailEmpresa,
    });

    // Atualiza estado local
    this.nomeEmpresa = nomeEmpresa;
    this.telefone = telefone;
    this.ramo = ramo;
    this.endereco = endereco;
    this.cnpj = cnpj;
    this.emailEmpresa = emailEmpresa;

    notifyListeners();
  }

  /* ================== LIMPAR estado local ================== */
  void limparDados() {
    nomeEmpresa = '';
    telefone = '';
    ramo = '';
    endereco = '';
    cnpj = '';
    emailEmpresa = '';
    notifyListeners();
  }
}
