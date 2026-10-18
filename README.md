# Glimmer Grove

A luminous match-3 for phones and tablets. Swap neighboring fruits, crack the frost, and spend leftover moves as bursts of light. Four in a line become a stripe, five become a sunburst, and a corner match folds into a bloom bomb.

The app is Flutter. Android and iOS projects live in `android/` and `ios/`. Progress, coins, and boosters stay on the device.

## Play

```bash
flutter pub get
flutter run
```

Build an Android package:

```bash
flutter build apk
```

The APK is written to `build/app/outputs/flutter-apk/`.

## Checks

```bash
flutter test
```

## Language

The grove follows the device language and can be switched between English and Español in Settings.

## Fonts

Fredoka and Nunito are included under the SIL Open Font License. See `assets/fonts/`.
