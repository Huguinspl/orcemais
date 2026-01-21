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
import '../../../models/despesa.dart';
import '../../../models/orcamento.dart';
import '../../../models/cliente.dart';
import '../../../models/receita.dart';
import '../../../providers/agendamentos_provider.dart';
import '../../../providers/despesas_provider.dart';
import '../../../providers/orcamentos_provider.dart';
import '../../../providers/transacoes_provider.dart';
import '../../../providers/user_provider.dart';
import '../../home/tabs/clientes_page.dart';

/// Formatador de moeda para campos de valor (despesas)
class CurrencyInputFormatterNovaDespesa extends TextInputFormatter {
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
/// Estrutura similar à página de Agendamento a Pagar
class NovaDespesaPage extends StatefulWidget {
  final Despesa? despesa;
  const NovaDespesaPage({super.key, this.despesa});

  /// Verifica se está em modo de edição
  bool get isEditMode => despesa != null;

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
  DateTime? _dataPagamento;
  TimeOfDay? _horaPagamento;
  String _formaPagamento = 'Dinheiro';
  CategoriaTransacao? _categoriaSelecionada;
  Orcamento? _orcamento;
  Cliente? _cliente;
  bool _salvando = false;

  // Novos campos
  bool _repetirParcelar = false;

  // Controle para salvar em agendamento
  bool _salvarEmAgendamento = true;

  // ID da despesa sendo editada (null = novo)
  String? _despesaId;

  // Lista de arquivos/fotos anexados
  final List<_ArquivoAnexo> _arquivosAnexados = [];
  bool _enviandoArquivo = false;

  bool get _isEdicao => widget.despesa != null;

  @override
  void initState() {
    super.initState();

    final despesa = widget.despesa;

    if (despesa != null) {
      // Modo edição: carregar dados da despesa existente
      _despesaId = despesa.id;
      _dataTransacao = despesa.data.toDate();
      _valorController.text =
          'R\$ ${despesa.valor.toStringAsFixed(2).replaceAll('.', ',')}';
      _descricaoController.text = despesa.descricao;
      _formaPagamento = despesa.formaPagamento;
      _cliente = despesa.cliente;

      // Tentar extrair fornecedor e categoria das observações se disponível
      // (não temos campo específico no modelo antigo)
    } else {
      // Modo criação: valores padrão
      _dataPagamento = DateTime.now().add(const Duration(days: 7));
      _horaPagamento = const TimeOfDay(hour: 10, minute: 0);
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
    // Remove R$ e espaços
    String limpo = texto.replaceAll('R\$', '').replaceAll(' ', '').trim();
    // Troca vírgula por ponto
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

  List<DropdownMenuItem<String>> _getFormasPagamento() {
    return const [
      DropdownMenuItem(value: 'Dinheiro', child: Text('Dinheiro')),
      DropdownMenuItem(value: 'Pix', child: Text('Pix')),
      DropdownMenuItem(value: 'Crédito', child: Text('Crédito')),
      DropdownMenuItem(value: 'Débito', child: Text('Débito')),
      DropdownMenuItem(value: 'Boleto', child: Text('Boleto')),
      DropdownMenuItem(value: 'Transferência', child: Text('Transferência')),
    ];
  }

  Future<void> _selecionarOrcamento() async {
    final prov = context.read<OrcamentosProvider>();
    if (prov.orcamentos.isEmpty) await prov.carregarOrcamentos();
    final selecionado = await showModalBottomSheet<Orcamento>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.70,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade600, Colors.teal.shade400],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Selecionar Orçamento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: prov.orcamentos.length,
                  itemBuilder: (_, i) {
                    final o = prov.orcamentos[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.teal.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.description,
                            color: Colors.teal.shade600,
                          ),
                        ),
                        title: Text(
                          '#${o.numero.toString().padLeft(4, '0')} - ${o.cliente.nome}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          DateFormat(
                            'dd/MM/yyyy',
                          ).format(o.dataCriacao.toDate()),
                        ),
                        onTap: () => Navigator.pop(context, o),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selecionado != null) {
      setState(() {
        _orcamento = selecionado;
        _cliente = selecionado.cliente;
      });
    }
  }

  Future<void> _selecionarCliente() async {
    final c = await Navigator.push<Cliente>(
      context,
      MaterialPageRoute(builder: (_) => const ClientesPage(isPickerMode: true)),
    );
    if (c != null) setState(() => _cliente = c);
  }

  /// Mostra modal para buscar despesas existentes
  void _mostrarBuscaDespesas() {
    final transacoesProv = context.read<TransacoesProvider>();
    final despesas =
        transacoesProv.transacoes
            .where((t) => t.tipo == TipoTransacao.despesa)
            .toList()
          ..sort((a, b) => b.data.compareTo(a.data));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final dateFormat = DateFormat('dd/MM/yyyy');
        final currencyFormat = NumberFormat.currency(
          locale: 'pt_BR',
          symbol: 'R\$',
        );
        String filtro = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final despesasFiltradas =
                filtro.isEmpty
                    ? despesas
                    : despesas
                        .where(
                          (d) => d.descricao.toLowerCase().contains(
                            filtro.toLowerCase(),
                          ),
                        )
                        .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.80,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade600, Colors.red.shade400],
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Buscar Despesa Existente',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  // Campo de busca
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Digite para buscar...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.red.shade400,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.red.shade400,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onChanged: (value) {
                        setModalState(() => filtro = value);
                      },
                    ),
                  ),
                  Expanded(
                    child:
                        despesasFiltradas.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    filtro.isEmpty
                                        ? 'Nenhuma despesa cadastrada'
                                        : 'Nenhuma despesa encontrada',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: despesasFiltradas.length,
                              itemBuilder: (_, i) {
                                final despesa = despesasFiltradas[i];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.receipt_long,
                                        color: Colors.red.shade600,
                                      ),
                                    ),
                                    title: Text(
                                      despesa.descricao,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          'Data: ${dateFormat.format(despesa.data)}',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          despesa.categoria.nome,
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Text(
                                      currencyFormat.format(despesa.valor),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.red.shade600,
                                      ),
                                    ),
                                    onTap: () {
                                      // Preencher os campos com os dados da despesa
                                      _preencherComDespesa(despesa);
                                      Navigator.pop(context);
                                    },
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Preenche os campos do formulário com os dados de uma despesa existente
  void _preencherComDespesa(Transacao despesa) {
    setState(() {
      _descricaoController.text = despesa.descricao;
      _valorController.text =
          'R\$ ${despesa.valor.toStringAsFixed(2).replaceAll('.', ',')}';
      _categoriaSelecionada = despesa.categoria;
      _dataTransacao = despesa.data;
      _observacoesController.text = despesa.observacoes ?? '';

      // Tentar extrair fornecedor das observações
      final obs = despesa.observacoes ?? '';
      if (obs.isNotEmpty) {
        final linhas = obs.split('\n');
        for (final linha in linhas) {
          if (linha.startsWith('Fornecedor:')) {
            _fornecedorController.text =
                linha.replaceFirst('Fornecedor:', '').trim();
            break;
          }
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Despesa "${despesa.descricao}" carregada'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Mostra opções para adicionar arquivo (câmera, galeria ou arquivos)
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
        // Para web, precisamos ler os bytes
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

    setState(() => _salvando = true);

    try {
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.uid;

      if (userId.isEmpty) {
        throw Exception('Usuário não identificado');
      }

      final valor = _parseMoeda(_valorController.text) ?? 0.0;
      final despesasProv = context.read<DespesasProvider>();

      // Monta observações
      final obsCompletas = StringBuffer();
      if (_fornecedorController.text.isNotEmpty) {
        obsCompletas.writeln('Fornecedor: ${_fornecedorController.text}');
      }
      if (_repetirParcelar) {
        obsCompletas.writeln('Repetir/Parcelar: Sim');
      }
      // Adiciona URLs dos comprovantes anexados
      if (_arquivosAnexados.isNotEmpty) {
        obsCompletas.writeln('Comprovantes:');
        for (final arquivo in _arquivosAnexados) {
          obsCompletas.writeln('- ${arquivo.nome}: ${arquivo.url}');
        }
      }
      if (_observacoesController.text.isNotEmpty) {
        obsCompletas.writeln(_observacoesController.text);
      }

      if (_isEdicao) {
        // MODO EDIÇÃO
        final original = widget.despesa!;
        final atualizado = original.copyWith(
          data: Timestamp.fromDate(_dataTransacao),
          valor: valor,
          formaPagamento: _formaPagamento,
          descricao: _descricaoController.text.trim(),
          atualizadoEm: Timestamp.now(),
        );
        await despesasProv.atualizarDespesa(atualizado);

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Despesa atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // MODO CRIAÇÃO
        // Validar data de pagamento
        if (_dataPagamento == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Selecione a data do pagamento'),
              backgroundColor: _corTema.shade600,
            ),
          );
          setState(() => _salvando = false);
          return;
        }

        // Combina data e hora de pagamento
        final dataHoraPagamento = DateTime(
          _dataPagamento!.year,
          _dataPagamento!.month,
          _dataPagamento!.day,
          _horaPagamento?.hour ?? 10,
          _horaPagamento?.minute ?? 0,
        );

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
        // Adiciona URLs dos comprovantes anexados
        if (_arquivosAnexados.isNotEmpty) {
          obsAgendamento.writeln('Comprovantes:');
          for (final arquivo in _arquivosAnexados) {
            obsAgendamento.writeln('- ${arquivo.nome}: ${arquivo.url}');
          }
        }
        if (_observacoesController.text.isNotEmpty) {
          obsAgendamento.writeln(_observacoesController.text);
        }

        final clienteNome =
            _fornecedorController.text.isNotEmpty
                ? _fornecedorController.text
                : 'Despesa: ${_descricaoController.text}';

        // Monta observações com data de pagamento
        final obsCompletas = StringBuffer();
        obsCompletas.writeln('[DESPESA A PAGAR]');
        obsCompletas.writeln(
          'Data Pagamento: ${DateFormat('dd/MM/yyyy').format(_dataPagamento!)}',
        );
        if (_fornecedorController.text.isNotEmpty) {
          obsCompletas.writeln('Fornecedor: ${_fornecedorController.text}');
        }
        if (_repetirParcelar) {
          obsCompletas.writeln('Repetir/Parcelar: Sim');
        }
        // Adiciona URLs dos comprovantes anexados
        if (_arquivosAnexados.isNotEmpty) {
          obsCompletas.writeln('Comprovantes:');
          for (final arquivo in _arquivosAnexados) {
            obsCompletas.writeln('- ${arquivo.nome}: ${arquivo.url}');
          }
        }
        if (_observacoesController.text.isNotEmpty) {
          obsCompletas.writeln(_observacoesController.text);
        }

        // Salvar como transação futura no controle financeiro
        final transacao = Transacao(
          descricao: _descricaoController.text.trim(),
          valor: valor,
          tipo: TipoTransacao.despesa,
          categoria: _categoriaSelecionada ?? CategoriaTransacao.outros,
          data: _dataPagamento!,
          observacoes: obsCompletas.toString().trim(),
          userId: userId,
          isFutura: true,
        );

        final sucesso = await context
            .read<TransacoesProvider>()
            .adicionarTransacao(transacao);

        if (!mounted) return;

        if (sucesso) {
          // Se deve salvar em agendamento
          if (_salvarEmAgendamento) {
            final agProv = context.read<AgendamentosProvider>();
            await agProv.adicionarAgendamento(
              orcamentoId: 'despesa_a_pagar',
              orcamentoNumero: null,
              clienteNome: clienteNome,
              dataHora: Timestamp.fromDate(dataHoraPagamento),
              status: 'Pendente',
              observacoes: obsAgendamento.toString().trim(),
            );
          }

          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _salvarEmAgendamento
                    ? 'Despesa a pagar agendada com sucesso!'
                    : 'Despesa a pagar salva no controle financeiro!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
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

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: corTema.shade600,
        foregroundColor: Colors.white,
        title: Text(
          _isEdicao ? 'Editar Despesa a Pagar' : 'Despesa a Pagar',
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
                            onChanged: (value) {
                              setState(() => _repetirParcelar = value);
                            },
                            activeColor: corTema.shade600,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ========== BUSCAR DESPESA EXISTENTE ==========
                    InkWell(
                      onTap: _mostrarBuscaDespesas,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.search,
                                color: Colors.blue.shade600,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Buscar Despesa Existente',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Carregar dados de uma despesa salva',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.blue.shade400,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ========== FORNECEDOR ==========
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
                        children: [
                          Icon(Icons.store, color: Colors.orange.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _fornecedorController,
                              decoration: const InputDecoration(
                                hintText: 'Nome do fornecedor (opcional)',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ========== COMPROVANTES/ANEXOS ==========
                    _buildCardAnexos(),
                    const SizedBox(height: 24),

                    // Título com indicador do tipo
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [corTema.shade600, corTema.shade400],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.trending_down,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dados da Despesa',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Despesa futura a pagar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Futura',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Descrição
                    TextFormField(
                      controller: _descricaoController,
                      decoration: InputDecoration(
                        labelText: 'Descrição *',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: corTema.shade600,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Digite uma descrição';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Valor
                    TextFormField(
                      controller: _valorController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatterNovaDespesa(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Valor *',
                        prefixIcon: Icon(
                          Icons.attach_money,
                          color: corTema.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: corTema.shade600,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            _parseMoeda(value) == 0) {
                          return 'Informe um valor válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Categoria
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
                          (value) =>
                              setState(() => _categoriaSelecionada = value),
                    ),
                    const SizedBox(height: 16),

                    // Forma de Pagamento
                    DropdownButtonFormField<String>(
                      value: _formaPagamento,
                      decoration: InputDecoration(
                        labelText: 'Forma de Pagamento',
                        prefixIcon: Icon(
                          Icons.payment,
                          color: Colors.green.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _getFormasPagamento(),
                      onChanged:
                          (value) => setState(
                            () => _formaPagamento = value ?? 'Dinheiro',
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Data da Transação
                    ListTile(
                      leading: Icon(
                        Icons.calendar_today,
                        color: corTema.shade600,
                      ),
                      title: const Text('Data da Transação'),
                      subtitle: Text(
                        dateFormat.format(_dataTransacao),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      tileColor: Colors.white,
                      onTap: _selecionarDataTransacao,
                    ),
                    const SizedBox(height: 16),

                    // Data do Pagamento (campo adicional)
                    ListTile(
                      leading: Icon(
                        Icons.event_available,
                        color: Colors.orange.shade600,
                      ),
                      title: Row(
                        children: [
                          const Text('Data do Pagamento'),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Previsto',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        _dataPagamento != null
                            ? dateFormat.format(_dataPagamento!)
                            : 'Selecionar data',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color:
                              _dataPagamento != null
                                  ? Colors.orange.shade700
                                  : Colors.grey.shade500,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.orange.shade300),
                      ),
                      tileColor: Colors.orange.shade50,
                      onTap: _selecionarDataPagamento,
                    ),
                    const SizedBox(height: 16),

                    // Hora do Pagamento
                    ListTile(
                      leading: Icon(
                        Icons.access_time,
                        color: Colors.orange.shade600,
                      ),
                      title: Row(
                        children: [
                          const Text('Hora do Pagamento'),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Previsto',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        _horaPagamento != null
                            ? _horaPagamento!.format(context)
                            : 'Selecionar hora',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color:
                              _horaPagamento != null
                                  ? Colors.orange.shade700
                                  : Colors.grey.shade500,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.orange.shade300),
                      ),
                      tileColor: Colors.orange.shade50,
                      onTap: _selecionarHoraPagamento,
                    ),
                    const SizedBox(height: 16),

                    // Checkbox "Salvar em Agendamento"
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

                    // Observações
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

                    // Botão salvar
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
