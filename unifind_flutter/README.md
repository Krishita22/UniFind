# UniFind Flutter shell

This minimal Flutter project loads the existing Vite/React UniFind app inside a WebView for quick testing on mobile.

Quick steps

1) Build and preview your web app from the repo root:

```bash
npm run build
npm run preview
```

Preview serves the production files (default port `5173`).

2) Run the Flutter app

```bash
cd unifind_flutter
flutter pub get
flutter run -d <device>
```

Notes
- Android emulator: use `http://10.0.2.2:5173` (already configured in `lib/main.dart`).
- iOS simulator: `http://localhost:5173` works.
- Physical devices: use your machine IP (e.g. `http://192.168.1.5:5173`) and ensure both are on the same network.
- Android: ensure `android/app/src/main/AndroidManifest.xml` contains `<uses-permission android:name="android.permission.INTERNET"/>`.
- iOS: if loading non-HTTPS, add App Transport Security exceptions in `ios/Runner/Info.plist`.

If you want the web build bundled inside the Flutter app (offline), I can add the steps to copy the `dist` output into the Flutter `assets/` and load it from local files.
