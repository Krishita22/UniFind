  ## Running the code

  Run `npm i` to install the dependencies.

  Run `npm run dev` to start the development server.
  
## Running with Flutter

- **Prerequisites:** Install Flutter (https://flutter.dev), Node.js and npm.

- **Recommended (local dev preview):**
  - From the project root, install web dependencies:

    ```bash
    npm install
    ```

  - Start the web dev server (Vite serves at `http://localhost:5173`):

    ```bash
    npm run dev
    ```

  - In a separate terminal, fetch Flutter dependencies and run the app:

    ```bash
    cd unifind_flutter
    # Marketplace app with lost and found

    This repository contains a React + Vite web app and a small Flutter shell that embeds the web app via a WebView.

    Original design: https://www.figma.com/design/Gdo5hyLjM5bFsXeGyiiLF5/Marketplace-app-with-lost-and-found

    ## Running the code

    Run `npm install` to install the dependencies and `npm run dev` to start the development server:

    ```bash
    npm install
    npm run dev
    ```

    Open http://localhost:5173 in your browser to view the web app.

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

    ## Commit the README change

    To stage and commit this README update locally:

    ```bash
    git add README.md
    git commit -m "docs: add Flutter run instructions and clean up README"
    git push
    ```

    If you want, I can create a branch and open a PR for you.
