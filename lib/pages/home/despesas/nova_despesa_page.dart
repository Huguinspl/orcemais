import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/receita.dart';
import '../../../providers/transacoes_provider.dart';
import '../../../providers/user_provider.dart';

class CurrencyInputFormatterDespesa extends TextInputFormatter {
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

/// Página para criar/editar despesa (saída de dinheiro já realizada)
/// Estrutura similar à página de Despesa a Pagar, mas sem campos de agendamento
class NovaDespesaPage extends StatefulWidget {
  /// Transação para edição (null = criar novo)
  final Transacao? transacao;

  /// Se true, cria despesa a pagar (futura)
  final bool isFutura;

  /// Callback para voltar ao modal de nova transação
  final VoidCallback? onVoltarParaModal;

  const NovaDespesaPage({
    super.key,
    this.transacao,
    this.isFutura = false,
    this.onVoltarParaModal,
  });

  /// Verifica se está em modo de edição
  bool get isEditMode => transacao != null;

  @override
  State<NovaDespesaPage> createState() => _NovaDespesaPageState();
}

class _NovaDespesaPageState extends State<NovaDespesaPage> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _fornecedorController = TextEditingController();

  DateTime _dataTransacao = DateTime.now();
  CategoriaTransacao? _categoriaSelecionada;
  bool _salvando = false;

  // Novos campos
  bool _repetirParcelar = false;
  int _quantidadeRepeticoes = 2; // Número de vezes que vai repetir (mínimo 2)
  String _tipoRepeticao = 'mensal'; // mensal, quinzenal, semanal

  // ID da transação sendo editada (null = novo)
  String? _transacaoId;

  // Lista de arquivos/fotos anexados
  final List<_ArquivoAnexoDespesa> _arquivosAnexados = [];
  bool _enviandoArquivo = false;

  @override
  void initState() {
    super.initState();

    final transacao = widget.transacao;

    if (transacao != null) {
      // Modo edição: carregar dados da transação existente
      _transacaoId = transacao.id;
      _dataTransacao = transacao.data;
      _descricaoController.text = transacao.descricao;
      _valorController.text =
          'R\$ ${transacao.valor.toStringAsFixed(2).replaceAll('.', ',')}';
      _categoriaSelecionada = transacao.categoria;
      _observacoesController.text = transacao.observacoes ?? '';
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

  MaterialColor get _corTema => Colors.red;

  double? _parseMoeda(String texto) {
    if (texto.isEmpty) return null;
    String limpo = texto.replaceAll('R\$', '').replaceAll(' ', '').trim();
    limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(limpo);
  }

  Future<void> _selecionarDataTransacao() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataTransacao,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _corTema.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (data != null) {
      setState(() => _dataTransacao = data);
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
        _arquivosAnexados.add(
          _ArquivoAnexoDespesa(nome: nome, url: url, tipo: tipo),
        );
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

  // ========== SALVAR ==========

  void _mostrarConfigRepeticao() {
    int tempQuantidade = _quantidadeRepeticoes;
    String tempTipo = _tipoRepeticao;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.repeat, color: _corTema.shade600, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Configurar Repetição',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Tipo de repetição
                  const Text(
                    'Repetir a cada:',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Semana'),
                        selected: tempTipo == 'semanal',
                        onSelected:
                            (v) => setModalState(() => tempTipo = 'semanal'),
                        selectedColor: _corTema.shade100,
                      ),
                      ChoiceChip(
                        label: const Text('Quinzena'),
                        selected: tempTipo == 'quinzenal',
                        onSelected:
                            (v) => setModalState(() => tempTipo = 'quinzenal'),
                        selectedColor: _corTema.shade100,
                      ),
                      ChoiceChip(
                        label: const Text('Mês'),
                        selected: tempTipo == 'mensal',
                        onSelected:
                            (v) => setModalState(() => tempTipo = 'mensal'),
                        selectedColor: _corTema.shade100,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Quantidade de repetições
                  const Text(
                    'Quantidade de vezes:',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed:
                            tempQuantidade > 2
                                ? () => setModalState(() => tempQuantidade--)
                                : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: _corTema.shade600,
                        iconSize: 32,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _corTema.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _corTema.shade200),
                        ),
                        child: Text(
                          '$tempQuantidade',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _corTema.shade700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            tempQuantidade < 24
                                ? () => setModalState(() => tempQuantidade++)
                                : null,
                        icon: const Icon(Icons.add_circle_outline),
                        color: _corTema.shade600,
                        iconSize: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getDescricaoRepeticao(tempTipo, tempQuantidade),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _repetirParcelar = false);
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _quantidadeRepeticoes = tempQuantidade;
                              _tipoRepeticao = tempTipo;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _corTema.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Confirmar'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getDescricaoRepeticao(String tipo, int quantidade) {
    final periodo =
        tipo == 'semanal'
            ? 'semanas'
            : (tipo == 'quinzenal' ? 'quinzenas' : 'meses');
    return 'Total: $quantidade despesas ao longo de ${quantidade} $periodo';
  }

  DateTime _calcularProximaData(DateTime dataBase, String tipo, int indice) {
    switch (tipo) {
      case 'semanal':
        return dataBase.add(Duration(days: 7 * indice));
      case 'quinzenal':
        return dataBase.add(Duration(days: 15 * indice));
      case 'mensal':
      default:
        return DateTime(dataBase.year, dataBase.month + indice, dataBase.day);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    try {
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.uid;

      if (userId.isEmpty) {
        throw Exception('Usuário não identificado');
      }

      final valor = _parseMoeda(_valorController.text) ?? 0.0;

      // Monta observações completas
      final obsCompletas = StringBuffer();
      obsCompletas.writeln('[DESPESA]');
      if (_fornecedorController.text.isNotEmpty) {
        obsCompletas.writeln('Fornecedor: ${_fornecedorController.text}');
      }
      if (_repetirParcelar) {
        obsCompletas.writeln('Repetir/Parcelar: Sim');
      }
      if (_observacoesController.text.isNotEmpty) {
        obsCompletas.writeln(_observacoesController.text);
      }
      // Adiciona URLs dos comprovantes
      if (_arquivosAnexados.isNotEmpty) {
        obsCompletas.writeln('[COMPROVANTES]');
        for (final arquivo in _arquivosAnexados) {
          obsCompletas.writeln('${arquivo.nome}|${arquivo.url}');
        }
        obsCompletas.writeln('[/COMPROVANTES]');
      }

      // Criar transação (despesa já realizada)
      final transacao = Transacao(
        id: _transacaoId,
        descricao: _descricaoController.text,
        valor: valor,
        tipo: TipoTransacao.despesa,
        categoria: _categoriaSelecionada ?? CategoriaTransacao.outros,
        data: _dataTransacao,
        observacoes: obsCompletas.toString().trim(),
        userId: userId,
        isFutura: widget.isFutura,
      );

      final transacoesProvider = context.read<TransacoesProvider>();
      bool sucesso;
      int quantidadeSalva = 1;

      if (_transacaoId != null) {
        // Modo edição - não repete, apenas atualiza
        sucesso = await transacoesProvider.atualizarTransacao(transacao);
      } else {
        // Modo criação
        sucesso = await transacoesProvider.adicionarTransacao(transacao);

        // Se repetir está ativado e salvou com sucesso, cria as repetições
        if (sucesso && _repetirParcelar && _quantidadeRepeticoes > 1) {
          for (int i = 1; i < _quantidadeRepeticoes; i++) {
            final dataRepeticao = _calcularProximaData(
              _dataTransacao,
              _tipoRepeticao,
              i,
            );
            final obsRepeticao = StringBuffer();
            obsRepeticao.writeln('[DESPESA]');
            if (_fornecedorController.text.isNotEmpty) {
              obsRepeticao.writeln('Fornecedor: ${_fornecedorController.text}');
            }
            obsRepeticao.writeln('Repetição: ${i + 1}/$_quantidadeRepeticoes');
            if (_observacoesController.text.isNotEmpty) {
              obsRepeticao.writeln(_observacoesController.text);
            }

            final transacaoRepeticao = Transacao(
              descricao: _descricaoController.text,
              valor: valor,
              tipo: TipoTransacao.despesa,
              categoria: _categoriaSelecionada ?? CategoriaTransacao.outros,
              data: dataRepeticao,
              observacoes: obsRepeticao.toString().trim(),
              userId: userId,
              isFutura: widget.isFutura,
            );

            final sucessoRepeticao = await transacoesProvider
                .adicionarTransacao(transacaoRepeticao);
            if (sucessoRepeticao) quantidadeSalva++;
          }
        }
      }

      if (!mounted) return;

      if (sucesso) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  _transacaoId != null
                      ? 'Despesa atualizada com sucesso!'
                      : _repetirParcelar && _quantidadeRepeticoes > 1
                      ? '$quantidadeSalva despesas salvas com sucesso!'
                      : 'Despesa salva com sucesso!',
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
        throw Exception('Erro ao salvar despesa');
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

  @override
  Widget build(BuildContext context) {
    final corTema = _corTema;
    final dateFormat = DateFormat('dd/MM/yyyy');

    final isEdicao = widget.transacao != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: corTema.shade600,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            // Se tiver callback, chama para reabrir o modal
            if (widget.onVoltarParaModal != null) {
              widget.onVoltarParaModal!();
            }
          },
        ),
        title: Text(
          isEdicao ? 'Editar Despesa' : 'Nova Despesa',
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
                    InkWell(
                      onTap: () {
                        if (!_repetirParcelar) {
                          setState(() => _repetirParcelar = true);
                          _mostrarConfigRepeticao();
                        } else {
                          setState(() => _repetirParcelar = false);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                                  onChanged: (v) {
                                    if (v) {
                                      setState(() => _repetirParcelar = true);
                                      _mostrarConfigRepeticao();
                                    } else {
                                      setState(() => _repetirParcelar = false);
                                    }
                                  },
                                  activeColor: corTema.shade600,
                                ),
                              ],
                            ),
                            if (_repetirParcelar) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: corTema.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: corTema.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$_quantidadeRepeticoes x ${_tipoRepeticao == 'semanal'
                                          ? 'Semanal'
                                          : _tipoRepeticao == 'quinzenal'
                                          ? 'Quinzenal'
                                          : 'Mensal'}',
                                      style: TextStyle(
                                        color: corTema.shade700,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: _mostrarConfigRepeticao,
                                      child: Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: corTema.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
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
                      inputFormatters: [CurrencyInputFormatterDespesa()],
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

                    // ========== DATA DA DESPESA ==========
                    ListTile(
                      leading: Icon(
                        Icons.calendar_today,
                        color: corTema.shade600,
                      ),
                      title: const Text('Data da Despesa'),
                      subtitle: Text(
                        dateFormat.format(_dataTransacao),
                        style: TextStyle(
                          color: corTema.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: corTema.shade300),
                      ),
                      tileColor: corTema.shade50,
                      onTap: _selecionarDataTransacao,
                    ),
                    const SizedBox(height: 16),

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
                                : Text(
                                  isEdicao
                                      ? 'Atualizar Despesa'
                                      : 'Salvar Despesa',
                                  style: const TextStyle(
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
    );
  }
}

/// Classe auxiliar para armazenar informações de arquivos anexados
class _ArquivoAnexoDespesa {
  final String nome;
  final String url;
  final String tipo; // 'image' ou 'pdf'

  _ArquivoAnexoDespesa({
    required this.nome,
    required this.url,
    required this.tipo,
  });
}
