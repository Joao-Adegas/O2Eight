# O₂Eight - Frontend

Aplicativo do O₂Eight, desenvolvido em Flutter. Durante o desenvolvimento, é executado como aplicação Web no navegador; o mesmo código-fonte pode gerar versões para Android e iOS.

## Sumário

- [Requisitos](#requisitos)
- [Configuração do Supabase](#configuração-do-supabase)
- [Configuração do aplicativo](#configuração-do-aplicativo)
- [Execução](#execução)
- [Fluxo de navegação](#fluxo-de-navegação)
- [Estrutura de pastas](#estrutura-de-pastas)
- [Solução de problemas](#solução-de-problemas)

## Requisitos

- Flutter SDK 3.27 ou superior (canal stable)
- Microsoft Edge ou Google Chrome
- Backend em execução em `http://localhost:8000` (ver `backend/README.md`)

Para verificar a instalação do Flutter:

```powershell
flutter doctor
```

## Configuração do Supabase

As configurações abaixo são feitas uma única vez no painel do Supabase.

**Redirecionamento do login**

Em **Authentication > URL Configuration**:

- **Site URL:** `http://localhost:5000`
- **Redirect URLs:** adicione `http://localhost:5000`

**Login com Google**

Em **Authentication > Sign In / Providers > Google**, informe o Client ID e o Client Secret gerados no Google Cloud Console (**APIs & Services > Credentials**). No Google Cloud Console, o redirect URI autorizado deve apontar para o projeto Supabase correto:

```
https://<id-do-projeto>.supabase.co/auth/v1/callback
```

**Login com e-mail e senha**

Em **Authentication > Sign In / Providers > Email**, mantenha o provedor ativado. A opção **Confirm email** define o comportamento do cadastro:

- **Ativada:** o usuário recebe um link por e-mail e só consegue entrar após confirmá-lo. O servidor de e-mail padrão do Supabase envia poucas mensagens por hora.
- **Desativada:** o usuário entra imediatamente após o cadastro. Recomendado durante o desenvolvimento.

## Configuração do aplicativo

**Credenciais do Supabase**

Em `lib/main.dart`, informe a URL do projeto e a chave anon:

```dart
await Supabase.initialize(
  url: 'https://<id-do-projeto>.supabase.co',
  anonKey: '<chave anon/publishable>',
);
```

A chave anon é pública por natureza e pode estar no aplicativo. A chave `service_role` nunca deve ser usada no frontend.

**Endereço da API**

O endereço do backend está definido como `http://localhost:8000` nos arquivos de `lib/services/`. Ao publicar a API em outro endereço, atualize a constante `_baseUrl` em cada um deles.

**Recursos gráficos**

As imagens ficam na pasta `images/` e precisam estar declaradas no `pubspec.yaml`:

```yaml
flutter:
  assets:
    - images/
```

O botão do Google usa `images/google_logo.png`. Se o arquivo não existir, uma letra "G" é exibida no lugar.

## Execução

A partir da pasta `frontend`:

1. Instale as dependências:

   ```powershell
   flutter pub get
   ```

2. Caso a pasta `web/` não exista no projeto, habilite o suporte à Web (apenas uma vez):

   ```powershell
   flutter create . --platforms=web
   ```

3. Execute o aplicativo:

   ```powershell
   flutter run -d edge --web-port=5000
   ```

   A porta 5000 é obrigatória, pois é o endereço cadastrado no Supabase para o retorno do login. Para usar o Chrome, substitua `edge` por `chrome`.

Comandos disponíveis no terminal durante a execução:

| Tecla | Ação |
|---|---|
| `r` | Hot reload: aplica alterações visuais mantendo o estado |
| `R` | Hot restart: reinicia o aplicativo, necessário após mudanças de lógica |
| `q` | Encerra a execução; necessário após alterar rotas, dependências ou o `pubspec.yaml` |

Para verificar erros de compilação sem executar o aplicativo:

```powershell
flutter analyze
```

## Fluxo de navegação

```
Login ──> Formulário de onboarding (somente no primeiro acesso) ──> Home
  │                                                                  │
  └──> Cadastro com e-mail e senha                                    └──> Chat
```

- A sessão fica salva no navegador. Se o usuário já estiver autenticado, a tela de login é ignorada e o aplicativo abre direto na Home.
- Ao abrir a Home, o aplicativo registra o usuário na API (`POST /auth/register-sso`) e verifica se o formulário já foi preenchido (`GET /form/me`). Caso não tenha sido, redireciona para o onboarding.
- O menu do avatar, no canto superior direito da Home, permite sair da conta.

Para testar o fluxo completo de um novo usuário, saia da conta pelo avatar ou abra uma janela InPrivate (`Ctrl+Shift+N`).

## Estrutura de pastas

```
lib/
├── main.dart                    Inicialização do Supabase e do aplicativo
├── app/
│   ├── app.dart                 MaterialApp e tema
│   └── routes.dart              Rotas nomeadas (AppRoutes)
├── core/theme/app_theme.dart    Cores e temas claro e escuro
├── models/                      Modelos de dados da interface
├── screens/
│   ├── login/                   Login com Google e com e-mail e senha
│   ├── signup/                  Cadastro com e-mail e senha
│   ├── form/                    Formulário de onboarding
│   ├── home/                    Painel de progresso
│   └── chat/                    Assistente com IA
├── services/                    Comunicação com a API e com o Supabase
│   ├── auth_service.dart
│   ├── form_service.dart
│   ├── progress_service.dart
│   └── chat_service.dart
└── widgets/                     Componentes compartilhados (barra inferior, avatar, botões)
```

## Solução de problemas

| Sintoma | Causa | Solução |
|---|---|---|
| `ClientException: Failed to fetch` | Backend desligado ou CORS não configurado | Inicie o backend e confira o `CORSMiddleware` |
| Login com Google volta para uma porta diferente | Aplicativo executado sem porta fixa | Use `--web-port=5000` |
| `AuthApiException: Invalid API key` | `anonKey` incorreta em `lib/main.dart` | Copie a chave novamente do painel do Supabase |
| Tela branca ou erros de renderização após atualizar dependências | Cache de compilação desatualizado | Execute `flutter clean` e depois `flutter pub get` |
| "E-mail ou senha incorretos" com uma conta criada pelo Google | Contas do Google não possuem senha | Entre pelo botão do Google |
| Nova rota não encontrada | Rotas alteradas com o aplicativo em execução | Encerre com `q` e execute novamente |
| "A assistente está indisponível agora" | Falha na chamada à Groq | Verifique o terminal do backend e a seção de solução de problemas do `backend/README.md` |