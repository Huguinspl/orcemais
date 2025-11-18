# 🎨 Guia de Implementação - Cores Personalizadas no Web

## 📋 Resumo
Este guia mostra como implementar a leitura das cores personalizadas enviadas pelo app Flutter no projeto `gestorfy-cliente.web.app`.

---

## 🔗 Parâmetros Recebidos na URL

Quando o usuário compartilha um orçamento/recibo, a URL terá estes parâmetros:

```
https://gestorfy-cliente.web.app/?
  userId=abc123&
  documentoId=xyz789&
  tipoDocumento=orcamento&
  corPrimaria=4280391909&
  corSecundaria=4293718525&
  corTerciaria=4289774331&
  corTextoSecundario=4278216609&
  corTextoTerciario=4278216609
```

---

## 🛠️ Implementação JavaScript

### **1. Função para Converter ARGB para CSS**

Adicione esta função no seu arquivo JavaScript principal:

```javascript
/**
 * Converte valor ARGB (int) para formato CSS rgba()
 * @param {string} argbString - String do valor ARGB (ex: "4280391909")
 * @returns {string} - Cor no formato "rgba(r, g, b, a)"
 */
function argbParaCss(argbString) {
  if (!argbString) return null;
  
  const argb = parseInt(argbString);
  const a = ((argb >> 24) & 0xFF) / 255; // Alpha (0-1)
  const r = (argb >> 16) & 0xFF;          // Red (0-255)
  const g = (argb >> 8) & 0xFF;           // Green (0-255)
  const b = argb & 0xFF;                  // Blue (0-255)
  
  return `rgba(${r}, ${g}, ${b}, ${a})`;
}

/**
 * Converte ARGB para formato hexadecimal #RRGGBB
 * @param {string} argbString - String do valor ARGB
 * @returns {string} - Cor no formato "#RRGGBB"
 */
function argbParaHex(argbString) {
  if (!argbString) return null;
  
  const argb = parseInt(argbString);
  const r = (argb >> 16) & 0xFF;
  const g = (argb >> 8) & 0xFF;
  const b = argb & 0xFF;
  
  const hex = '#' + [r, g, b].map(x => {
    const h = x.toString(16);
    return h.length === 1 ? '0' + h : h;
  }).join('');
  
  return hex;
}
```

---

### **2. Função para Ler Parâmetros da URL**

```javascript
/**
 * Lê todos os parâmetros da URL
 * @returns {Object} - Objeto com todos os parâmetros
 */
function obterParametrosUrl() {
  const urlParams = new URLSearchParams(window.location.search);
  
  return {
    userId: urlParams.get('userId'),
    documentoId: urlParams.get('documentoId'),
    tipoDocumento: urlParams.get('tipoDocumento'),
    corPrimaria: urlParams.get('corPrimaria'),
    corSecundaria: urlParams.get('corSecundaria'),
    corTerciaria: urlParams.get('corTerciaria'),
    corTextoSecundario: urlParams.get('corTextoSecundario'),
    corTextoTerciario: urlParams.get('corTextoTerciario'),
  };
}

/**
 * Obtém as cores personalizadas ou retorna cores padrão
 * @param {string} tipoDocumento - 'orcamento' ou 'recibo'
 * @returns {Object} - Objeto com as cores em formato CSS
 */
function obterCoresPersonalizadas(tipoDocumento) {
  const params = obterParametrosUrl();
  
  // Cores padrão (caso não tenha personalização)
  const coresPadrao = tipoDocumento === 'orcamento' ? {
    primaria: '#1976D2',      // Azul
    secundaria: '#E3F2FD',
    terciaria: '#BBDEFB',
    textoSecundario: '#0D47A1',
    textoTerciario: '#0D47A1',
  } : {
    primaria: '#FF6B00',      // Laranja
    secundaria: '#FFF3E0',
    terciaria: '#FFE0B2',
    textoSecundario: '#E65100',
    textoTerciario: '#E65100',
  };
  
  // Usar cores personalizadas se existirem
  return {
    primaria: argbParaHex(params.corPrimaria) || coresPadrao.primaria,
    secundaria: argbParaHex(params.corSecundaria) || coresPadrao.secundaria,
    terciaria: argbParaHex(params.corTerciaria) || coresPadrao.terciaria,
    textoSecundario: argbParaHex(params.corTextoSecundario) || coresPadrao.textoSecundario,
    textoTerciario: argbParaHex(params.corTextoTerciario) || coresPadrao.textoTerciario,
  };
}
```

---

### **3. Aplicar Cores na Página**

#### **Opção A: Via CSS Variables (RECOMENDADO)**

```javascript
/**
 * Aplica as cores personalizadas usando CSS Variables
 */
function aplicarCoresPersonalizadas() {
  const params = obterParametrosUrl();
  const cores = obterCoresPersonalizadas(params.tipoDocumento);
  
  // Define as variáveis CSS no :root
  document.documentElement.style.setProperty('--cor-primaria', cores.primaria);
  document.documentElement.style.setProperty('--cor-secundaria', cores.secundaria);
  document.documentElement.style.setProperty('--cor-terciaria', cores.terciaria);
  document.documentElement.style.setProperty('--cor-texto-secundario', cores.textoSecundario);
  document.documentElement.style.setProperty('--cor-texto-terciario', cores.textoTerciario);
  
  console.log('✅ Cores aplicadas:', cores);
}

// Chamar quando a página carregar
document.addEventListener('DOMContentLoaded', aplicarCoresPersonalizadas);
```

**CSS correspondente:**

```css
:root {
  /* Cores padrão (fallback) */
  --cor-primaria: #1976D2;
  --cor-secundaria: #E3F2FD;
  --cor-terciaria: #BBDEFB;
  --cor-texto-secundario: #0D47A1;
  --cor-texto-terciario: #0D47A1;
}

/* Aplicar cores nos elementos */
.header {
  background-color: var(--cor-primaria);
  color: white;
}

.section-label {
  background-color: var(--cor-terciaria);
  color: var(--cor-texto-terciario);
}

.totals-container {
  background-color: var(--cor-secundaria);
  border: 1px solid var(--cor-primaria);
}

.item-card {
  border: 2px solid var(--cor-primaria);
}

.item-header {
  background: linear-gradient(135deg, var(--cor-primaria), var(--cor-primaria)88);
}

.badge-numero {
  background-color: var(--cor-primaria);
}

.total-destaque {
  color: var(--cor-primaria);
}
```

---

#### **Opção B: Via JavaScript Direto (Alternativa)**

```javascript
/**
 * Aplica cores diretamente nos elementos via JavaScript
 */
function aplicarCoresDiretamente() {
  const params = obterParametrosUrl();
  const cores = obterCoresPersonalizadas(params.tipoDocumento);
  
  // Header
  const headers = document.querySelectorAll('.header, .cabecalho');
  headers.forEach(el => {
    el.style.backgroundColor = cores.primaria;
    el.style.color = 'white';
  });
  
  // Labels de seção
  const labels = document.querySelectorAll('.section-label, .label-secao');
  labels.forEach(el => {
    el.style.backgroundColor = cores.terciaria;
    el.style.color = cores.textoTerciario;
  });
  
  // Container de totais
  const totals = document.querySelectorAll('.totals-container, .container-totais');
  totals.forEach(el => {
    el.style.backgroundColor = cores.secundaria;
    el.style.borderColor = cores.primaria;
  });
  
  // Cards de itens
  const cards = document.querySelectorAll('.item-card, .card-item');
  cards.forEach(el => {
    el.style.borderColor = cores.primaria;
  });
  
  // Header dos cards
  const cardHeaders = document.querySelectorAll('.item-header, .card-header');
  cardHeaders.forEach(el => {
    el.style.background = `linear-gradient(135deg, ${cores.primaria}, ${cores.primaria}88)`;
  });
  
  // Badges de número
  const badges = document.querySelectorAll('.badge-numero, .numero-item');
  badges.forEach(el => {
    el.style.backgroundColor = cores.primaria;
    el.style.color = 'white';
  });
  
  // Totais em destaque
  const totaisDestaque = document.querySelectorAll('.total-destaque, .valor-total');
  totaisDestaque.forEach(el => {
    el.style.color = cores.primaria;
  });
}
```

---

## 🎯 Exemplo Completo de Implementação

### **index.html**

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Orçamento - Gestorfy</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <!-- Header -->
    <div class="header">
        <div class="logo">Empresa XYZ</div>
        <div class="info">contato@empresa.com</div>
    </div>
    
    <!-- Conteúdo -->
    <div class="container">
        <div class="section-label">Dados do Cliente</div>
        <div class="cliente-info">...</div>
        
        <div class="section-label">Itens do Orçamento</div>
        <div class="item-card">
            <div class="item-header">
                <div class="badge-numero">1</div>
                <div class="item-nome">Item 1</div>
            </div>
            <div class="item-body">...</div>
        </div>
        
        <div class="totals-container">
            <div class="total-destaque">R$ 1.000,00</div>
        </div>
    </div>
    
    <script src="cores.js"></script>
    <script src="main.js"></script>
</body>
</html>
```

### **cores.js**

```javascript
// Copie todo o código das funções acima aqui
function argbParaCss(argbString) { /* ... */ }
function argbParaHex(argbString) { /* ... */ }
function obterParametrosUrl() { /* ... */ }
function obterCoresPersonalizadas(tipoDocumento) { /* ... */ }
function aplicarCoresPersonalizadas() { /* ... */ }

// Aplicar cores ao carregar
document.addEventListener('DOMContentLoaded', aplicarCoresPersonalizadas);
```

---

## 🧪 Teste Local

Para testar localmente, adicione parâmetros na URL:

```
http://localhost:3000/?
  userId=teste123&
  documentoId=doc456&
  tipoDocumento=orcamento&
  corPrimaria=4280391909&
  corSecundaria=4293718525&
  corTerciaria=4289774331&
  corTextoSecundario=4278216609&
  corTextoTerciario=4278216609
```

---

## 🐛 Debug

Adicione logs para verificar se está funcionando:

```javascript
function aplicarCoresPersonalizadas() {
  const params = obterParametrosUrl();
  console.log('📋 Parâmetros recebidos:', params);
  
  const cores = obterCoresPersonalizadas(params.tipoDocumento);
  console.log('🎨 Cores calculadas:', cores);
  
  // Aplicar cores...
  
  console.log('✅ Cores aplicadas com sucesso!');
}
```

---

## ✅ Checklist de Implementação

- [ ] Adicionar função `argbParaCss()` e `argbParaHex()`
- [ ] Adicionar função `obterParametrosUrl()`
- [ ] Adicionar função `obterCoresPersonalizadas()`
- [ ] Adicionar função `aplicarCoresPersonalizadas()`
- [ ] Atualizar CSS com variáveis `--cor-*`
- [ ] Testar com URL de exemplo
- [ ] Verificar console do navegador
- [ ] Testar no mobile
- [ ] Validar cores padrão (sem parâmetros)

---

## 🎨 Mapeamento de Cores

| Parâmetro Flutter | Variável CSS | Uso |
|-------------------|--------------|-----|
| `corPrimaria` | `--cor-primaria` | Header, badges, bordas |
| `corSecundaria` | `--cor-secundaria` | Fundo totais, cards |
| `corTerciaria` | `--cor-terciaria` | Labels seções |
| `corTextoSecundario` | `--cor-texto-secundario` | Texto em labels |
| `corTextoTerciario` | `--cor-texto-terciario` | Texto em labels |

---

## 🚀 Pronto!

Agora seu sistema web vai:
1. ✅ Ler as cores da URL
2. ✅ Converter ARGB para CSS
3. ✅ Aplicar automaticamente na página
4. ✅ Usar cores padrão se não houver personalização

**Precisa de ajuda com alguma parte específica?** 😊
