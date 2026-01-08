# 🔧 Como Forçar o App a Abrir ao Clicar no Link de Verificação

## 🎯 Problema
Quando você clica no link de verificação de email, o Android abre o navegador web em vez do app instalado.

## ✅ Solução: Configuração Manual no Android

### **Método 1: Configurar Manualmente no Android (Mais Fácil)**

1. **Abra as Configurações do Android**
2. Vá em **"Apps"** ou **"Aplicativos"**
3. Procure por **"Orcemais"**
4. Toque em **"Orcemais"**
5. Procure por **"Abrir por padrão"** ou **"Definir como padrão"**
6. Toque em **"Adicionar links"** ou **"Links compatíveis"**
7. **Ative** os seguintes domínios:
   - ☑️ `gestorfy-app.firebaseapp.com`
   - ☑️ `gestorfy-app.web.app`
   - ☑️ `orcemais.page.link`
8. Selecione **"Abrir neste app"** para todos

### **Método 2: Testar Link Direto (Teste Rápido)**

Depois de fazer o cadastro e receber o email:

1. **Abra o Gmail no celular**
2. **Clique e SEGURE** o link de verificação
3. No menu que aparecer, escolha:
   - **"Abrir com..."** ou **"Abrir link com"**
4. Selecione **"Orcemais"**
5. Marque **"Sempre"** para links futuros

### **Método 3: Limpar Configurações de Navegador Padrão**

Se o Chrome sempre abre automaticamente:

1. Vá em **Configurações** → **Apps**
2. Procure por **"Chrome"** ou **"Navegador"**
3. Toque em **"Abrir por padrão"**
4. Toque em **"Limpar padrões"**
5. Agora tente clicar no link novamente - deve perguntar qual app usar

### **Método 4: Via ADB (Avançado - Requer Computador)**

Se você tem o celular conectado ao PC:

```powershell
# Execute este comando no PowerShell
.\force_app_links.ps1
```

Ou manualmente:
```powershell
adb shell pm set-app-links --package com.orcemais.orcemais 0 gestorfy-app.firebaseapp.com
adb shell pm set-app-links --package com.orcemais.orcemais 0 gestorfy-app.web.app
```

## 🧪 Como Testar

### **Passo 1: Fazer Novo Cadastro**
1. Desinstale o app (para limpar cache)
2. Instale novamente: `flutter run -d 22101320G`
3. Faça um novo cadastro com email válido

### **Passo 2: Verificar Email**
1. Abra o **Gmail no celular** (mesmocelular onde o app está)
2. Localize o email de "Bem-vindo ao Orcemais!"
3. **NÃO clique direto no link ainda**

### **Passo 3: Configurar (só precisa fazer 1 vez)**
1. Siga o **Método 1** ou **Método 2** acima
2. Configure o app como padrão para os domínios

### **Passo 4: Clicar no Link**
1. Agora clique no botão "Verificar Email"
2. O app **Orcemais deve abrir** (não o Chrome)
3. Você verá a mensagem: "Email verificado com sucesso!"

## 📱 Comportamento Esperado

### ✅ Quando funciona corretamente:
```
1. Usuário clica no link de verificação
   ↓
2. Android detecta que é link do Firebase
   ↓
3. Verifica se há app instalado que aceita esse domínio
   ↓
4. Encontra "Orcemais" configurado para gestorfy-app.firebaseapp.com
   ↓
5. ABRE O APP ORCEMAIS (não o navegador)
   ↓
6. DeepLinkHandler processa o link
   ↓
7. Recarrega dados do usuário no Firebase
   ↓
8. Mostra "✅ Email verificado com sucesso!"
   ↓
9. Redireciona para a home do app
```

### ❌ Quando não funciona:
```
1. Usuário clica no link
   ↓
2. Android não encontra app configurado
   ↓
3. ABRE O CHROME (comportamento padrão)
   ↓
4. Mostra página web do Firebase
```

## 🔍 Verificar se está Configurado

**No celular:**
1. Vá em Configurações → Apps → Orcemais
2. Veja "Abrir por padrão"
3. Deve mostrar os domínios ativados

**Pelos logs do app:**
Quando você clicar no link e o app abrir, observe o terminal:
```
🔗 Deep link recebido: https://gestorfy-app.firebaseapp.com/...
🔗 Host: gestorfy-app.firebaseapp.com
🔗 Path: /...
📧 Link de verificação de email detectado!
📧 Processando verificação de email...
✅ Email verificado com sucesso!
```

## ⚠️ Limitações do Android

### Por que isso acontece?
O Android só abre automaticamente o app se:
1. ✅ O app está instalado
2. ✅ O AndroidManifest.xml tem os intent-filters corretos **(JÁ FEITO)**
3. ✅ O usuário configurou o app como padrão **(PRECISA FAZER)**
4. ❌ OU o app verificou automaticamente com Google (precisa assetlinks.json no servidor)

**Nossa implementação:** Itens 1 e 2 estão OK. O item 3 o usuário precisa fazer manualmente (é segurança do Android).

### Alternativa: Firebase Dynamic Links (Futuro)

Para abrir automaticamente sem configuração manual, seria necessário:
1. Criar Firebase Dynamic Links no console
2. Configurar domínio personalizado
3. Hospedar arquivo `assetlinks.json`

Isso é mais complexo e pode ser implementado depois se necessário.

## 📝 Checklist de Teste

- [ ] App compilado e instalado no celular
- [ ] Novo cadastro realizado
- [ ] Email de verificação recebido no Gmail do celular
- [ ] Configurações do app ajustadas (Método 1 ou 2)
- [ ] Link clicado no Gmail
- [ ] **App abriu** (não Chrome)
- [ ] Mensagem de sucesso apareceu
- [ ] Usuário foi redirecionado para home

## 💡 Dica Final

**Se mesmo assim não funcionar:** 

Abra o link no navegador, depois:
1. Na página que abrir, copie a URL completa
2. Volte pro app
3. No app, você pode criar uma tela de "Colar link de verificação"
4. O app processa o link manualmente

Mas tente primeiro os métodos acima! O mais fácil é o **Método 1** (configurar manualmente nas configurações do app).

---

**Última atualização:** 7 de janeiro de 2026
