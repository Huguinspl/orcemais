import 'package:flutter/material.dart';

class TermosPage extends StatelessWidget {
  const TermosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Termos de uso e Privacidade',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            '1. Coleta de dados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Coletamos informações pessoais como nome, e-mail e CPF com o objetivo de facilitar a criação de orçamentos, recibos e controle de serviços. Seus dados são armazenados com segurança e não são compartilhados com terceiros.',
          ),
          SizedBox(height: 24),

          Text(
            '2. Uso das informações',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'As informações fornecidas são utilizadas exclusivamente para personalizar e melhorar sua experiência no aplicativo, bem como para funcionalidades essenciais como salvamento de dados e geração de documentos.',
          ),
          SizedBox(height: 24),

          Text(
            '3. Segurança',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Adotamos medidas de segurança para proteger suas informações contra acessos não autorizados, alterações, divulgações ou destruições.',
          ),
          SizedBox(height: 24),

          Text(
            '4. Responsabilidade do usuário',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'O usuário é responsável por manter seus dados atualizados e proteger suas credenciais de acesso. Não nos responsabilizamos por dados incorretos fornecidos pelo usuário.',
          ),
          SizedBox(height: 24),

          Text(
            '5. Alterações nos termos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Reservamo-nos o direito de modificar esta política a qualquer momento. Mudanças significativas serão notificadas dentro do próprio app.',
          ),
          SizedBox(height: 24),

          Text(
            '6. Contato',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Em caso de dúvidas, sugestões ou solicitações relacionadas à privacidade, entre em contato através do e-mail de suporte fornecido na seção de contato do aplicativo.',
          ),
        ],
      ),
    );
  }
}
