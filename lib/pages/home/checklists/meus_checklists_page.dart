import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/checklists_provider.dart';
import 'criar_checklist_page.dart';

class MeusChecklistsPage extends StatefulWidget {
  const MeusChecklistsPage({super.key});

  @override
  State<MeusChecklistsPage> createState() => _MeusChecklistsPageState();
}

class _MeusChecklistsPageState extends State<MeusChecklistsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ChecklistsProvider>().carregarChecklists();
    });
  }

  @override
  Widget build(BuildContext context) {
    final checklistsProvider = context.watch<ChecklistsProvider>();
    final checklists = checklistsProvider.checklists;
    final carregando = checklistsProvider.carregando;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meus Checklists',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade600, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade50, Colors.white, Colors.white],
          ),
        ),
        child:
            carregando
                ? const Center(child: CircularProgressIndicator())
                : checklists.isEmpty
                ? _buildEmptyState()
                : _buildListaChecklists(checklists),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogNovoChecklist(context),
        backgroundColor: Colors.teal.shade600,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Novo Checklist',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.checklist_rounded,
                size: 80,
                color: Colors.teal.shade400,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Nenhum checklist criado',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Crie seu primeiro checklist para organizar suas tarefas e atividades do dia a dia.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade600, Colors.teal.shade400],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.shade200,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _mostrarDialogNovoChecklist(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                label: const Text(
                  'Criar Primeiro Checklist',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogNovoChecklist(BuildContext context) {
    final TextEditingController nomeController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: EdgeInsets.zero,
            title: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade600, Colors.teal.shade400],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.checklist_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Novo Checklist'),
                  ],
                ),
              ],
            ),
            content: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nome do Checklist',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nomeController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Ex: Verificações diárias',
                      prefixIcon: Icon(
                        Icons.edit_outlined,
                        color: Colors.teal.shade600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.teal.shade600,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade600, Colors.teal.shade400],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (nomeController.text.trim().isNotEmpty) {
                      Navigator.pop(ctx);
                      _criarChecklist(nomeController.text.trim());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Criar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _criarChecklist(String nome) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CriarChecklistPage(nomeChecklist: nome),
      ),
    );
  }

  Widget _buildListaChecklists(List checklists) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: checklists.length,
      itemBuilder: (context, index) {
        final checklist = checklists[index];
        final progresso = checklist.progresso;
        final itensConcluidos = checklist.itensConcluidos;
        final totalItens = checklist.totalItens;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(16),
            shadowColor: Colors.teal.withOpacity(0.2),
            child: InkWell(
              onTap: () {
                // TODO: Navegar para visualizar checklist
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Abrindo: ${checklist.nome}'),
                    backgroundColor: Colors.teal.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.teal.withOpacity(0.05),
                      Colors.teal.withOpacity(0.02),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.teal.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.teal.shade400,
                                Colors.teal.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.checklist_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                checklist.nome,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$itensConcluidos de $totalItens itens concluídos',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.teal.shade50,
                          ),
                          child: Center(
                            child: Text(
                              '${(progresso * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Barra de progresso
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progresso,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.teal.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Data de criação
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Criado em ${DateFormat('dd/MM/yyyy').format(checklist.criadoEm.toDate())}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
