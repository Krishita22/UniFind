# UniFind Flutter (Native)

This Flutter project is a native Dart implementation of UniFind's core flows:
- Marketplace browsing + item details
- Lost & Found feed
- Post listing form (For Sale / Lost / Found)
- My Listings view
- Docs page

## Prerequisites

- Flutter SDK installed (`flutter --version`)
- Android Studio or Xcode (for mobile simulators/devices)

## Run the app

```bash
cd unifind_flutter
flutter pub get
flutter run
```

## Run on a specific target

List available devices:

```bash
flutter devices
```

Run on device id:

```bash
flutter run -d <device_id>
```

Examples:
- Android emulator: `flutter run -d emulator-5554`
- iOS simulator: `flutter run -d ios`
- Chrome (web): `flutter run -d chrome`

## Notes

- The app uses in-memory mock data from Dart models in `lib/main.dart`.
- Posted items appear immediately in the app state and in `My Listings`.
