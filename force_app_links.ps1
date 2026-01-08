# Script para forçar o app a ser o handler padrão de links
Write-Host "🔧 Configurando App Links no Android..." -ForegroundColor Cyan

# Verifica se há dispositivo conectado
$device = adb devices | Select-String "device$" | Select-Object -First 1
if (-not $device) {
    Write-Host "❌ Nenhum dispositivo Android conectado!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Dispositivo encontrado" -ForegroundColor Green

# Força o app a ser o handler padrão
Write-Host "`n📱 Configurando Orcemais como handler padrão..." -ForegroundColor Cyan
adb shell pm set-app-links --package com.orcemais.orcemais 0 gestorfy-app.firebaseapp.com
adb shell pm set-app-links --package com.orcemais.orcemais 0 gestorfy-app.web.app
adb shell pm set-app-links --package com.orcemais.orcemais 0 orcemais.page.link

# Verifica o status
Write-Host "`n📊 Status dos App Links:" -ForegroundColor Cyan
adb shell pm get-app-links com.orcemais.orcemais

Write-Host "`n✅ Configuração concluída!" -ForegroundColor Green
Write-Host "Agora teste clicando no link de verificação no email." -ForegroundColor Yellow
