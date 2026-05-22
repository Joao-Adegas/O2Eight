# flutter_version

Conversao do frontend React para Flutter com foco mobile.

## Estrutura

- lib/main.dart
- lib/app/app.dart
- lib/app/routes.dart
- lib/core/theme/app_theme.dart
- lib/screens/home/home_screen.dart
- lib/components
- lib/models
- lib/services

## Gerar projeto somente Android e iOS

Se a pasta estiver sem android e ios, execute na raiz de flutter_version:

1. flutter create . --platforms=android,ios
2. flutter pub get

## Rodar no Android

1. flutter devices
2. flutter run -d <id_do_dispositivo_android>

## Rodar no iOS (macOS com Xcode)

1. flutter devices
2. flutter run -d <id_do_simulador_ou_iphone>

## Testes

1. flutter test

## Build

Android APK:

1. flutter build apk --release

Android App Bundle:

1. flutter build appbundle --release

iOS (ipa requer assinatura/configuracao no Xcode):

1. flutter build ios --release
