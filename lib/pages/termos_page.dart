import 'package:flutter/material.dart';

class TermosPage extends StatelessWidget {
  const TermosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.white, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header moderno
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade600, Colors.teal.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.shade200.withOpacity(0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.description,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Termos e Privacidade',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Política de uso do app',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Conteúdo
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildTermoCard(
                      context,
                      icon: Icons.shield_outlined,
                      title: '1. Coleta de dados',
                      content:
                          'Coletamos informações pessoais como nome, e-mail e CPF com o objetivo de facilitar a criação de orçamentos, recibos e controle de serviços. Seus dados são armazenados com segurança e não são compartilhados com terceiros.',
                      gradientColors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTermoCard(
                      context,
                      icon: Icons.verified_user_outlined,
                      title: '2. Uso das informações',
                      content:
                          'As informações fornecidas são utilizadas exclusivamente para personalizar e melhorar sua experiência no aplicativo, bem como para funcionalidades essenciais como salvamento de dados e geração de documentos.',
                      gradientColors: [
                        Colors.teal.shade400,
                        Colors.teal.shade600,
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTermoCard(
                      context,
                      icon: Icons.lock_outlined,
                      title: '3. Segurança',
                      content:
                          'Adotamos medidas de segurança para proteger suas informações contra acessos não autorizados, alterações, divulgações ou destruições.',
                      gradientColors: [
                        Colors.green.shade400,
                        Colors.green.shade600,
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTermoCard(
                      context,
                      icon: Icons.person_outline,
                      title: '4. Responsabilidade do usuário',
                      content:
                          'O usuário é responsável por manter seus dados atualizados e proteger suas credenciais de acesso. Não nos responsabilizamos por dados incorretos fornecidos pelo usuário.',
                      gradientColors: [
                        Colors.orange.shade400,
                        Colors.orange.shade600,
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTermoCard(
                      context,
                      icon: Icons.update_outlined,
                      title: '5. Alterações nos termos',
                      content:
                          'Reservamo-nos o direito de modificar esta política a qualquer momento. Mudanças significativas serão notificadas dentro do próprio app.',
                      gradientColors: [
                        Colors.purple.shade400,
                        Colors.purple.shade600,
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTermoCard(
                      context,
                      icon: Icons.email_outlined,
                      title: '6. Contato',
                      content:
                          'Em caso de dúvidas, sugestões ou solicitações relacionadas à privacidade, entre em contato através do e-mail de suporte fornecido na seção de contato do aplicativo.',
                      gradientColors: [
                        Colors.indigo.shade400,
                        Colors.indigo.shade600,
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Footer
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade100, Colors.grey.shade200],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.grey.shade600,
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Última atualização',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Novembro de 2025',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
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

  Widget _buildTermoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required List<Color> gradientColors,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, gradientColors[0].withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: gradientColors[1],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
