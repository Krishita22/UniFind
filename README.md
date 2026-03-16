# UniFind

Ryisha Heusner, Stephania Ivanov, Sumaya Rahman, Nick Seminerio, Krishita Vaghani

Marketplace app with lost and found — CSIT 415 Project.

This repository contains:
- a native Flutter app (`unifind_flutter/`)
- a PHP backend (`unifind_backend/`)

## Run Locally

1. Clone and enter the repo:

```bash
git clone https://github.com/ivanovs1/UniFind.git
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
- `flutter run -d ios` (open iOS Simulator first)

### Flutter code layout

The Flutter UI was split out of one large file to make it easier to read and maintain.

- `unifind_flutter/lib/main.dart` → app bootstrap, theme, and root app state
- `unifind_flutter/lib/src/landing_page.dart` → landing page
- `unifind_flutter/lib/src/auth_screens.dart` → login/register/forgot password
- `unifind_flutter/lib/src/marketplace_screen.dart` → marketplace feed
- `unifind_flutter/lib/src/lost_found_screen.dart` → lost & found feed
- `unifind_flutter/lib/src/post_listing_screen.dart` → post listing form
- `unifind_flutter/lib/src/my_listings_screen.dart` → user listings
- `unifind_flutter/lib/src/documentation_screen.dart` → in-app docs
- `unifind_flutter/lib/src/item_detail_screen.dart` → listing details
- `unifind_flutter/lib/src/ui_controls.dart` → shared form/filter controls
- `unifind_flutter/lib/src/ui_feedback.dart` → buttons/empty-state/feedback widgets
- `unifind_flutter/lib/src/data.dart` → models, enums, and categories



