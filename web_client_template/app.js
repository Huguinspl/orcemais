// Configuração do Firebase (SUBSTITUA com suas credenciais)
const firebaseConfig = {
    apiKey: "SUA_API_KEY",
    authDomain: "SEU_PROJETO.firebaseapp.com",
    projectId: "SEU_PROJETO_ID",
    storageBucket: "SEU_PROJETO.appspot.com",
    messagingSenderId: "SEU_SENDER_ID",
    appId: "SEU_APP_ID"
};

// Inicializar Firebase
firebase.initializeApp(firebaseConfig);
const db = firebase.firestore();

// Função para converter ARGB (int) para CSS rgba
function argbParaCss(argbString) {
    if (!argbString) return null;
    
    const argb = parseInt(argbString);
    const a = ((argb >> 24) & 0xFF) / 255;
    const r = (argb >> 16) & 0xFF;
    const g = (argb >> 8) & 0xFF;
    const b = argb & 0xFF;
    
    return `rgba(${r}, ${g}, ${b}, ${a})`;
}

// Função para aplicar cores personalizadas
function aplicarCoresPersonalizadas(params) {
    const root = document.documentElement;
    
    if (params.corPrimaria) {
        const corPrimaria = argbParaCss(params.corPrimaria);
        root.style.setProperty('--cor-primaria', corPrimaria);
        root.style.setProperty('--cor-primaria-light', corPrimaria.replace('1)', '0.2)'));
        root.style.setProperty('--cor-primaria-shadow', corPrimaria.replace('1)', '0.08)'));
        root.style.setProperty('--cor-primaria-chip', corPrimaria.replace('1)', '0.08)'));
        
        // Gradiente para o header dos itens
        const corLight = corPrimaria.replace('1)', '0.1)');
        const corLighter = corPrimaria.replace('1)', '0.05)');
        root.style.setProperty('--cor-primaria-gradient', 
            `linear-gradient(135deg, ${corLight} 0%, ${corLighter} 100%)`);
    }
    
    if (params.corSecundaria) {
        root.style.setProperty('--cor-secundaria', argbParaCss(params.corSecundaria));
    }
    
    if (params.corTerciaria) {
        root.style.setProperty('--cor-terciaria', argbParaCss(params.corTerciaria));
    }
    
    if (params.corTextoSecundario) {
        root.style.setProperty('--cor-texto-secundario', argbParaCss(params.corTextoSecundario));
    }
    
    if (params.corTextoTerciario) {
        root.style.setProperty('--cor-texto-terciario', argbParaCss(params.corTextoTerciario));
    }
}

// Função para formatar moeda
function formatarMoeda(valor) {
    return new Intl.NumberFormat('pt-BR', {
        style: 'currency',
        currency: 'BRL'
    }).format(valor);
}

// Função para criar ícone SVG
function criarIcone(tipo) {
    const icones = {
        phone: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16"><path d="M3.654 1.328a.678.678 0 0 0-1.015-.063L1.605 2.3c-.483.484-.661 1.169-.45 1.77a17.568 17.568 0 0 0 4.168 6.608 17.569 17.569 0 0 0 6.608 4.168c.601.211 1.286.033 1.77-.45l1.034-1.034a.678.678 0 0 0-.063-1.015l-2.307-1.794a.678.678 0 0 0-.58-.122l-2.19.547a1.745 1.745 0 0 1-1.657-.459L5.482 8.062a1.745 1.745 0 0 1-.46-1.657l.548-2.19a.678.678 0 0 0-.122-.58L3.654 1.328zM1.884.511a1.745 1.745 0 0 1 2.612.163L6.29 2.98c.329.423.445.974.315 1.494l-.547 2.19a.678.678 0 0 0 .178.643l2.457 2.457a.678.678 0 0 0 .644.178l2.189-.547a1.745 1.745 0 0 1 1.494.315l2.306 1.794c.829.645.905 1.87.163 2.611l-1.034 1.034c-.74.74-1.846 1.065-2.877.702a18.634 18.634 0 0 1-7.01-4.42 18.634 18.634 0 0 1-4.42-7.009c-.362-1.03-.037-2.137.703-2.877L1.885.511z"/></svg>',
        email: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16"><path d="M0 4a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2V4Zm2-1a1 1 0 0 0-1 1v.217l7 4.2 7-4.2V4a1 1 0 0 0-1-1H2Zm13 2.383-4.708 2.825L15 11.105V5.383Zm-.034 6.876-5.64-3.471L8 9.583l-1.326-.795-5.64 3.47A1 1 0 0 0 2 13h12a1 1 0 0 0 .966-.741ZM1 11.105l4.708-2.897L1 5.383v5.722Z"/></svg>',
        location: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16"><path d="M8 16s6-5.686 6-10A6 6 0 0 0 2 6c0 4.314 6 10 6 10zm0-7a3 3 0 1 1 0-6 3 3 0 0 1 0 6z"/></svg>',
        badge: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16"><path d="M8 16A8 8 0 1 0 8 0a8 8 0 0 0 0 16zm0-1A7 7 0 1 1 8 1a7 7 0 0 1 0 14z"/><path d="M8 6a.5.5 0 0 1 .5.5V10a.5.5 0 0 1-1 0V6.5A.5.5 0 0 1 8 6z"/></svg>',
        description: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16"><path d="M14 4.5V14a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V2a2 2 0 0 1 2-2h5.5L14 4.5zm-3 0A1.5 1.5 0 0 1 9.5 3V1H4a1 1 0 0 0-1 1v12a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1V4.5h-2z"/><path d="M4.603 14.087a.81.81 0 0 1-.438-.42c-.195-.388-.13-.776.08-1.102.198-.307.526-.568.897-.787a7.68 7.68 0 0 1 1.482-.645 19.697 19.697 0 0 0 1.062-2.227 7.269 7.269 0 0 1-.43-1.295c-.086-.4-.119-.796-.046-1.136.075-.354.274-.672.65-.823.192-.077.4-.12.602-.077a.7.7 0 0 1 .477.365c.088.164.12.356.127.538.007.188-.012.396-.047.614-.084.51-.27 1.134-.52 1.794a10.954 10.954 0 0 0 .98 1.686 5.753 5.753 0 0 1 1.334.05c.364.066.734.195.96.465.12.144.193.32.2.518.007.192-.047.382-.138.563a1.04 1.04 0 0 1-.354.416.856.856 0 0 1-.51.138c-.331-.014-.654-.196-.933-.417a5.712 5.712 0 0 1-.911-.95 11.651 11.651 0 0 0-1.997.406 11.307 11.307 0 0 1-1.02 1.51c-.292.35-.609.656-.927.787a.793.793 0 0 1-.58.029zm1.379-1.901c-.166.076-.32.156-.459.238-.328.194-.541.383-.647.547-.094.145-.096.25-.04.361.01.022.02.036.026.044a.266.266 0 0 0 .035-.012c.137-.056.355-.235.635-.572a8.18 8.18 0 0 0 .45-.606zm1.64-1.33a12.71 12.71 0 0 1 1.01-.193 11.744 11.744 0 0 1-.51-.858 20.801 20.801 0 0 1-.5 1.05zm2.446.45c.15.163.296.3.435.41.24.19.407.253.498.256a.107.107 0 0 0 .07-.015.307.307 0 0 0 .094-.125.436.436 0 0 0 .059-.2.095.095 0 0 0-.026-.063c-.052-.062-.2-.152-.518-.209a3.876 3.876 0 0 0-.612-.053zM8.078 7.8a6.7 6.7 0 0 0 .2-.828c.031-.188.043-.343.038-.465a.613.613 0 0 0-.032-.198.517.517 0 0 0-.145.04c-.087.035-.158.106-.196.283-.04.192-.03.469.046.822.024.111.054.227.09.346z"/></svg>',
        basket: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16"><path d="M5.757 1.071a.5.5 0 0 1 .172.686L3.383 6h9.234L10.07 1.757a.5.5 0 1 1 .858-.514L13.783 6H15a1 1 0 0 1 1 1v1a1 1 0 0 1-1 1v4.5a2.5 2.5 0 0 1-2.5 2.5h-9A2.5 2.5 0 0 1 1 13.5V9a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h1.217L5.07 1.243a.5.5 0 0 1 .686-.172zM2 9v4.5A1.5 1.5 0 0 0 3.5 15h9a1.5 1.5 0 0 0 1.5-1.5V9H2zM1 7v1h14V7H1zm3 3a.5.5 0 0 1 .5.5v3a.5.5 0 0 1-1 0v-3A.5.5 0 0 1 4 10zm2 0a.5.5 0 0 1 .5.5v3a.5.5 0 0 1-1 0v-3A.5.5 0 0 1 6 10zm2 0a.5.5 0 0 1 .5.5v3a.5.5 0 0 1-1 0v-3A.5.5 0 0 1 8 10zm2 0a.5.5 0 0 1 .5.5v3a.5.5 0 0 1-1 0v-3a.5.5 0 0 1 .5-.5zm2 0a.5.5 0 0 1 .5.5v3a.5.5 0 0 1-1 0v-3a.5.5 0 0 1 .5-.5z"/></svg>',
        money: '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16"><path d="M4 10.781c.148 1.667 1.513 2.85 3.591 3.003V15h1.043v-1.216c2.27-.179 3.678-1.438 3.678-3.3 0-1.59-.947-2.51-2.956-3.028l-.722-.187V3.467c1.122.11 1.879.714 2.07 1.616h1.47c-.166-1.6-1.54-2.748-3.54-2.875V1H7.591v1.233c-1.939.23-3.27 1.472-3.27 3.156 0 1.454.966 2.483 2.661 2.917l.61.162v4.031c-1.149-.17-1.94-.8-2.131-1.718H4zm3.391-3.836c-1.043-.263-1.6-.825-1.6-1.616 0-.944.704-1.641 1.8-1.828v3.495l-.2-.05zm1.591 1.872c1.287.323 1.852.859 1.852 1.769 0 1.097-.826 1.828-2.2 1.939V8.73l.348.086z"/></svg>'
    };
    return icones[tipo] || '';
}

// Função para renderizar o orçamento
function renderizarOrcamento(orcamento, negocio) {
    const container = document.getElementById('container');
    
    let html = `
        <div class="header">
            ${negocio.logoUrl ? `<img src="${negocio.logoUrl}" alt="Logo" class="logo">` : ''}
            <div class="header-info">
                <h1>${negocio.nomeEmpresa || 'Empresa'}</h1>
                ${negocio.telefone ? `<p>${criarIcone('phone')} ${negocio.telefone}</p>` : ''}
                ${negocio.emailEmpresa ? `<p>${criarIcone('email')} ${negocio.emailEmpresa}</p>` : ''}
            </div>
        </div>
        
        <div class="content">
            ${negocio.descricao ? `<p style="margin-bottom: 24px; color: #555;">${negocio.descricao}</p>` : ''}
            
            <div class="divider"></div>
            
            <span class="section-label">Dados do Cliente</span>
            <div class="client-info">
                <div class="label">Cliente:</div>
                <div class="value">${orcamento.cliente.nome}</div>
                ${orcamento.cliente.celular ? `<div class="value">${orcamento.cliente.celular}</div>` : ''}
                ${orcamento.cliente.email ? `<div class="value">${orcamento.cliente.email}</div>` : ''}
            </div>
            
            <span class="section-label">Itens do Orçamento</span>
            <div class="items-list">
    `;
    
    // Renderizar itens
    orcamento.itens.forEach((item, index) => {
        const preco = item.preco || 0;
        const quantidade = item.quantidade || 1;
        const totalItem = preco * quantidade;
        
        html += `
            <div class="item-card">
                <div class="item-header">
                    <div class="item-number">${index + 1}</div>
                    <div class="item-name">${item.nome || 'Item'}</div>
                </div>
                <div class="item-body">
                    ${item.descricao ? `
                        <div class="item-description">
                            <span class="item-description-icon">${criarIcone('description')}</span>
                            <span>${item.descricao}</span>
                        </div>
                    ` : ''}
                    
                    <div class="item-chips">
                        <div class="info-chip">
                            <div class="info-chip-label">
                                ${criarIcone('basket')} Quantidade
                            </div>
                            <div class="info-chip-value">${quantidade.toFixed(2)}</div>
                        </div>
                        <div class="info-chip">
                            <div class="info-chip-label">
                                ${criarIcone('money')} Valor Unit.
                            </div>
                            <div class="info-chip-value">${formatarMoeda(preco)}</div>
                        </div>
                    </div>
                    
                    <div class="item-divider"></div>
                    
                    <div class="item-total">
                        <span class="item-total-label">Total do Item</span>
                        <span class="item-total-value">${formatarMoeda(totalItem)}</span>
                    </div>
                </div>
            </div>
        `;
    });
    
    html += `
            </div>
            
            <div class="totals-container">
                <div class="total-row">
                    <span>Subtotal</span>
                    <span>${formatarMoeda(orcamento.subtotal || 0)}</span>
                </div>
                ${orcamento.desconto > 0 ? `
                    <div class="total-row">
                        <span>Desconto</span>
                        <span>- ${formatarMoeda(orcamento.desconto)}</span>
                    </div>
                ` : ''}
                <div class="total-row grand-total">
                    <span>Valor Total</span>
                    <span>${formatarMoeda(orcamento.valorTotal || 0)}</span>
                </div>
            </div>
        </div>
    `;
    
    container.innerHTML = html;
    container.classList.add('show');
}

// Função para mostrar erro
function mostrarErro(mensagem) {
    const container = document.getElementById('container');
    container.innerHTML = `
        <div class="content">
            <div class="error">
                <h2>❌ Erro</h2>
                <p>${mensagem}</p>
            </div>
        </div>
    `;
    container.classList.add('show');
}

// Função principal
async function carregarOrcamento() {
    try {
        // Obter parâmetros da URL
        const urlParams = new URLSearchParams(window.location.search);
        const userId = urlParams.get('userId');
        const documentoId = urlParams.get('documentoId');
        const tipoDocumento = urlParams.get('tipoDocumento') || 'orcamento';
        
        // Aplicar cores personalizadas
        aplicarCoresPersonalizadas({
            corPrimaria: urlParams.get('corPrimaria'),
            corSecundaria: urlParams.get('corSecundaria'),
            corTerciaria: urlParams.get('corTerciaria'),
            corTextoSecundario: urlParams.get('corTextoSecundario'),
            corTextoTerciario: urlParams.get('corTextoTerciario')
        });
        
        if (!userId || !documentoId) {
            throw new Error('Parâmetros inválidos na URL');
        }
        
        // Buscar orçamento do Firestore
        const orcamentoDoc = await db
            .collection('usuarios')
            .doc(userId)
            .collection(tipoDocumento === 'recibo' ? 'recibos' : 'orcamentos')
            .doc(documentoId)
            .get();
        
        if (!orcamentoDoc.exists) {
            throw new Error('Orçamento não encontrado');
        }
        
        const orcamento = orcamentoDoc.data();
        
        // Buscar dados do negócio
        const negocioDoc = await db
            .collection('usuarios')
            .doc(userId)
            .collection('negocio')
            .doc('info')
            .get();
        
        const negocio = negocioDoc.exists ? negocioDoc.data() : {};
        
        // Ocultar loading
        document.getElementById('loading').style.display = 'none';
        
        // Renderizar
        renderizarOrcamento(orcamento, negocio);
        
    } catch (error) {
        console.error('Erro:', error);
        document.getElementById('loading').style.display = 'none';
        mostrarErro(error.message || 'Erro ao carregar orçamento');
    }
}

// Iniciar quando a página carregar
window.addEventListener('DOMContentLoaded', carregarOrcamento);
