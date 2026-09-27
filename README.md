# MedTrack Pro — Smart WebView Android App

A production-ready Flutter Smart WebView Android application configured for [https://gigantic-med-track-pro.base44.app](https://gigantic-med-track-pro.base44.app).

---

## 🚀 Features Implemented

1. **`webview_flutter` & Android Configuration**:
   - Modern `webview_flutter: ^4.10.0` with Android platform integration (`webview_flutter_android`).
   - Configured `AndroidManifest.xml` with:
     - `android.permission.INTERNET`
     - `android.permission.ACCESS_NETWORK_STATE`
     - Hardware acceleration enabled (`android:hardwareAccelerated="true"`) for smooth 60/120fps scrolling.
     - `android:usesCleartextTraffic="true"` and intent queries for web links (`tel:`, `mailto:`, `https:`).

2. **Pull-to-Refresh Functionality**:
   - Injected passive JavaScript touch gestures detecting user swipe down at the top of the webpage (`scrollY <= 0`).
   - Flutter `RefreshIndicator` wrapper and Top App Bar quick-refresh button with state animation.
   - Offline screen also features native pull-to-refresh to retry connections.

3. **Android Back Button History Navigation**:
   - Utilizes `PopScope` to intercept physical and gesture back actions on Android.
   - Evaluates `await _controller.canGoBack()`:
     - If history exists, navigates backward (`_controller.goBack()`).
     - If at the root of web history, alerts user with a snackbar (*"Press back again to exit MedTrack Pro"*) to prevent accidental closure.

4. **Loading Indicators**:
   - **Top Linear Progress Bar**: Live progress tracking (0% to 100%) across the top edge.
   - **Centered Loading Spinner Overlay**: Clean translucent card with circular spinner and *"Connecting to MedTrack Pro..."* during page initiation and network reconnects.

5. **Clean Offline Error Screen**:
   - Live network listener via `connectivity_plus` combined with DNS socket verification (`InternetAddress.lookup`).
   - Displays modern medical-themed offline UI with:
     - Clear offline status icon and messaging.
     - Target domain badge (`gigantic-med-track-pro.base44.app`).
     - Interactive **"Try Again"** button with loading feedback.
     - Pull-to-refresh support directly on the offline screen.
     - **Auto-reconnect**: Automatically detects when network connectivity returns and reloads the web application seamlessly.

---

## 📁 Project Structure

```
med track/
├── pubspec.yaml                          # Dependencies (webview_flutter, connectivity_plus)
├── .gitignore                            # Standard Flutter & Android gitignore
├── README.md                             # Project documentation
├── android/
│   ├── build.gradle                      # Root Gradle configuration
│   ├── settings.gradle                   # Plugin loader & Gradle settings
│   ├── gradle.properties                 # JVM arguments & AndroidX flags
│   └── app/
│       ├── build.gradle                  # App build setup (minSdk 21, compileSdk 34)
│       └── src/main/
│           ├── AndroidManifest.xml       # Internet permissions & hardware acceleration
│           ├── kotlin/com/medtrack/app/
│           │   └── MainActivity.kt       # Android FlutterActivity
│           └── res/
│               ├── drawable/launch_background.xml
│               └── values/styles.xml
└── lib/
    ├── main.dart                         # App entrypoint & Material 3 theme
    ├── constants/
    │   └── app_constants.dart            # Target URL, JS scripts, & theme colors
    ├── services/
    │   └── connectivity_service.dart     # Socket & interface connectivity manager
    ├── widgets/
    │   ├── loading_indicator.dart        # Linear progress bar & overlay spinner
    │   └── offline_screen.dart           # Offline UI with retry & pull-to-refresh
    └── screens/
        └── webview_screen.dart           # Smart WebView controller & navigation
```

---

## 🛠️ How to Run & Build

### Prerequisites
- Flutter SDK (>= 3.10.0)
- Android SDK & Java 17 / JDK 11

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run on Connected Android Device or Emulator
```bash
flutter run
```

### 3. Build Production APK
```bash
flutter build apk --release
```
The generated APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`
