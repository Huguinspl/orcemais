import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/agendamento.dart';
import '../../../models/receita.dart';
import '../../../providers/agendamentos_provider.dart';
import '../../../providers/transacoes_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/notification_service.dart';

class CurrencyInputFormatterDespesaAPagar extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final numeros = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.isEmpty) return const TextEditingValue(text: 'R\$ 0,00');
    final valor = int.parse(numeros) / 100;
    final textoFormatado =
        'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
    return TextEditingValue(
      text: textoFormatado,
      selection: TextSelection.collapsed(offset: textoFormatado.length),
    );
  }
}

/// Página para criar despesa a pagar (despesa futura) vindo do Controle Financeiro
/// Estrutura similar à página de Receita a Receber
class NovaDespesaAPagarPage extends StatefulWidget {
  /// Agendamento para edição (null = criar novo)
  final Agendamento? agendamento;

  /// Se true, mostra checkbox "Salvar em Agendamento"
  final bool fromControleFinanceiro;

  /// Callback para voltar ao modal de nova transação
  final VoidCallback? onVoltarParaModal;

  const NovaDespesaAPagarPage({
    super.key,
    this.agendamento,
    this.fromControleFinanceiro = true,
    this.onVoltarParaModal,
  });

  @override
  State<NovaDespesaAPagarPage> createState() => _NovaDespesaAPagarPageState();
}

class _NovaDespesaAPagarPageState extends State<NovaDespesaAPagarPage> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _fornecedorController = TextEditingController();

  DateTime? _dataPagamento;
  TimeOfDay? _horaPagamento;
  CategoriaTransacao? _categoriaSelecionada;
  bool _salvando = false;

  // Novos campos
  bool _repetirParcelar = false;

  // Controle para salvar em agendamento
  bool _salvarEmAgendamento = true;

  // Lista de arquivos/fotos anexados
  final List<_ArquivoAnexo> _arquivosAnexados = [];
  bool _enviandoArquivo = false;

  // ID do agendamento sendo editado (se for edição)
  String? _agendamentoIdEditando;

  @override
  void initState() {
    super.initState();

    if (widget.agendamento != null) {
      // Modo edição - preencher campos com dados do agendamento
      _agendamentoIdEditando = widget.agendamento!.id;
      _preencherDadosDoAgendamento();
    } else {
      // Valores padrão para nova despesa a pagar
      _dataPagamento = DateTime.now().add(const Duration(days: 7));
      _horaPagamento = const TimeOfDay(hour: 10, minute: 0);
    }
  }

  void _preencherDadosDoAgendamento() {
    final ag = widget.agendamento!;
    final dataHora = ag.dataHora.toDate();

    _dataPagamento = dataHora;
    _horaPagamento = TimeOfDay.fromDateTime(dataHora);

    // Preencher fornecedor (clienteNome no agendamento)
    if (ag.clienteNome != null && !ag.clienteNome!.startsWith('Despesa:')) {
      _fornecedorController.text = ag.clienteNome!;
    }

    // Remove seção de comprovantes antes de processar
    var obsLimpa = ag.observacoes.replaceAll(
      RegExp(r'\[COMPROVANTES\].*?\[/COMPROVANTES\]', dotAll: true),
      '',
    );

    // Extrair dados das observações
    final linhas = obsLimpa.split('\n');
    bool dentroComprovantes = false;

    for (final linha in linhas) {
      // Ignora linhas vazias
      if (linha.trim().isEmpty) continue;

      // Ignora tags de comprovantes (caso a regex não tenha pego)
      if (linha.startsWith('[COMPROVANTES]')) {
        dentroComprovantes = true;
        continue;
      }
      if (linha.startsWith('[/COMPROVANTES]')) {
        dentroComprovantes = false;
        continue;
      }
      if (dentroComprovantes) continue;

      if (linha.startsWith('Descrição:')) {
        _descricaoController.text = linha.replaceFirst('Descrição:', '').trim();
      } else if (linha.startsWith('Valor:')) {
        final valorStr = linha.replaceFirst('Valor:', '').trim();
        _valorController.text = valorStr;
      } else if (linha.startsWith('Categoria:')) {
        final categoriaNome = linha.replaceFirst('Categoria:', '').trim();
        // Buscar categoria pelo nome
        for (final cat in CategoriaTransacao.values) {
          if (cat.nome == categoriaNome) {
            _categoriaSelecionada = cat;
            break;
          }
        }
      } else if (linha.startsWith('Fornecedor:')) {
        _fornecedorController.text =
            linha.replaceFirst('Fornecedor:', '').trim();
      } else if (linha.startsWith('Repetir/Parcelar:')) {
        _repetirParcelar = linha.contains('Sim');
      } else if (!linha.startsWith('[') &&
          !linha.startsWith('Data prevista:') &&
          !linha.startsWith('Hora prevista:') &&
          !linha.contains('|') && // URLs de comprovantes contêm |
          linha.trim().isNotEmpty) {
        // Outras observações
        if (_observacoesController.text.isNotEmpty) {
          _observacoesController.text += '\n';
        }
        _observacoesController.text += linha;
      }
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _observacoesController.dispose();
    _fornecedorController.dispose();
    super.dispose();
  }

  MaterialColor get _corTema => Colors.orange;

  double? _parseMoeda(String texto) {
    if (texto.isEmpty) return null;
    String limpo = texto.replaceAll('R\$', '').replaceAll(' ', '').trim();
    limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(limpo);
  }

  Future<void> _selecionarDataPagamento() async {
    final data = await showDatePicker(
      context: context,
      initialDate:
          _dataPagamento ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (data != null) {
      setState(() => _dataPagamento = data);
    }
  }

  Future<void> _selecionarHoraPagamento() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaPagamento ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              dialBackgroundColor: Colors.orange.shade50,
              hourMinuteTextColor: Colors.orange.shade700,
            ),
          ),
          child: child!,
        );
      },
    );
    if (hora != null) {
      setState(() => _horaPagamento = hora);
    }
  }

  List<DropdownMenuItem<CategoriaTransacao>> _getCategorias() {
    final categorias =
        CategoriaTransacao.values.where((cat) => cat.isDespesa).toList();
    return categorias.map((cat) {
      return DropdownMenuItem(value: cat, child: Text(cat.nome));
    }).toList();
  }

  // ========== MÉTODOS DE COMPROVANTES ==========

  void _mostrarOpcoesAnexo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Adicionar Comprovante',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOpcaoAnexo(
                    icone: Icons.camera_alt,
                    label: 'Câmera',
                    cor: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _capturarFoto();
                    },
                  ),
                  _buildOpcaoAnexo(
                    icone: Icons.photo_library,
                    label: 'Galeria',
                    cor: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _selecionarDaGaleria();
                    },
                  ),
                  _buildOpcaoAnexo(
                    icone: Icons.attach_file,
                    label: 'Arquivo',
                    cor: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _selecionarArquivo();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOpcaoAnexo({
    required IconData icone,
    required String label,
    required MaterialColor cor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cor.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icone, color: cor.shade600, size: 32),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: cor.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _capturarFoto() async {
    try {
      final picker = ImagePicker();
      final foto = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (foto != null) {
        await _adicionarArquivo(foto.path, foto.name, 'image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao capturar foto: $e')));
      }
    }
  }

  Future<void> _selecionarDaGaleria() async {
    try {
      final picker = ImagePicker();
      final imagens = await picker.pickMultiImage(imageQuality: 70);
      for (final img in imagens) {
        await _adicionarArquivo(img.path, img.name, 'image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagens: $e')),
        );
      }
    }
  }

  Future<void> _selecionarArquivo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
        allowMultiple: true,
      );
      if (result != null) {
        for (final file in result.files) {
          if (file.path != null) {
            final tipo =
                file.extension?.toLowerCase() == 'pdf' ? 'pdf' : 'image';
            await _adicionarArquivo(file.path!, file.name, tipo);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
        );
      }
    }
  }

  Future<void> _adicionarArquivo(String path, String nome, String tipo) async {
    setState(() => _enviandoArquivo = true);
    try {
      final userId = context.read<UserProvider>().uid;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'despesas/$userId/comprovantes/$timestamp\_$nome';

      final ref = FirebaseStorage.instance.ref().child(storagePath);

      String url;
      if (kIsWeb) {
        final bytes = await File(path).readAsBytes();
        await ref.putData(bytes);
        url = await ref.getDownloadURL();
      } else {
        await ref.putFile(File(path));
        url = await ref.getDownloadURL();
      }

      setState(() {
        _arquivosAnexados.add(_ArquivoAnexo(nome: nome, url: url, tipo: tipo));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar arquivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _enviandoArquivo = false);
      }
    }
  }

  void _removerArquivo(int index) {
    setState(() {
      _arquivosAnexados.removeAt(index);
    });
  }

  Widget _buildCardAnexos() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.purple.shade600),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Comprovantes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              if (_enviandoArquivo)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _mostrarOpcoesAnexo,
                  icon: Icon(Icons.add_circle, color: Colors.purple.shade600),
                  tooltip: 'Adicionar comprovante',
                ),
            ],
          ),
          if (_arquivosAnexados.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nenhum comprovante anexado',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
            )
          else ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _arquivosAnexados.length,
                itemBuilder: (context, index) {
                  final arquivo = _arquivosAnexados[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child:
                                arquivo.tipo == 'image'
                                    ? Image.network(
                                      arquivo.url,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => Icon(
                                            Icons.image,
                                            color: Colors.grey.shade400,
                                            size: 40,
                                          ),
                                    )
                                    : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.picture_as_pdf,
                                          color: Colors.red.shade400,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'PDF',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removerArquivo(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
          InkWell(
            onTap: _mostrarOpcoesAnexo,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.purple.shade200,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    color: Colors.purple.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Adicionar foto ou arquivo',
                    style: TextStyle(
                      color: Colors.purple.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    // Validação da data de pagamento
    if (_dataPagamento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecione a data de pagamento'),
          backgroundColor: _corTema.shade600,
        ),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.uid;

      if (userId.isEmpty) {
        throw Exception('Usuário não identificado');
      }

      final valor = _parseMoeda(_valorController.text) ?? 0.0;

      // Combina data e hora de pagamento
      final dataHoraPagamento = DateTime(
        _dataPagamento!.year,
        _dataPagamento!.month,
        _dataPagamento!.day,
        _horaPagamento?.hour ?? 10,
        _horaPagamento?.minute ?? 0,
      );

      // Monta observações completas
      final obsCompletas = StringBuffer();
      obsCompletas.writeln('[DESPESA A PAGAR]');
      obsCompletas.writeln(
        'Data prevista: ${DateFormat('dd/MM/yyyy').format(_dataPagamento!)}',
      );
      if (_horaPagamento != null) {
        obsCompletas.writeln(
          'Hora prevista: ${_horaPagamento!.hour.toString().padLeft(2, '0')}:${_horaPagamento!.minute.toString().padLeft(2, '0')}',
        );
      }
      if (_fornecedorController.text.isNotEmpty) {
        obsCompletas.writeln('Fornecedor: ${_fornecedorController.text}');
      }
      if (_repetirParcelar) {
        obsCompletas.writeln('Repetir/Parcelar: Sim');
      }
      if (_observacoesController.text.isNotEmpty) {
        obsCompletas.writeln(_observacoesController.text);
      }

      // Criar transação futura (despesa a pagar)
      final transacao = Transacao(
        descricao: _descricaoController.text,
        valor: valor,
        tipo: TipoTransacao.despesa,
        categoria: _categoriaSelecionada ?? CategoriaTransacao.outros,
        data: dataHoraPagamento,
        observacoes: obsCompletas.toString().trim(),
        userId: userId,
        isFutura: true,
      );

      final sucesso = await context
          .read<TransacoesProvider>()
          .adicionarTransacao(transacao);

      if (!mounted) return;

      if (sucesso) {
        // Salvar na agenda se opção estiver marcada OU se for edição de agendamento
        if (_salvarEmAgendamento || _agendamentoIdEditando != null) {
          // Solicita permissão de notificação se ainda não foi concedida
          final notificationService = NotificationService();
          if (!notificationService.isInitialized) {
            await notificationService.initialize();
          }
          if (!notificationService.permissionGranted) {
            await notificationService.requestPermission();
          }

          final agProv = context.read<AgendamentosProvider>();

          // Monta observações para o agendamento
          final obsAgendamento = StringBuffer();
          obsAgendamento.writeln('[DESPESA A PAGAR]');
          obsAgendamento.writeln('Descrição: ${_descricaoController.text}');
          obsAgendamento.writeln(
            'Valor: R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
          );
          if (_categoriaSelecionada != null) {
            obsAgendamento.writeln('Categoria: ${_categoriaSelecionada!.nome}');
          }
          if (_fornecedorController.text.isNotEmpty) {
            obsAgendamento.writeln('Fornecedor: ${_fornecedorController.text}');
          }
          if (_repetirParcelar) {
            obsAgendamento.writeln('Repetir/Parcelar: Sim');
          }
          if (_observacoesController.text.isNotEmpty) {
            obsAgendamento.writeln(_observacoesController.text);
          }
          // Adiciona URLs dos comprovantes
          if (_arquivosAnexados.isNotEmpty) {
            obsAgendamento.writeln('[COMPROVANTES]');
            for (final arquivo in _arquivosAnexados) {
              obsAgendamento.writeln('${arquivo.nome}|${arquivo.url}');
            }
            obsAgendamento.writeln('[/COMPROVANTES]');
          }

          final clienteNome =
              _fornecedorController.text.isNotEmpty
                  ? _fornecedorController.text
                  : 'Despesa: ${_descricaoController.text}';

          // Se for edição, atualiza o agendamento existente
          if (_agendamentoIdEditando != null) {
            print('=== EDITANDO DESPESA A PAGAR ===');
            print('Agendamento original status: ${widget.agendamento!.status}');
            final agendamentoAtualizado = widget.agendamento!.copyWith(
              clienteNome: clienteNome,
              dataHora: Timestamp.fromDate(dataHoraPagamento),
              observacoes: obsAgendamento.toString().trim(),
            );
            print(
              'Agendamento atualizado status: ${agendamentoAtualizado.status}',
            );
            await agProv.atualizarAgendamento(agendamentoAtualizado);
          } else {
            await agProv.adicionarAgendamento(
              orcamentoId: 'despesa_a_pagar',
              orcamentoNumero: null,
              clienteNome: clienteNome,
              dataHora: Timestamp.fromDate(dataHoraPagamento),
              status: 'Pendente',
              observacoes: obsAgendamento.toString().trim(),
            );
          }
        }

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  _agendamentoIdEditando != null
                      ? 'Despesa a pagar atualizada!'
                      : _salvarEmAgendamento
                      ? 'Despesa a pagar adicionada e agendada!'
                      : 'Despesa a pagar salva (sem agendamento)',
                ),
              ],
            ),
            backgroundColor: _corTema.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        throw Exception('Erro ao salvar transação');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  void _voltarParaModal() {
    Navigator.pop(context);
    if (widget.onVoltarParaModal != null) {
      widget.onVoltarParaModal!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final corTema = _corTema;
    final dateFormat = DateFormat('dd/MM/yyyy');

    final isEdicao = widget.agendamento != null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: corTema.shade600,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _voltarParaModal,
          ),
          title: Text(
            isEdicao ? 'Editar Despesa a Pagar' : 'Nova Despesa a Pagar',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [corTema.shade50, Colors.white],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ========== REPETIR / PARCELAR ==========
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.repeat, color: corTema.shade600),
                                const SizedBox(width: 12),
                                const Text(
                                  'Repetir / Parcelar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _repetirParcelar,
                              onChanged:
                                  (v) => setState(() => _repetirParcelar = v),
                              activeColor: corTema.shade600,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ========== FORNECEDOR ==========
                      TextFormField(
                        controller: _fornecedorController,
                        decoration: InputDecoration(
                          labelText: 'Fornecedor (opcional)',
                          prefixIcon: Icon(
                            Icons.business,
                            color: corTema.shade600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ========== COMPROVANTES ==========
                      _buildCardAnexos(),
                      const SizedBox(height: 16),

                      // ========== DESCRIÇÃO ==========
                      TextFormField(
                        controller: _descricaoController,
                        decoration: InputDecoration(
                          labelText: 'Descrição',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Informe a descrição'
                                    : null,
                      ),
                      const SizedBox(height: 16),

                      // ========== VALOR ==========
                      TextFormField(
                        controller: _valorController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          CurrencyInputFormatterDespesaAPagar(),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Valor',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Informe o valor';
                          final valor = _parseMoeda(v);
                          if (valor == null || valor <= 0) {
                            return 'Valor inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ========== CATEGORIA ==========
                      DropdownButtonFormField<CategoriaTransacao>(
                        value: _categoriaSelecionada,
                        decoration: InputDecoration(
                          labelText: 'Categoria',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _getCategorias(),
                        onChanged:
                            (v) => setState(() => _categoriaSelecionada = v),
                        validator:
                            (v) => v == null ? 'Selecione uma categoria' : null,
                      ),
                      const SizedBox(height: 24),

                      // ========== DATA DO PAGAMENTO ==========
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Previsto',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.calendar_today,
                          color: Colors.orange.shade600,
                        ),
                        title: const Text('Data do Pagamento'),
                        subtitle: Text(
                          _dataPagamento != null
                              ? dateFormat.format(_dataPagamento!)
                              : 'Selecionar data',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.orange.shade300),
                        ),
                        tileColor: Colors.orange.shade50,
                        onTap: _selecionarDataPagamento,
                      ),
                      const SizedBox(height: 12),

                      // ========== HORA DO PAGAMENTO ==========
                      ListTile(
                        leading: Icon(
                          Icons.access_time,
                          color: Colors.orange.shade600,
                        ),
                        title: const Text('Hora do Pagamento'),
                        subtitle: Text(
                          _horaPagamento != null
                              ? '${_horaPagamento!.hour.toString().padLeft(2, '0')}:${_horaPagamento!.minute.toString().padLeft(2, '0')}'
                              : 'Selecionar hora',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.orange.shade300),
                        ),
                        tileColor: Colors.orange.shade50,
                        onTap: _selecionarHoraPagamento,
                      ),
                      const SizedBox(height: 16),

                      // ========== CHECKBOX SALVAR EM AGENDAMENTO ==========
                      if (widget.fromControleFinanceiro) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: CheckboxListTile(
                            value: _salvarEmAgendamento,
                            onChanged:
                                (v) => setState(
                                  () => _salvarEmAgendamento = v ?? true,
                                ),
                            title: const Text(
                              'Salvar em Agendamento',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              _salvarEmAgendamento
                                  ? 'A despesa também aparecerá na aba de Agendamentos'
                                  : 'A despesa será salva apenas no Controle Financeiro',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                            secondary: Icon(
                              _salvarEmAgendamento
                                  ? Icons.event_available
                                  : Icons.event_busy,
                              color: Colors.blue.shade600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            activeColor: Colors.blue.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ========== OBSERVAÇÕES ==========
                      TextFormField(
                        controller: _observacoesController,
                        decoration: InputDecoration(
                          labelText: 'Observações (opcional)',
                          prefixIcon: const Icon(Icons.notes),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      // ========== BOTÃO SALVAR ==========
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _salvando ? null : _salvar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: corTema.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              _salvando
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    'Salvar Despesa a Pagar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Classe auxiliar para armazenar informações de arquivos anexados
class _ArquivoAnexo {
  final String nome;
  final String url;
  final String tipo; // 'image' ou 'pdf'

  _ArquivoAnexo({required this.nome, required this.url, required this.tipo});
}
