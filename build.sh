#!/bin/bash

# Script de build para o MedMoney
# Autor: Seu Nome
# Data: $(date +%d/%m/%Y)

echo "🚀 Iniciando build do MedMoney..."

# Verificar se o Flutter está instalado
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter não encontrado. Por favor, instale o Flutter e tente novamente."
    exit 1
fi

# Limpar builds anteriores
echo "🧹 Limpando builds anteriores..."
flutter clean

# Obter dependências
echo "📦 Obtendo dependências..."
flutter pub get

# Verificar se há erros no código
echo "🔍 Verificando código..."
flutter analyze
if [ $? -ne 0 ]; then
    echo "⚠️ Há erros no código. Deseja continuar mesmo assim? (s/n)"
    read resposta
    if [ "$resposta" != "s" ]; then
        echo "❌ Build cancelado."
        exit 1
    fi
fi

# Perguntar qual plataforma deseja fazer o build
echo "📱 Para qual plataforma deseja fazer o build?"
echo "1. Android (APK)"
echo "2. Android (App Bundle)"
echo "3. iOS"
echo "4. Web"
echo "5. Todas as plataformas"
read plataforma

# Função para build do Android (APK)
build_android_apk() {
    echo "📱 Gerando APK para Android..."
    flutter build apk --release
    if [ $? -eq 0 ]; then
        echo "✅ APK gerado com sucesso em build/app/outputs/flutter-apk/app-release.apk"
    else
        echo "❌ Falha ao gerar APK para Android."
    fi
}

# Função para build do Android (App Bundle)
build_android_bundle() {
    echo "📱 Gerando App Bundle para Android..."
    flutter build appbundle --release
    if [ $? -eq 0 ]; then
        echo "✅ App Bundle gerado com sucesso em build/app/outputs/bundle/release/app-release.aab"
    else
        echo "❌ Falha ao gerar App Bundle para Android."
    fi
}

# Função para build do iOS
build_ios() {
    echo "🍎 Gerando build para iOS..."
    flutter build ios --release --no-codesign
    if [ $? -eq 0 ]; then
        echo "✅ Build para iOS gerado com sucesso."
        echo "⚠️ Nota: Para distribuição, abra o projeto no Xcode e configure a assinatura."
    else
        echo "❌ Falha ao gerar build para iOS."
    fi
}

# Função para build da Web
build_web() {
    echo "🌐 Gerando build para Web..."
    flutter build web --release
    if [ $? -eq 0 ]; then
        echo "✅ Build para Web gerado com sucesso em build/web/"
    else
        echo "❌ Falha ao gerar build para Web."
    fi
}

# Executar build conforme a escolha
case $plataforma in
    1)
        build_android_apk
        ;;
    2)
        build_android_bundle
        ;;
    3)
        build_ios
        ;;
    4)
        build_web
        ;;
    5)
        build_android_apk
        build_android_bundle
        build_ios
        build_web
        ;;
    *)
        echo "❌ Opção inválida."
        exit 1
        ;;
esac

echo "🎉 Processo de build concluído!" 