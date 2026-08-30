# Finora — Flutter

A full Flutter (Dart) port of the native Android (Kotlin/Jetpack Compose) Finora app.
Same glassmorphism navy design, same Firebase backend (Auth + Cloud Firestore + Storage),
same data model — so it reads/writes the **same user data** as the native app.

> This `lib/` + `pubspec.yaml` is the complete Dart codebase. Because a Flutter SDK was not
> available on the build machine, it was authored without a compiler. Run `flutter analyze`
> after setup and fix any minor issues it reports (a normal first-run step for a fresh port).

## Project layout
```
lib/
  main.dart                 app entry, providers, theme, AuthGate
  core/
    theme/                  app_theme.dart (glass palette/typography), glass_background.dart
    utils/                  formatters.dart, date_filter.dart
    widgets/                glass_widgets.dart (GlassCard, PrimaryButton, SegmentedControl, …)
  data/
    models/                 transaction, wallet, category, finance_models, coerce
    services/               auth/transaction/wallet/finance repositories (Firestore)
  state/                    ChangeNotifier "ViewModels" (auth, dashboard, transaction, wallet, budget, more, theme)
  features/                 one folder per screen (auth, main, dashboard, transaction, wallet,
                            report, more, budget, goal, asset, loan, category, notification, settings, profile)
PORTING_NOTES.md            internal API reference (widgets/providers/models)
```

## Architecture mapping (Kotlin → Flutter)
| Native (Kotlin) | Flutter |
| --- | --- |
| Jetpack Compose | Flutter widgets |
| Hilt + ViewModel + StateFlow | `provider` + `ChangeNotifier` |
| Repository + Firestore KTX | repository classes + `cloud_firestore` |
| Vico charts | `fl_chart` |
| `FinoraColors`/glass theme | `app_theme.dart` + `glass_widgets.dart` |
| `MainActivity`/Nav | `main.dart` + `AuthGate` + `MainScreen` |

Firestore paths are identical: `users/{uid}/{wallets|transactions|assets|loans|goals|budgets|notifications|categories|settings}`.
Wallet balances are derived on the fly via `WalletRepository.computeWalletsWithBalances` (ported 1:1),
and deleting a transaction reverses its linked asset/loan/goal exactly like the native app.

## Setup & run
1. **Install Flutter** (stable channel): https://docs.flutter.dev/get-started/install — then `flutter doctor`.
2. **Generate the platform folders** (this repo only ships `lib/` + `pubspec.yaml`):
   ```bash
   cd flutter-app
   flutter create --org com.finora --project-name finora .
   ```
   (This adds `android/`, `ios/`, etc. and keeps the existing `lib/` and `pubspec.yaml`.)
3. **Connect Firebase** (use the SAME project as the native app — `gen-lang-client-0843862000`). Easiest:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This adds the Android `google-services.json` / iOS `GoogleService-Info.plist` so
   `Firebase.initializeApp()` in `main.dart` works on both platforms.
   - For Google Sign-In on Android, add the app's SHA-1/SHA-256 fingerprints in the Firebase console
     (same as the native app), and ensure the OAuth client exists.
4. **Get packages & run:**
   ```bash
   flutter pub get
   flutter analyze        # fix any minor issues from the blind port
   flutter run            # or: flutter build apk
   ```

## Notes
- Default theme is **dark (navy glass)**; the Light/Dark/System toggle lives in Settings (persisted via `shared_preferences`).
- The bottom navigation has 4 tabs (Tổng quan, Giao dịch, Báo cáo, Thêm) + a raised glowing center "+"
  that opens the add-transaction form. "Ví & Thẻ" and the other detail screens are pushed routes
  (reachable from **Thêm** and the Dashboard quick actions).
- All business logic, Firestore structure, and Vietnamese copy match the native app — only the UI framework changed.
