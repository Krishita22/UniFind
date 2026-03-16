# UniFind

Ryisha Heusner, Stephania Ivanov, Sumaya Rahman, Nick Seminerio, Krishita Vaghani

Marketplace app with lost and found - CSIT 415 Project.

This repository contains:
- a native Flutter app (`unifind_flutter/`)
- a PHP backend (`unifind_backend/`)

## Run Locally

1. Clone and enter the repo:

```bash
git clone https://github.com/Krishita22/UniFind.git
cd UniFind
```

2. Pull latest `main`:

```bash
git checkout main
git pull origin main
```

### Run Flutter app

```bash
cd unifind_flutter
flutter pub get
flutter devices
flutter run -d <device_id>
```

Examples:
- `flutter run -d chrome`
- `flutter run -d macos`
- `flutter run -d ios`

## Repository Structure (Detailed)

### Root
- `README.md`: this file.
- `unifind_flutter/`: Flutter client app.
- `unifind_backend/`: PHP/MySQL backend used by the Flutter app.

---

## `unifind_flutter/` (Client App)

### Project and tooling files
- `unifind_flutter/pubspec.yaml`: Flutter package manifest (dependencies, assets, app metadata).
- `unifind_flutter/pubspec.lock`: locked package versions.
- `unifind_flutter/analysis_options.yaml`: Dart/Flutter lint and analyzer rules.
- `unifind_flutter/.metadata`: Flutter project metadata.
- `unifind_flutter/.gitignore`: Flutter-specific ignore rules.
- `unifind_flutter/README.md`: Flutter module README.

### App source (`lib/`)
- `unifind_flutter/lib/main.dart`: app entry point, theme constants, root app state, and part wiring.
- `unifind_flutter/lib/api_service.dart`: HTTP calls to backend endpoints (`login.php`, `post_listing.php`, etc.).
- `unifind_flutter/lib/api/auth_screens.dart`: auth API constants/helpers.

- `unifind_flutter/lib/src/landing_page.dart`: landing page UI sections and navigation to auth screens.
- `unifind_flutter/lib/src/auth_screens.dart`: login/register/forgot-password UI and auth workflows.
- `unifind_flutter/lib/src/marketplace_screen.dart`: marketplace listing browse/filter UI.
- `unifind_flutter/lib/src/lost_found_screen.dart`: lost-and-found browse/filter UI.
- `unifind_flutter/lib/src/post_listing_screen.dart`: create listing form and image pick/upload flow.
- `unifind_flutter/lib/src/my_listings_screen.dart`: user-owned listings page.
- `unifind_flutter/lib/src/item_detail_screen.dart`: item detail page.
- `unifind_flutter/lib/src/documentation_screen.dart`: in-app docs/help page.
- `unifind_flutter/lib/src/ui_controls.dart`: shared controls (search/chips/buttons).
- `unifind_flutter/lib/src/ui_feedback.dart`: shared empty-state and feedback widgets.
- `unifind_flutter/lib/src/data.dart`: models/enums/date helpers/category lists.

### Assets
- `unifind_flutter/assets/images/logo.jpg`: main logo.
- `unifind_flutter/assets/images/whitelogo.png`: white logo variant for dark headers.

### Tests
- `unifind_flutter/test/widget_test.dart`: widget tests for main UI flows.

### Web runner files
- `unifind_flutter/web/index.html`: Flutter web host page.
- `unifind_flutter/web/manifest.json`: PWA manifest.
- `unifind_flutter/web/favicon.png`: favicon.
- `unifind_flutter/web/icons/Icon-192.png`: web app icon (192).
- `unifind_flutter/web/icons/Icon-512.png`: web app icon (512).
- `unifind_flutter/web/icons/Icon-maskable-192.png`: maskable icon (192).
- `unifind_flutter/web/icons/Icon-maskable-512.png`: maskable icon (512).

### Platform runner folders
- `unifind_flutter/android/`: Android Gradle project, manifests, and runner config.
- `unifind_flutter/ios/`: iOS Xcode project, plist, Podfile, runner sources.
- `unifind_flutter/linux/`: Linux desktop runner and generated plugin registrants.
- `unifind_flutter/macos/`: macOS Xcode runner project and configs.

### Generated/local build folders (not source of truth)
- `unifind_flutter/.dart_tool/`: generated Dart/Flutter tooling cache.
- `unifind_flutter/build/`: generated build artifacts.
- `unifind_flutter/ios/Flutter/ephemeral/`: generated iOS ephemeral files.
- `unifind_flutter/macos/Flutter/ephemeral/`: generated macOS ephemeral files.
- `unifind_flutter/.flutter-plugins-dependencies`: generated plugin dependency map.

---

## `unifind_backend/` (PHP Backend)

### Top-level backend files
- `unifind_backend/.htaccess`: Apache rules for backend routing/security.
- `unifind_backend/.gitignore`: backend-specific ignore rules.
- `unifind_backend/composer.json`: PHP dependency manifest.
- `unifind_backend/schema.sql`: MySQL schema.
- `unifind_backend/index.php`: backend landing/home page for authenticated users.
- `unifind_backend/README.md`: backend-specific setup and scope.
- `unifind_backend/CPANEL_DEPLOYMENT.md`: cPanel deployment instructions.

### Configuration
- `unifind_backend/config/config.example.php`: app/db/mail/security config template.

### Shared includes (`includes/`)
- `unifind_backend/includes/bootstrap.php`: app bootstrap and common setup.
- `unifind_backend/includes/db.php`: database connection logic.
- `unifind_backend/includes/functions.php`: utility functions.
- `unifind_backend/includes/csrf.php`: CSRF helpers.
- `unifind_backend/includes/auth_guard.php`: auth/session access guard.
- `unifind_backend/includes/flash.php`: flash message helpers.
- `unifind_backend/includes/mailer.php`: email sending logic (verification/reset).
- `unifind_backend/includes/header.php`: shared page header template.
- `unifind_backend/includes/footer.php`: shared page footer template.

### Authentication endpoints/pages (`auth/`)
- `unifind_backend/auth/login.php`: user login.
- `unifind_backend/auth/logout.php`: logout/session clear.
- `unifind_backend/auth/register.php`: registration flow.
- `unifind_backend/auth/verify.php`: email verification handler.
- `unifind_backend/auth/resend_verification.php`: resend verification flow.

### Listing pages (`listings/`)
- `unifind_backend/listings/create.php`: create/list item endpoint/page.
- `unifind_backend/listings/view.php`: view listing details.

### Frontend assets
- `unifind_backend/assets/css/style.css`: backend web styling.

### Uploads
- `unifind_backend/uploads/.htaccess`: blocks script execution in uploads.
- `unifind_backend/uploads/listings/index.html`: placeholder/index guard file.

## Notes
- Flutter app is the main client UI.
- Backend folder is the API/auth/listing service layer used by Flutter.
- Generated Flutter folders can be regenerated by running Flutter commands.

## Git Command Guide

### Set your local repo to your new owner remote

```bash
cd <repo>
git remote set-url origin https://github.com/Krishita22/UniFind.git
git fetch --all --prune
git checkout main
git pull origin main
git log --oneline -n 3
```

- `cd <repo>`: go into your local project folder.
- `git remote set-url origin ...`: repoint `origin` to your new GitHub repo URL.
- `git fetch --all --prune`: download latest branches/tags and remove stale remote-tracking refs.
- `git checkout main`: switch to `main` branch.
- `git pull origin main`: fetch + merge latest `origin/main` into local `main`.
- `git log --oneline -n 3`: show last 3 commits in short format.

### Example branch sync flow

```bash
cd /Users/krishitavaghani/Documents/GitHub/UniFind
git switch Steph
git fetch origin
git reset --hard origin/Steph

rm -rf unifind_flutter/.dart_tool
cd unifind_flutter
flutter clean
flutter pub get
flutter run -d chrome

git merge origin/main
git switch -f Steph
```

- `git switch Steph`: switch to branch `Steph`.
- `git fetch origin`: get latest branch state from remote.
- `git reset --hard origin/Steph`: force local `Steph` to exactly match remote `Steph` (discards local uncommitted changes).
- `rm -rf unifind_flutter/.dart_tool`: remove generated Dart tool cache.
- `flutter clean`: clear Flutter build artifacts.
- `flutter pub get`: install Dart/Flutter dependencies from `pubspec.yaml`.
- `flutter run -d chrome`: run Flutter app on Chrome.
- `git merge origin/main`: merge latest remote `main` into current branch.
- `git switch -f Steph`: force switch to `Steph`, discarding conflicting local changes if needed.

### Basic Git commands (everyday use)

```bash
git status
git branch
git switch <branch>
git switch -c <new-branch>
git add .
git add <file>
git commit -m "message"
git pull origin <branch>
git push origin <branch>
git fetch origin
git log --oneline --graph --decorate -n 20
git diff
git diff --staged
git restore <file>
git restore --staged <file>
git stash
git stash pop
```

- `git status`: see changed/untracked files and current branch state.
- `git branch`: list local branches.
- `git switch <branch>`: switch branches.
- `git switch -c <new-branch>`: create and switch to new branch.
- `git add .` / `git add <file>`: stage changes for commit.
- `git commit -m "..."`: create a commit from staged changes.
- `git pull origin <branch>`: update local branch from remote.
- `git push origin <branch>`: upload local commits.
- `git fetch origin`: update remote-tracking references without merging.
- `git log --oneline --graph --decorate -n 20`: compact visual commit history.
- `git diff`: view unstaged changes.
- `git diff --staged`: view staged changes.
- `git restore <file>`: discard unstaged changes in file.
- `git restore --staged <file>`: unstage file while keeping its working changes.
- `git stash`: temporarily save uncommitted changes.
- `git stash pop`: re-apply latest stash and remove it.
