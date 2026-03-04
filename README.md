# UniFind

Marketplace app with lost and found — CSIT 415 Project.

This repository contains a React + Vite web app and a native Flutter app.

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

### Run web app

```bash
npm install
npm run dev
```

Open `http://localhost:5173`.

Ryisha Heusner, Stephania Ivanov, Sumaya Rahman, Nick Seminerio, Krishita Vaghani

Professor Raina Samuel

CSIT415_03SP26

6 February 2026

## Short Description of Project

UniFind is a web application designed exclusively for the Montclair State University community that combines a campus marketplace with a lost-and-found system. Verified students, faculty, and staff can securely buy and sell items such as textbooks, electronics, and school supplies, while also providing a reliable way to report and recover lost items on campus. By requiring MSU email and ID verification, UniFind creates a trusted, university-only environment that reduces scams, encourages item reuse, and improves communication within the MSU community.

## Milestone I Requirements

### Key Functionalities / Requirements

The project uses an Incremental Process Model, releasing functionality in increments. For Milestone I we will focus on establishing UniFind's core functionality for Montclair State students. The first iteration will implement the essential features described below to support typical user flows (register/login, browse listings, view listings, post a listing).

- Login / Registering
   - Users are prompted to log in when entering the application. New users can register. Only users with a `montclair.edu` email address are allowed to register/login. Registration will validate the email domain and send a verification email via the API; non-MSU addresses are rejected.

- Authentication with API
   - All users must authenticate before accessing UniFind. Registration requires a valid Montclair State email and verification via a sent email. Passwords are stored as hashes in the database; during login the entered password is hashed and compared to the stored hash. Successful registration and login redirect users to the landing page displaying marketplace listings.

- Browsing
   - After login, the landing page displays all available listings stored in the database. Listings include name, description, price, category, and an image.

- Posting an Item / Listing
   - Verified users can create and post listings with required fields: name, description, price, category, and an image. Listings missing required information are rejected with appropriate feedback.

### What Will Be Accomplished By Milestone I

By Milestone I, the team aims to deliver a working marketplace backed by a database containing users and listings. The milestone includes a functioning registration and login system, a landing page to browse listings, and the ability for verified users to create listings. These components will provide a foundation for future increments.

### Test Cases

Milestone I test cases will validate:

- Registration and authentication using a valid `montclair.edu` email (non-MSU emails rejected).
- Passwords are stored only when registration succeeds and stored as secure hashes.
- Verification emails are sent and login succeeds/fails correctly based on credentials.
- Only verified users can view approved listings on the landing page; all approved listings appear as expected.
- Verified users can create listings when all required fields are provided; incomplete listings are rejected with clear feedback.
