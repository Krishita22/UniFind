 # UniFind

Marketplace app with lost and found — CSIT 415 Project

This repository contains a React + Vite web app and a small Flutter shell that embeds the web app via a WebView.

## Running the web app

Install dependencies and start the Vite dev server:

```bash
npm install
npm run dev
```

Open `http://localhost:5173` in your browser to view the web app.

## Running with Flutter

- **Prerequisites:** Install Flutter (https://flutter.dev), Node.js and npm.

- **Local dev preview:**
  1. From the project root, install web dependencies and start the dev server:

     ```bash
     npm install
     npm run dev
     ```

  2. In a separate terminal, run the Flutter shell:

     ```bash
     cd unifind_flutter
     flutter pub get
     flutter run
     ```

  - The Flutter app loads `http://localhost:5173` by default. On Android emulators it uses `http://10.0.2.2:5173`.
  - To point the Flutter app at a different (deployed) URL:

     ```bash
     flutter run --dart-define=PREVIEW_URL=https://your-deployed-url/
     ```

- **Production:** build and deploy the web app (`npm run build`) and set `PREVIEW_URL` to the deployed URL or host it where the WebView can reach it.

---

Last updated: 2026-02-18
