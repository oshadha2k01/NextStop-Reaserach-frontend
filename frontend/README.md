# Smart Bus System - Flutter Mobile Application

## 📌 Project Overview

This repository contains the **Flutter mobile application** for the Smart Bus System. The app provides real-time bus tracking, occupancy monitoring, and accessible journey planning for passengers.

Developed as part of IT4010 Research Project – 2025 (July Intake).

---

## 🖥️ Application Architecture

```
+----------------------------------------------------------+
|              Flutter Mobile Application                   |
+----------------------------------------------------------+
|                                                           |
|  +-----------------+        +---------------------------+ |
|  | Presentation    |        | State Management          | |
|  | (UI/Screens)    |   ←→   | (Provider)                | |
|  +-----------------+        +---------------------------+ |
|           |                              |                |
|  +-------------------------------------------------+     |
|  | Data Layer (API/WebSocket/Local Storage)        |     |
|  +-------------------------------------------------+     |
|                          |                                |
+--------------------------|--------------------------------+
                           ↓
              +------------------------+
              |   Backend Services     |
              +------------------------+
```

---

## 🛠️ Technology Stack

- **Framework:** Flutter 3.x
- **Language:** Dart 3.x
- **State Management:** Provider
- **Maps:** Google Maps Flutter
- **Real-time:** WebSocket, Firebase Messaging
- **Storage:** Hive, Shared Preferences
- **HTTP Client:** Dio
- **Localization:** Flutter Localizations (English, Sinhala, Tamil)
- **Accessibility:** Flutter TTS, Speech to Text

---

## 🧩 Key Features

### Real-Time Bus Tracking
- Live bus location on Google Maps
- ETA countdown timer
- Route visualization with polylines

### Occupancy Monitoring
- Real-time seat availability display
- Color-coded crowding indicators
- Occupancy alerts

### Accessibility
- Screen reader support
- Voice commands
- Audio announcements
- High contrast mode
- Multi-language support (English, Sinhala, Tamil)

### Journey Planning
- Route search with autocomplete
- Fare estimation
- Alternative route suggestions
- Favorite routes management

### User Feedback
- Driver ratings
- Complaint submission
- Real-time notifications

---

## 📱 Main Screens

1. **Splash & Onboarding**
2. **Login/Register**
3. **Home** - Map with nearby buses
4. **Search** - Route planning
5. **Live Tracking** - Real-time bus tracking
6. **Favorites** - Saved routes and stops
7. **Profile & Settings** - User preferences

---

* Real-time passenger counting using cctv cameras for both exit and entrance doors. 
* Embedded deep learning models (Yolo12) for human detecting.
* Privacy-preserving anonymous detection

### Prerequisites
```bash
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / VS Code
- Git
```

* Realtime calculation share with mobile and desktop users.
* No GPU dependency – optimized for embedded systems

```bash
# Clone repository
git clone <repository-url>
cd frontend

# Install dependencies
flutter pub get

# Run app
flutter run
```

### Environment Setup

Create `.env` file:
```env
API_BASE_URL=your_api_url
GOOGLE_MAPS_API_KEY=your_maps_key
```

---

## 📂 Project Structure

```
lib/
├── main.dart
├── core/
│   ├── constants/
│   ├── theme/
│   └── network/
├── features/
│   ├── authentication/
│   ├── home/
│   ├── tracking/
│   └── profile/
├── shared/
│   ├── widgets/
│   └── services/
└── l10n/
```

---

## 🧪 Testing

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

---

## 📦 Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## 👥 Team

| Name                  | ID         | Role                    |
| --------------------- | ---------- | ----------------------- |
| Weerakoon W.M.D.P     | IT22131560 | IoT & ETA Prediction    |
| Pathiraja H.P.M.O.N   | IT22230492 | Fleet Management        |
| Chandrasekara C.M.P.V | IT22286246 | Mobile App Development  |
| Abeysekara W.R.G.M    | IT22271150 | Passenger Counting      |

---

## 📞 Support

- **Issue Tracker:** GitHub Issues
- **Documentation:** Project Wiki

---

📄 IT4010 Research Project – 2025