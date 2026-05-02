# 🎮 GameVault

> Biblioteca pessoal de jogos

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%2B%20Auth-FFCA28?logo=firebase)
![RAWG API](https://img.shields.io/badge/API-RAWG.io-blueviolet)
## ✨ Funcionalidades

- 🔐 **Login com Google** via Firebase Authentication
- 🏠 **Home Page** com lista paginada de jogos populares
- 🔍 **Busca** por nome com modo exato e amplo
- 🎛️ **Filtros laterais** por gênero, plataforma e tipo de jogo
- 🎮 **Página do Jogo** com:
  - Classificação etária (ESRB)
  - Nota Metacritic
  - Desenvolvedora e distribuidora
  - Plataformas disponíveis
  - Tempo de conclusão (HowLongToBeat)
  - Galeria de screenshots e trailers inline
  - Requisitos mínimos de sistema (PC)
  - Onde comprar (Steam, GOG, Epic, PlayStation, Xbox, Nintendo)
  - Preço atual na Steam em R$
  - DLCs e expansões clicáveis
  - Sinopse traduzida automaticamente para PT-BR
- ❤️ **Wishlist** pessoal salva no Firestore
- 📄 **Paginação numérica** estilo Steam

---

## 🏗️ Arquitetura da Aplicação

```
GameVault
│
├── lib/
│   ├── main.dart                    # Ponto de entrada, inicialização Firebase
│   ├── firebase_options.dart        # Configurações geradas pelo FlutterFire CLI
│   │
│   ├── models/
│   │   └── game.dart                # Modelo de dados do jogo (fromJson, helpers)
│   │
│   ├── services/
│   │   ├── api_service.dart         # Integração RAWG API + Steam API + HLTB
│   │   ├── firebase_service.dart    # Auth Google + Firestore (wishlist)
│   │   └── translation_service.dart # Tradução PT-BR via MyMemory API
│   │
│   ├── screens/
│   │   ├── login_screen.dart        # Tela de login com Google
│   │   ├── home_screen.dart         # Lista principal + filtros + busca
│   │   ├── game_details_screen.dart # Página completa do jogo
│   │   └── wishlist_screen.dart     # Lista de desejos do usuário
│   │
│   └── widgets/
│       └── media_viewer.dart        # Popup de screenshots e vídeos inline
│
├── android/                         # Configurações Android
├── pubspec.yaml                     # Dependências do projeto
└── README.md
```

### Fluxo de dados

```
Usuário
   │
   ▼
LoginScreen ──► Firebase Auth (Google)
   │
   ▼
HomeScreen
   ├── ApiService.fetchGames()       ──► RAWG API
   ├── Filtros (gênero, plataforma, tag, ordenação)
   └── Paginação (20 jogos/página)
   │
   ▼
GameDetailsScreen
   ├── ApiService.fetchGameDetails()     ──► RAWG API
   ├── ApiService.fetchGameScreenshots() ──► RAWG API
   ├── ApiService.fetchGameStores()      ──► RAWG API
   ├── ApiService.fetchGameVideos()      ──► RAWG API
   ├── ApiService.fetchGameDLCs()        ──► RAWG API
   ├── ApiService.fetchSteamPrice()      ──► Steam Store API
   ├── ApiService.fetchHLTB()            ──► HowLongToBeat API
   ├── TranslationService.translate()    ──► MyMemory API
   └── FirebaseService (wishlist)        ──► Cloud Firestore
```

---

## 🛠️ Tecnologias Utilizadas

| Tecnologia | Uso |
|---|---|
| **Flutter 3.x** | Framework principal |
| **Dart 3.x** | Linguagem de programação |
| **RAWG.io API** | Dados de jogos (catálogo, screenshots, lojas) |
| **Firebase Auth** | Autenticação com Google |
| **Cloud Firestore** | Banco de dados da wishlist |
| **Steam Store API** | Preços em tempo real |
| **HowLongToBeat API** | Tempo estimado de conclusão |
| **MyMemory API** | Tradução automática PT-BR |
| **cached_network_image** | Cache de imagens |
| **video_player** | Reprodução de trailers |
| **url_launcher** | Abertura de links externos |

---

## 📦 Instalação e Execução

### Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x instalado
- Android Studio ou VS Code com extensão Flutter
- Dispositivo Android físico ou emulador configurado
- Conta no [RAWG.io](https://rawg.io/apidocs) para obter uma API Key gratuita
- Projeto configurado no [Firebase Console](https://console.firebase.google.com)

### 1. Clone o repositório

```bash
git clone https://github.com/OOCoelho/game_vault.git
cd game_vault
```

### 2. Instale as dependências

```bash
flutter pub get
```

### 3. Configure a API Key do RAWG

Abra o arquivo `lib/services/api_service.dart` e substitua:

```dart
static const String _apiKey = 'SUA_CHAVE_AQUI';
```

pela sua chave obtida gratuitamente em [rawg.io/apidocs](https://rawg.io/apidocs).

### 4. Configure o Firebase

Instale o FlutterFire CLI (apenas uma vez):

```bash
dart pub global activate flutterfire_cli
```

Dentro da pasta do projeto, execute:

```bash
flutterfire configure
```

Selecione seu projeto Firebase quando solicitado. Isso gera automaticamente o arquivo `lib/firebase_options.dart`.

### 5. Execute o projeto

Com um dispositivo conectado ou emulador rodando:

```bash
flutter run
```

---

## 📋 Dependências

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.1
  url_launcher: ^6.2.5
  video_player: ^2.8.3
  cached_network_image: ^3.3.1
  firebase_core: ^3.1.0
  firebase_auth: ^5.1.0
  cloud_firestore: ^5.1.0
  google_sign_in: ^6.2.1

- Dados de jogos fornecidos por **[RAWG.io](https://rawg.io)**
- Tempo de conclusão por **[HowLongToBeat](https://howlongtobeat.com)**
- Preços por **[Steam Store](https://store.steampowered.com)**
- Tradução por **[MyMemory](https://mymemory.translated.net)**
