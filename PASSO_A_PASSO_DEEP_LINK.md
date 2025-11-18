# 🔗 Passo a Passo - Deep Link com Parâmetros Personalizados

## ✅ Status: IMPLEMENTADO!

Os parâmetros já estão sendo enviados corretamente nos Deep Links! 🎉

---

## 📋 O que é enviado na URL

Quando você compartilha um orçamento ou recibo via Link Web, a URL gerada contém:

### **Parâmetros Obrigatórios:**
- `userId` - ID do usuário no Firestore
- `documentoId` - ID do orçamento/recibo no Firestore  
- `tipoDocumento` - Tipo do documento (`orcamento` ou `recibo`)

### **Parâmetros de Cores (se personalizadas):**
- `corPrimaria` - Cor principal (ex: 4280391909)
- `corSecundaria` - Cor secundária/fundo (ex: 4293718525)
- `corTerciaria` - Cor terciária/fundo alternativo
- `corTextoSecundario` - Cor do texto em fundo secundário
- `corTextoTerciario` - Cor do texto em fundo terciário

---

## 🔍 Exemplo de URL Gerada

```
https://link.orcemais.com/xyz123

↓ Redireciona para:

https://gestorfy-cliente.web.app/?
  userId=abc123&
  documentoId=xyz789&
  tipoDocumento=orcamento&
  corPrimaria=4280391909&
  corSecundaria=4293718525&
  corTerciaria=4293980928&
  corTextoSecundario=4278190335&
  corTextoTerciario=4278190335
```

---

## 💻 Como Funciona no Código

### **1. Preparação dos Parâmetros**

**Orçamentos** (`compartilhar_orcamento.dart` - linhas 91-120):
```dart
final parametrosPersonalizados = <String, dynamic>{
  'userId': userProvider.uid,
  'documentoId': orcamento.id,
  'tipoDocumento': 'orcamento',
};

// Adicionar cores se personalizadas
if (businessProvider.pdfTheme != null) {
  final theme = businessProvider.pdfTheme!;
  if (theme['primary'] != null) {
    parametrosPersonalizados['corPrimaria'] = theme['primary'].toString();
  }
  // ... outras cores
}
```

**Recibos** (`compartilhar_recibo_page.dart` - linhas 308-337):
```dart
final parametrosPersonalizados = <String, dynamic>{
  'userId': userProvider.uid,
  'documentoId': recibo.id,
  'tipoDocumento': 'recibo',
};

// Adicionar cores se personalizadas
if (businessProvider.pdfTheme != null) {
  final theme = businessProvider.pdfTheme!;
  if (theme['primary'] != null) {
    parametrosPersonalizados['corPrimaria'] = theme['primary'].toString();
  }
  // ... outras cores
}
```

### **2. Criação do Deep Link**

```dart
final link = await DeepLink.createLink(
  LinkModel(
    dominio: 'link.orcemais.com',
    titulo: 'Orçamento ${orcamento.numero} - ${businessProvider.nomeEmpresa}',
    slug: orcamento.id,
    onlyWeb: true,
    urlImage: businessProvider.logoUrl,
    urlDesktop: 'https://gestorfy-cliente.web.app',
    parametrosPersonalizados: parametrosPersonalizados, // ← Aqui!
  ),
);
```

### **3. Resultado**

O `DeepLink.createLink` retorna um link curto que:
- Usa o domínio `link.orcemais.com`
- Redireciona para `gestorfy-cliente.web.app`
- **Passa todos os parâmetros na URL**

---

## 🎯 Fluxo Completo

```
┌─────────────────────────────────────────────────────────────┐
│ 1. GESTORFY APP (Mobile/Desktop)                            │
├─────────────────────────────────────────────────────────────┤
│ • Usuário cria orçamento/recibo                             │
│ • Define cores personalizadas (opcional)                    │
│ • Clica em "Compartilhar Link Web"                          │
│                                                              │
│ ⬇️ Coleta os dados:                                          │
│   - userId (do UserProvider)                                │
│   - documentoId (do orçamento/recibo)                       │
│   - tipoDocumento ('orcamento' ou 'recibo')                 │
│   - Cores do pdfTheme (se existirem)                        │
└─────────────────────────────────────────────────────────────┘
                            ⬇️
┌─────────────────────────────────────────────────────────────┐
│ 2. DEEP LINK SERVICE                                        │
├─────────────────────────────────────────────────────────────┤
│ • Cria link curto em link.orcemais.com                      │
│ • Associa todos os parâmetros ao link                       │
│ • Retorna URL curta: https://link.orcemais.com/xyz123       │
└─────────────────────────────────────────────────────────────┘
                            ⬇️
┌─────────────────────────────────────────────────────────────┐
│ 3. COMPARTILHAMENTO                                         │
├─────────────────────────────────────────────────────────────┤
│ • Link é enviado via WhatsApp/Email/SMS                     │
│ • Cliente clica no link                                     │
└─────────────────────────────────────────────────────────────┘
                            ⬇️
┌─────────────────────────────────────────────────────────────┐
│ 4. REDIRECIONAMENTO                                         │
├─────────────────────────────────────────────────────────────┤
│ link.orcemais.com/xyz123                                    │
│         ⬇️ redireciona para                                  │
│ gestorfy-cliente.web.app/?userId=...&documentoId=...        │
└─────────────────────────────────────────────────────────────┘
                            ⬇️
┌─────────────────────────────────────────────────────────────┐
│ 5. GESTORFY-CLIENTE (Flutter Web)                           │
├─────────────────────────────────────────────────────────────┤
│ ✅ Lê parâmetros da URL                                      │
│ ✅ Busca dados no Firestore usando userId e documentoId     │
│ ✅ Aplica cores personalizadas da URL                        │
│ ✅ Renderiza orçamento/recibo com visual customizado        │
└─────────────────────────────────────────────────────────────┘
```

---

## 🧪 Como Testar

### **No App Gestorfy:**

1. **Personalize as cores:**
   - Vá em **Personalizar PDF**
   - Altere as cores principais
   - Salve

2. **Crie um orçamento:**
   - Vá em **Orçamentos** → **Novo Orçamento**
   - Preencha os dados
   - Adicione itens

3. **Gere o Link Web:**
   - Na última etapa, escolha **"Link Web"**
   - Veja o preview com suas cores
   - Clique em **"Compartilhar"**

4. **Copie o link gerado**

5. **Abra em um navegador:**
   - Cole a URL no navegador
   - Verifique se as cores aparecem corretamente

### **Validar os Parâmetros:**

Abra o Console do navegador (F12) e execute:
```javascript
console.log(window.location.href);
// Deve mostrar todos os parâmetros na URL
```

---

## 📦 Arquivos Modificados

| Arquivo | Linhas | O que faz |
|---------|--------|-----------|
| `compartilhar_orcamento.dart` | 91-120 | Prepara parâmetros do orçamento |
| `compartilhar_recibo_page.dart` | 308-337 | Prepara parâmetros do recibo |
| Ambos | DeepLink.createLink | Envia parâmetros na URL |

---

## ✅ Checklist de Implementação

- [x] Adicionar `userId` nos parâmetros
- [x] Adicionar `documentoId` nos parâmetros
- [x] Adicionar `tipoDocumento` nos parâmetros
- [x] Passar cores personalizadas (`corPrimaria`, etc)
- [x] Testar com orçamentos
- [x] Testar com recibos
- [ ] Implementar leitura no `gestorfy-cliente.web.app` (próximo passo)

---

## 🚀 Próximos Passos

Agora que o **Gestorfy** já está enviando todos os parâmetros, você precisa:

1. **No projeto `gestorfy-cliente` (Flutter Web):**
   - Implementar leitura dos parâmetros da URL
   - Buscar dados no Firestore usando `userId` e `documentoId`
   - Aplicar as cores personalizadas
   - Renderizar o documento

2. **Siga o guia:**
   - Veja o arquivo `GUIA_INTEGRACAO_FLUTTER_WEB.md`
   - Copie o código do `UrlParamsHelper`
   - Implemente a página de visualização

---

## 🎉 Resultado Final

Quando tudo estiver implementado:

```
✅ Usuário personaliza cores no app
✅ Link compartilhado contém todas as informações
✅ Cliente abre o link e vê o orçamento/recibo
✅ Visual está idêntico com cores personalizadas
✅ Tudo funcionando automaticamente!
```

---

**Dúvidas?** Consulte o `GUIA_INTEGRACAO_FLUTTER_WEB.md` para a implementação no projeto `gestorfy-cliente`! 😊
