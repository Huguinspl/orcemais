import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/business_info.dart';

class BusinessProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authSub;

  DocumentReference<Map<String, dynamic>> get _docRef =>
      _db.doc('business/$_uid');

  // ---- estado local ----
  String nomeEmpresa = '';
  String telefone = '';
  String ramo = '';
  String endereco = '';
  String cnpj = '';
  String emailEmpresa = '';
  String? logoUrl; // salva no Firestore
  String? logoLocalPath; // cache local
  Uint8List? _logoCacheBytes; // bytes em memória

  // Pix
  String? pixTipo; // cpf, cnpj, email, celular, aleatoria
  String? pixChave;

  // Assinatura
  String? assinaturaUrl; // URL no Storage
  String? assinaturaLocalPath; // path local
  Uint8List? _assinaturaCacheBytes;
  // Descrição do negócio
  String? descricao;
  // Tema do PDF (mapa de cores em int ARGB, ex: 0xFFRRGGBB)
  Map<String, dynamic>? pdfTheme;

  String get _uid => _auth.currentUser?.uid ?? '';

  /* ================== LER do Firestore ================== */
  BusinessInfo? _cachedInfo;

  BusinessInfo? get info => _cachedInfo;

  BusinessProvider() {
    // Se já estiver logado ao iniciar o provider
    if (_auth.currentUser != null) {
      // Carrega dados do Firestore (inclui logoUrl)
      // ignorar o resultado; apenas popula estado
      // não aguardar aqui para não travar construtor
      // e evitar race conditions no build inicial
      // (notificações virão quando terminar)
      // ignore: discarded_futures
      carregarDoFirestore();
    }
    // Ouvir mudanças de autenticação para carregar/limpar automaticamente
    _authSub = _auth.authStateChanges().listen((user) {
      if (user != null) {
        // ignore: discarded_futures
        carregarDoFirestore();
      } else {
        // ignore: discarded_futures
        limparDados();
      }
    });
  }

  Future<void> carregarDoFirestore() async {
    if (_uid.isEmpty) return;

    // Limpar dados anteriores ANTES de carregar novos dados
    // para evitar mistura de dados entre contas diferentes
    await limparDados();

    final doc = await _docRef.get();

    if (doc.exists) {
      _cachedInfo = BusinessInfo.fromMap(doc.data()!);
      nomeEmpresa = _cachedInfo!.nomeEmpresa;
      telefone = _cachedInfo!.telefone;
      ramo = _cachedInfo!.ramo;
      endereco = _cachedInfo!.endereco;
      cnpj = _cachedInfo!.cnpj;
      emailEmpresa = _cachedInfo!.emailEmpresa;
      logoUrl = _cachedInfo!.logoUrl;
      pixTipo = _cachedInfo!.pixTipo;
      pixChave = _cachedInfo!.pixChave;
      assinaturaUrl = _cachedInfo!.assinaturaUrl;
      descricao = _cachedInfo!.descricao;
      pdfTheme = _cachedInfo!.pdfTheme;
      // tenta carregar path local de prefs
      final prefs = await SharedPreferences.getInstance();
      logoLocalPath = prefs.getString('business_logo_local_path');
      assinaturaLocalPath = prefs.getString('business_assinatura_local_path');
      // pré-carregar bytes para evitar piscadas
      try {
        if (logoUrl != null && _logoCacheBytes == null) {
          await getLogoBytes();
        }
        if (assinaturaUrl != null && _assinaturaCacheBytes == null) {
          await getAssinaturaBytes();
        }
      } catch (_) {}
    } else {
      // ignore: discarded_futures
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
    String? logoUrl,
    String? pixTipo,
    String? pixChave,
    String? assinaturaUrl,
    String? descricao,
    Map<String, dynamic>? pdfTheme,
  }) async {
    if (_uid.isEmpty) return;

    final info = BusinessInfo(
      nomeEmpresa: nomeEmpresa,
      telefone: telefone,
      ramo: ramo,
      endereco: endereco,
      cnpj: cnpj,
      emailEmpresa: emailEmpresa,
      logoUrl: logoUrl ?? this.logoUrl,
      pixTipo: pixTipo ?? this.pixTipo,
      pixChave: pixChave ?? this.pixChave,
      assinaturaUrl: assinaturaUrl ?? this.assinaturaUrl,
      descricao: descricao ?? this.descricao,
      pdfTheme: pdfTheme ?? this.pdfTheme,
    );
    await _docRef.set(info.toMap(includeNulls: true));

    // Atualiza estado local
    this.nomeEmpresa = nomeEmpresa;
    this.telefone = telefone;
    this.ramo = ramo;
    this.endereco = endereco;
    this.cnpj = cnpj;
    this.emailEmpresa = emailEmpresa;
    if (logoUrl != null) this.logoUrl = logoUrl;
    if (pixTipo != null) this.pixTipo = pixTipo;
    if (pixChave != null) this.pixChave = pixChave;
    if (assinaturaUrl != null) this.assinaturaUrl = assinaturaUrl;
    if (descricao != null) this.descricao = descricao;
    if (pdfTheme != null) this.pdfTheme = pdfTheme;

    _cachedInfo = BusinessInfo(
      nomeEmpresa: this.nomeEmpresa,
      telefone: this.telefone,
      ramo: this.ramo,
      endereco: this.endereco,
      cnpj: this.cnpj,
      emailEmpresa: this.emailEmpresa,
      logoUrl: this.logoUrl,
      pixTipo: this.pixTipo,
      pixChave: this.pixChave,
      assinaturaUrl: this.assinaturaUrl,
      descricao: this.descricao,
      pdfTheme: this.pdfTheme,
    );
    notifyListeners();
  }

  Future<void> salvarInfo(BusinessInfo info) async {
    if (_uid.isEmpty) return;
    await _docRef.set(info.toMap(includeNulls: true));
    _cachedInfo = info;
    nomeEmpresa = info.nomeEmpresa;
    telefone = info.telefone;
    ramo = info.ramo;
    endereco = info.endereco;
    cnpj = info.cnpj;
    emailEmpresa = info.emailEmpresa;
    logoUrl = info.logoUrl;
    pixTipo = info.pixTipo;
    pixChave = info.pixChave;
    assinaturaUrl = info.assinaturaUrl;
    descricao = info.descricao;
    pdfTheme = info.pdfTheme;
    notifyListeners();
  }

  // ===== Descrição do negócio =====
  Future<void> salvarDescricao(String descricao) async {
    this.descricao = descricao;
    final updated = (_cachedInfo ?? BusinessInfo.empty()).copyWith(
      descricao: descricao,
    );
    await salvarInfo(updated);
  }

  Future<void> removerDescricao() async {
    descricao = null;
    final updated = (_cachedInfo ?? BusinessInfo.empty()).copyWith(
      descricao: null,
    );
    await salvarInfo(updated);
  }

  // ===== Tema de cores do PDF =====
  Future<void> salvarPdfTheme(Map<String, dynamic> theme) async {
    pdfTheme = Map<String, dynamic>.from(theme);
    final updated = (_cachedInfo ?? BusinessInfo.empty()).copyWith(
      pdfTheme: pdfTheme,
    );
    await salvarInfo(updated);
  }

  Future<void> limparPdfTheme() async {
    pdfTheme = null;
    final updated = (_cachedInfo ?? BusinessInfo.empty()).copyWith(
      pdfTheme: null,
    );
    await salvarInfo(updated);
  }

  Future<void> salvarPix({required String tipo, required String chave}) async {
    pixTipo = tipo;
    pixChave = chave;
    final updated = (_cachedInfo ?? BusinessInfo.empty()).copyWith(
      pixTipo: pixTipo,
      pixChave: pixChave,
    );
    await salvarInfo(updated);
  }

  Future<void> removerPix() async {
    pixTipo = null;
    pixChave = null;
    final updated = (_cachedInfo ?? BusinessInfo.empty()).copyWith(
      pixTipo: null,
      pixChave: null,
    );
    await salvarInfo(updated);
  }

  Future<void> uploadLogoBytes(Uint8List bytes, {String? filePath}) async {
    if (_uid.isEmpty) return;
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'negocios/$_uid/logomarca',
      );
      await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
      final url = await ref.getDownloadURL();
      logoUrl = url;
      _logoCacheBytes = bytes;
      if (filePath != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('business_logo_local_path', filePath);
        logoLocalPath = filePath;
      }
      final updated = (_cachedInfo ?? BusinessInfo.empty()).copyWith(
        nomeEmpresa: nomeEmpresa,
        telefone: telefone,
        ramo: ramo,
        endereco: endereco,
        cnpj: cnpj,
        emailEmpresa: emailEmpresa,
        logoUrl: logoUrl,
        pixTipo: pixTipo,
        pixChave: pixChave,
        assinaturaUrl: assinaturaUrl,
      );
      await salvarInfo(updated);
    } catch (e) {
      debugPrint('Erro ao fazer upload da logo: $e');
      rethrow;
    }
  }

  Future<Uint8List?> getLogoBytes() async {
    if (_logoCacheBytes != null) return _logoCacheBytes;

    // Em Web, não usar File system
    if (!kIsWeb && logoLocalPath != null) {
      try {
        final f = File(logoLocalPath!);
        if (await f.exists()) {
          _logoCacheBytes = await f.readAsBytes();
          return _logoCacheBytes;
        }
      } catch (e) {
        debugPrint('Erro ao ler logo do arquivo local: $e');
      }
    }

    // Buscar do Firebase Storage
    try {
      if (kIsWeb) {
        // No Web, prefira baixar direto do caminho conhecido no Storage
        if (_uid.isNotEmpty) {
          try {
            final ref = FirebaseStorage.instance.ref(
              'negocios/$_uid/logomarca',
            );
            final data = await ref.getData(5 * 1024 * 1024);
            if (data != null) {
              _logoCacheBytes = data;
              return _logoCacheBytes;
            }
          } catch (e) {
            debugPrint('Erro ao baixar logo do path padrão: $e');
          }
        }

        // Fallback: se tiver URL, tentar a partir dela
        if (logoUrl != null && logoUrl!.isNotEmpty) {
          try {
            final ref = FirebaseStorage.instance.refFromURL(logoUrl!);
            final data = await ref.getData(5 * 1024 * 1024);
            if (data != null) {
              _logoCacheBytes = data;
              return _logoCacheBytes;
            }
          } catch (e) {
            debugPrint('Erro ao baixar logo da URL via Storage: $e');
          }
        }
      } else {
        // Mobile/Desktop: usar HTTP para baixar da URL
        if (logoUrl != null && logoUrl!.isNotEmpty) {
          try {
            final resp = await http.get(Uri.parse(logoUrl!));
            if (resp.statusCode == 200) {
              _logoCacheBytes = resp.bodyBytes;
              return _logoCacheBytes;
            }
          } catch (e) {
            debugPrint('Erro ao baixar logo via HTTP: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Erro geral ao buscar logo: $e');
    }

    return null;
  }

  Future<void> uploadAssinaturaBytes(
    Uint8List bytes, {
    String? filePath,
  }) async {
    if (_uid.isEmpty) return;
    final ref = FirebaseStorage.instance.ref().child(
      'negocios/$_uid/assinatura',
    );
    await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
    final url = await ref.getDownloadURL();
    assinaturaUrl = url;
    _assinaturaCacheBytes = bytes;
    if (filePath != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('business_assinatura_local_path', filePath);
      assinaturaLocalPath = filePath;
    }
    final updated = (_cachedInfo ?? BusinessInfo.empty()).copyWith(
      nomeEmpresa: nomeEmpresa,
      telefone: telefone,
      ramo: ramo,
      endereco: endereco,
      cnpj: cnpj,
      emailEmpresa: emailEmpresa,
      logoUrl: logoUrl,
      pixTipo: pixTipo,
      pixChave: pixChave,
      assinaturaUrl: assinaturaUrl,
    );
    await salvarInfo(updated);
  }

  Future<Uint8List?> getAssinaturaBytes() async {
    if (_assinaturaCacheBytes != null) return _assinaturaCacheBytes;

    // Tentar ler do arquivo local (mobile/desktop)
    if (!kIsWeb && assinaturaLocalPath != null) {
      try {
        final f = File(assinaturaLocalPath!);
        if (await f.exists()) {
          _assinaturaCacheBytes = await f.readAsBytes();
          return _assinaturaCacheBytes;
        }
      } catch (e) {
        debugPrint('Erro ao ler assinatura do arquivo local: $e');
      }
    }

    // Buscar do Firebase Storage
    try {
      if (kIsWeb) {
        // Web: baixar direto do Storage
        if (_uid.isNotEmpty) {
          try {
            final ref = FirebaseStorage.instance.ref(
              'negocios/$_uid/assinatura',
            );
            final data = await ref.getData(5 * 1024 * 1024);
            if (data != null) {
              _assinaturaCacheBytes = data;
              return _assinaturaCacheBytes;
            }
          } catch (e) {
            debugPrint('Erro ao baixar assinatura do path padrão: $e');
          }
        }

        // Fallback: tentar a partir da URL
        if (assinaturaUrl != null && assinaturaUrl!.isNotEmpty) {
          try {
            final ref = FirebaseStorage.instance.refFromURL(assinaturaUrl!);
            final data = await ref.getData(5 * 1024 * 1024);
            if (data != null) {
              _assinaturaCacheBytes = data;
              return _assinaturaCacheBytes;
            }
          } catch (e) {
            debugPrint('Erro ao baixar assinatura da URL via Storage: $e');
          }
        }
      } else {
        // Mobile/Desktop: usar HTTP para baixar da URL
        if (assinaturaUrl != null && assinaturaUrl!.isNotEmpty) {
          try {
            final resp = await http.get(Uri.parse(assinaturaUrl!));
            if (resp.statusCode == 200) {
              _assinaturaCacheBytes = resp.bodyBytes;
              return _assinaturaCacheBytes;
            }
          } catch (e) {
            debugPrint('Erro ao baixar assinatura via HTTP: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Erro geral ao buscar assinatura: $e');
    }

    return null;
  }

  Future<void> removerAssinatura() async {
    assinaturaUrl = null;
    assinaturaLocalPath = null;
    _assinaturaCacheBytes = null;
    descricao = null;
    pdfTheme = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('business_assinatura_local_path');
    final updated = (_cachedInfo ?? BusinessInfo.empty()).copyWith(
      nomeEmpresa: nomeEmpresa,
      telefone: telefone,
      ramo: ramo,
      endereco: endereco,
      cnpj: cnpj,
      emailEmpresa: emailEmpresa,
      logoUrl: logoUrl,
      pixTipo: pixTipo,
      pixChave: pixChave,
      assinaturaUrl: null,
    );
    await salvarInfo(updated);
  }

  Future<void> removerLogo() async {
    logoUrl = null;
    logoLocalPath = null;
    _logoCacheBytes = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('business_logo_local_path');
    final updated = (_cachedInfo ?? BusinessInfo.empty()).copyWith(
      nomeEmpresa: nomeEmpresa,
      telefone: telefone,
      ramo: ramo,
      endereco: endereco,
      cnpj: cnpj,
      emailEmpresa: emailEmpresa,
      logoUrl: null,
      pixTipo: pixTipo,
      pixChave: pixChave,
      assinaturaUrl: assinaturaUrl,
    );
    await salvarInfo(updated);
  }

  /* ================== LIMPAR estado local ================== */
  Future<void> limparDados() async {
    nomeEmpresa = '';
    telefone = '';
    ramo = '';
    endereco = '';
    cnpj = '';
    emailEmpresa = '';
    logoUrl = null;
    logoLocalPath = null;
    _logoCacheBytes = null;
    pixTipo = null;
    pixChave = null;
    assinaturaUrl = null;
    assinaturaLocalPath = null;
    _assinaturaCacheBytes = null;
    descricao = null;
    pdfTheme = null;
    _cachedInfo = BusinessInfo.empty();

    // Limpar também o SharedPreferences para evitar paths de contas anteriores
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('business_logo_local_path');
      await prefs.remove('business_assinatura_local_path');
    } catch (e) {
      debugPrint('Erro ao limpar SharedPreferences: $e');
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
