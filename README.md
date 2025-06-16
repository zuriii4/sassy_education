# 🎓 Sassy - Interaktívna vzdelávacia platforma

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org/)
[![MongoDB](https://img.shields.io/badge/MongoDB-4EA94B?style=for-the-badge&logo=mongodb&logoColor=white)](https://mongodb.com/)
[![TypeScript](https://img.shields.io/badge/TypeScript-007ACC?style=for-the-badge&logo=typescript&logoColor=white)](https://typescriptlang.org/)

## 📋 Abstrakt

**Sassy** je inovatívna multiplatformová aplikácia navrhnutá na podporu učiteľov pri tvorbe personalizovaných interaktívnych vzdelávacích materiálov pre deti s mentálnym postihnutím a špeciálnymi potrebami. Aplikácia kombinuje jednoduchosť používania s pokročilými funkciami na sledovanie pokroku a správu vzdelávacieho obsahu.

### ✨ Kľúčové vlastnosti
- 🎮 **4 typy interaktívnych aktivít**: Kvízy, hlavolamy, prešmyčky a spájanie
- 👥 **Správa študentov a skupín**: Organizácia žiakov a prideľovanie úloh
- 📊 **Real-time sledovanie pokroku**: Detailné štatistiky a analytics
- 🔄 **Multiplatformová podpora**: Web, iOS, Android, Windows, macOS, Linux
- 🎨 **Prispôsobiteľné rozhranie**: Dizajn optimalizovaný pre špeciálne potreby
- 📱 **Real-time notifikácie**: Okamžité upozornenia cez WebSocket

---

## 🏗️ Architektúra systému

```
┌─────────────────┐    API/REST    ┌──────────────────┐
│   Flutter App   │ ◄────────────► │   Express.js     │
│   (Frontend)    │                │   (Backend)      │
└─────────────────┘                └──────────────────┘
                                            │
                                            ▼
                                   ┌──────────────────┐
                                   │    MongoDB       │
                                   │   (Database)     │
                                   └──────────────────┘
```

### 🛠️ Technologický stack

**Frontend (Klient)**
- **Flutter** (Dart) - Multiplatformový framework
- **Socket.IO Client** - Real-time komunikácia
- **HTTP** - REST API komunikácia

**Backend (Server)**
- **Node.js + Express.js** - Server framework
- **TypeScript** - Typovaný JavaScript
- **Socket.IO** - WebSocket server
- **Multer** - File upload handling

**Databáza**
- **MongoDB** - NoSQL databáza
- **Mongoose** - ODM pre MongoDB

**Autentifikácia**
- **JWT** (JSON Web Tokens)
- **Bcrypt** - Hash hesiel

---

## 📋 Systémové požiadavky

### 🖥️ Server
- **Node.js**: v14.0.0 alebo vyššia
- **MongoDB**: v4.4 alebo vyššia
- **Disk space**: Minimálne 500 MB + priestor pre používateľské súbory
- **RAM**: Minimálne 1 GB

### 📱 Klient
- **Flutter SDK**: v2.10.0 alebo vyššia
- **Disk space**: 150 MB na mobilných zariadeniach
- **Podporované platformy**:
  - 📱 iOS 10.0+
  - 🤖 Android API 21+
  - 🌐 Moderné webové prehliadače
  - 💻 Windows 10+
  - 🍎 macOS 10.14+
  - 🐧 Linux (Ubuntu 18.04+)

---

## 🚀 Inštalácia a nastavenie

### 1️⃣ Príprava databázy

#### Možnosť A: Lokálna MongoDB
```bash
# Ubuntu/Debian
sudo apt-get install mongodb

# macOS
brew install mongodb-community

# Windows
# Stiahnite z https://www.mongodb.com/try/download/community
```

#### Možnosť B: MongoDB Atlas (Cloud)
1. Vytvorte účet na [MongoDB Atlas](https://cloud.mongodb.com/)
2. Vytvorte nový cluster
3. Získajte connection string

### 2️⃣ Inštalácia serverovej časti

```bash
# Klonujte repository
git clone [repo-url]
cd [name]

# Prejdite do server priečinka
cd express_app_sassy

# Nainštalujte závislosti
npm install

# Vytvorte .env súbor
touch .env
```

**Konfigurácia `.env` súboru:**
```env
PORT=3000
MONGO_URI=mongodb://localhost:27017/edumate
# alebo pre MongoDB Atlas:
# MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/edumate

JWT_SECRET=your-super-secret-jwt-key-here
```

```bash
# Skompilujte TypeScript
npm run build

# Spustite server
npm start
```

✅ **Server by mal bežať na:** `http://localhost:3000`

### 3️⃣ Inštalácia klientskej časti

```bash
# Nainštalujte Flutter SDK
# https://docs.flutter.dev/get-started/install

# Overte inštaláciu
flutter doctor

# Prejdite do client priečinka
cd ../client

# Nainštalujte závislosti
flutter pub get

# Vytvorte .env súbor
touch .env
```

**Konfigurácia `.env` súboru pre klienta:**
```env
API_URL=http://localhost:3000/api
WEB_SOCKET_URL=http://localhost:3000
```

### 4️⃣ Spustenie aplikácie

#### 🌐 Web verzia
```bash
flutter run -d chrome
# alebo
flutter build web --release
```

#### 📱 Mobilné zariadenia
```bash
# Android
flutter build apk --release
flutter install

# iOS (vyžaduje macOS + Xcode)
flutter build ios --release
# Potom otvorte ios/Runner.xcworkspace v Xcode
```

#### 💻 Desktop aplikácie
```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

---

## 👥 Používateľské roly a oprávnenia

### 🔐 Administrátor
- Kompletná správa systému
- Správa učiteľov a študentov
- Systémové nastavenia
- Prístup ku všetkým dátam

### 👨‍🏫 Učiteľ
- Tvorba a správa vzdelávacích materiálov
- Organizácia študentov do skupín
- Prideľovanie úloh
- Sledovanie pokroku študentov
- Správa notifikácií

### 👨‍🎓 Študent
- Prístup k prideleným úlohám
- Riešenie interaktívnych aktivít
- Sledovanie vlastného pokroku
- Príjem notifikácií

---

## 🎮 Typy interaktívnych materiálov

### 🧩 Hlavolamy (Puzzles)
- Skladanie obrázkov z puzzle kusov
- Podpora vlastných obrázkov
- Rôzne úrovne obtiažnosti

### ❓ Kvízy (Quizzes)
- Otázky s viacerými možnosťami
- Správne/nesprávne odpovede
- Automatické vyhodnotenie

### 🔀 Prešmyčky (Shuffles)
- Usporadúvanie prvkov do správneho poradia
- Drag & drop funkcionalita
- Textové aj obrázkové prvky

### 🔗 Spájanie (Matching)
- Párovanie súvisiacich prvkov
- Vizuálne prepojenie čiar
- Podpora text-text, text-obrázok kombinácií

---

## 🔧 Vývoj a prispievanie

### 📁 Štruktúra projektu

```
sassy/
├── express_app_sassy/      # Backend (Node.js + Express)
│   ├── src/
│   │   ├── controllers/    # Business logika
│   │   ├── models/         # MongoDB schémy
│   │   ├── routes/         # API endpointy
│   │   ├── middleware/     # Auth a permissions
│   │   ├── utils/          # WebSocket service
│   │   └── config/         # DB konfigurácia
│   ├── public/uploads/     # Nahrané súbory
│   └── .env               # Environment variables
│
├── flutter_app_sassy/     # Frontend (Flutter)
│   ├── lib/
│   │   ├── screens/       # UI obrazovky
│   │   │   ├── admin/     # Admin rozhranie
│   │   │   ├── teacher/   # Učiteľské rozhranie
│   │   │   └── student/   # Študentské rozhranie
│   │   ├── widgets/       # Znovupoužiteľné komponenty
│   │   ├── models/        # Dátové triedy
│   │   └── services/      # API komunikácia
│   └── .env              # Environment variables
```

### 🛠️ Vývojové príkazy

```bash
# Server development
cd server
npm run dev          # Spustenie s hot reload
npm run build        # Kompilácia TypeScript
npm run test         # Spustenie testov

# Client development
cd client
flutter run          # Debug režim
flutter test         # Spustenie testov
flutter analyze      # Analýza kódu
flutter format .     # Formátovanie kódu
```

### 📊 API dokumentácia

**Autentifikácia endpointy:**
```
POST /api/auth/login              # Prihlásenie
POST /api/auth/student/login      # Študentské prihlásenie
POST /api/auth/student/login/colorcode  # Prihlásenie farebným kódom
```

**Chránené endpointy:**
```
GET    /api/users                 # Zoznam používateľov
POST   /api/materials             # Vytvorenie materiálu
PUT    /api/materials/:id         # Aktualizácia materiálu
DELETE /api/materials/:id         # Vymazanie materiálu
GET    /api/groups                # Správa skupín
POST   /api/notifications         # Notifikácie
```

### 🔌 WebSocket udalosti

```javascript
// Klient -> Server
authenticate         // Autentifikácia
join_room            // Pripojenie do miestnosti

// Server -> Klient
material_assigned    // Nový materiál pridelený
material_completed   // Materiál dokončený
user_status_changed  // Zmena online statusu
notification_new     # Nová notifikácia
```

### 🎨 Pridanie nového typu materiálu

1. **Server-side:**
   ```typescript
   // models/material.ts - rozšírte schému
   // controllers/materialController.ts - pridajte validáciu
   // types/materialTypes.ts - definujte typ
   ```

2. **Client-side:**
   ```dart
   // lib/models/ - vytvorte model
   // lib/screens/teacher/ - editor obrazovka
   // lib/screens/student/ - riešenie obrazovka
   // lib/services/api_service.dart - API komunikácia
   ```

---

## 🚢 Deployment

### 🐳 Docker deployment
```dockerfile
# Dockerfile pre server
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
```

### ☁️ Cloud deployment
- **Backend**: Heroku, Vercel, DigitalOcean
- **Databáza**: MongoDB Atlas, AWS DocumentDB
- **Frontend**: Firebase Hosting, Netlify, Vercel

### 📱 Mobilná distribúcia
- **iOS**: App Store Connect
- **Android**: Google Play Console

---

## 🔧 Troubleshooting

### ❌ Časté problémy

**Server sa nespustí:**
```bash
# Skontrolujte MongoDB pripojenie
mongosh
# Skontrolujte .env súbor
cat .env
# Skontrolujte port konflikty
lsof -i :3000
```

**Flutter build chyby:**
```bash
# Vyčistite cache
flutter clean
flutter pub get

# Skontrolujte Flutter doctor
flutter doctor -v
```

**WebSocket pripojenie zlyhá:**
```dart
// Skontrolujte URL v .env
// Overte firewall nastavenia
// Skontrolujte CORS nastavenia na serveri
```

---

## 🤝 Prispievanie

1. Forkujte repository
2. Vytvorte feature branch (`git checkout -b feature/AmazingFeature`)
3. Commitnite zmeny (`git commit -m 'Add some AmazingFeature'`)
4. Pushnite do branch (`git push origin feature/AmazingFeature`)
5. Otvorte Pull Request

### 📋 Coding standards
- Používajte TypeScript pre backend
- Dodržujte Dart/Flutter conventions
- Píšte testy pre nové funkcie
- Dokumentujte API endpointy

---

## 📞 Podpora a kontakt

- 📧 **Email**: [zuri4@duck.com]
- 🐛 **Bug reports**: [GitHub Issues](https://github.com/zuri/sassy_education/issues)
- 💬 **Diskusie**: [GitHub Discussions](https://github.com/zuri/sassy_education/discussions)
- 📖 **Dokumentácia**: [Wiki](https://github.com/zuri/sassy_education/wiki)

---

## 🙏 Poďakovanie

Špeciálne poďakovanie patrí:
- Flutter komunite za vynikajúci framework
- MongoDB tímu za robustnú databázu
- Express.js komunite za server framework
- Všetkým prispievateľom a testerom

---

<div align="center">

**Sassy** - *Podporujeme inkluzívne vzdelávanie pomocou technológií* 🎓

[⬆ Späť na začiatok](#-edumate---interaktívna-vzdelávacia-platforma)

</div>
