# FINORA rebuild audit — working evidence register

Status: IN PROGRESS. This is an initial source audit, not a claim of complete
feature parity or completed UI migration. Latest pasted specification overrides
the earlier V3 image-derived palette. No feature screen has been migrated in
this audit pass.

## Architecture inventory

- Entrypoint: lib/main.dart, Firebase initialization, MultiProvider, ThemeController,
  WidgetStyleController, SplashScreen and AuthGate.
- Navigation: features/main/main_screen.dart IndexedStack plus imperative
  MaterialPageRoute pushes; current shell is bottom-only with four destinations
  and a separate create-transaction action.
- State/DI: ChangeNotifier providers instantiated in main; repositories directly
  constructed in providers. Dashboard combines six subscriptions and recomputes
  after each emission. Transaction provider independently watches transactions,
  wallets and categories. Metadata/offline state is not consistently exposed.
- Network: Firestore repositories plus dart:io AI service. Scope resolver chooses
  users or families. Named database ID is hard-coded in multiple repositories;
  web reads firestoreDatabaseId from firebase-applet-config.json.
- Auth: FirebaseAuth and GoogleSignIn in auth_repository.dart; SDK owns auth
  credentials/token refresh. Profile synchronization writes users/{uid}.
- DTOs: transaction.dart, wallet.dart, category.dart, finance_models.dart,
  family_models.dart; coerce.dart handles Firestore value conversion.
- Persistence: SharedPreferences theme/widget style; Firestore repositories for
  financial records and settings. Transaction stream maintains a local map keyed
  by document ID. Cache metadata and pending-write feedback need explicit audit.
- Error handling: repository exceptions, provider error strings, error_boundary,
  plus startup/error widget handlers in main. Some success emissions clear errors
  while other subscriptions may still be unavailable.

## Feature discovery

Existing Flutter feature folders: auth, splash, onboarding, main, dashboard,
transaction (entry/history/detail screen/detail sheet), wallet (list and entry),
budget, report, category, goal, loan, asset, profile, settings, notification, more,
family, ai. Additional workflows include bank selection, member filtering, custom
periods, category management, investment subtypes, savings goals and debt payments.

Web adds explicit settings panels for trash and activity logs, AI scan/copilot,
investment forms for quantified assets, savings and hui/phuong, command palette,
theme/privacy preferences and synchronization status. These must not disappear
from the parity inventory merely because the original expected module list omitted them.

## Initial parity matrix

Paths below are relative to the repository root (Flutter entries start flutter-app/).
NEEDS MIGRATION means comparison/verification is outstanding, not that behavior
has been proven equal.

| Feature | Web evidence | Flutter evidence | API / contract | Status |
|---|---|---|---|---|
| Personal/family collection paths | src/lib/firebase.ts getActiveBasePath | data/services/scope_resolver.dart | users/{uid}, families/{familyId} | API DIFFERENT — corrected, verification pending |
| Authentication/profile | src/pages/Login.tsx, Signup.tsx, services/settingsService.ts | data/services/auth_repository.dart | FirebaseAuth, users profile | NEEDS MIGRATION |
| Dashboard totals/health | src/pages/Dashboard.tsx, lib/financeCalculations.ts | state/dashboard_provider.dart | local aggregation; hard-coded health fallback amounts in Flutter | MOBILE DIFFERENT |
| Transactions CRUD | src/components/dashboard/AddTransactionModal.tsx, services/transactionService.ts | data/services/transaction_repository.dart | transaction fields, mutation side effects | MOBILE DIFFERENT |
| Investment delete cascade | src/services/transactionService.ts | data/services/transaction_repository.dart | asset quantity, unit price, subtype | MOBILE DIFFERENT |
| Wallets/credit cards | src/lib/moneyLedger.ts, lib/balance-utils.ts | data/services/wallet_repository.dart | initial balance, debt, wallet effects | NEEDS MIGRATION |
| Budgets/recurrence | src/services/budgetService.ts | data/services/finance_repository.dart BudgetRepository | monthKey, recurrence, archival, notifications | NEEDS MIGRATION |
| Reports | src/pages/reports/index.tsx | features/report/report_screen.dart | canonical classification and period calculations | NEEDS MIGRATION |
| Goals/deposits | src/pages/goals/index.tsx | GoalRepository, features/goal | savedAmount and linked transactions | NEEDS MIGRATION |
| Loans/repayments | src/pages/loans/index.tsx | LoanRepository, features/loan | principal, remaining, repayment side effects | NEEDS MIGRATION |
| Assets/subtypes | src/types/investment.ts, components/investments/forms | features/asset, finance_models.dart | quantified, savings, hui/phuong fields | NEEDS MIGRATION |
| Categories | src/pages/categories, components/categories | CategoryRepository, features/category | IDs, type, grouping, icon names | NEEDS MIGRATION |
| Settings/profile | src/services/settingsService.ts | SettingsRepository, features/settings, profile | personal settings/app and profile documents | NEEDS MIGRATION |
| Notifications | src/pages/notifications, NotificationManager.tsx | NotificationRepository, features/notification | read/delete/generation | NEEDS MIGRATION |
| Family/permissions | src/services/familyService.ts, types/family.ts | family_repository.dart, family_provider.dart | membership and roles | NEEDS MIGRATION |
| AI/scan | src/pages/ai, services/aiTransactionService.ts | ai_service.dart, finora_nlp_engine.dart | parsing, capture, confirmation | NEEDS MIGRATION |
| Search/filter/sort/pagination | src/pages/transactions, lib/dateFilters.ts | transaction_provider.dart, core/utils/date_filter.dart | periods, owner, query, ordering | NEEDS MIGRATION |
| Global privacy | src/store/useThemeStore.ts privacyMode | state/theme_controller.dart has theme only | shared persisted privacy state | MOBILE DIFFERENT |
| Offline/pending writes | src/store/useDataStore.ts syncStatus | providers use loading/error/refresh flags | snapshot metadata | MOBILE DIFFERENT |
| Trash restoration | src/services/trashService.ts, settings/TrashPanel.tsx | repository soft delete; no matching restoration service discovered | restoreDeletedTransaction and purgeAfter | MOBILE MISSING |
| Activity log | src/services/activityLogService.ts, settings/ActivityLogsPanel.tsx | no corresponding service/panel discovered | activityLogs collection | MOBILE MISSING |
| Design gallery | required by rebuild specification | no /design-system route found | debug-only, no production data | MOBILE MISSING |

## Confirmed discrepancies and required changes

1. Scope resolver returned literal users/ or families/, leaving document ID empty.
   Web includes the UID/family ID. Corrected only the two return values; regression
   test covers two users, family precedence and blank family fallback. No database
   writes or migrations are required for this code correction.
2. Investment reversal on web uses assetQuantity/quantity, unit buy price and
   subtype-specific branches. Flutter increments/decrements quantity by one and
   takes the last transaction amount as current price. Required: audit creation,
   editing and deletion as one contract; port fields and subtype behavior together.
   Affected: transaction model/repository, asset model, add-transaction form/provider.
3. Web exposes trash restore and activity log services. Flutter soft-deletes records
   but no equivalent restore service was discovered. Required: preserve retention
   fields, port restore side effects and expose settings flows with permissions.
4. Web stores privacyMode; Flutter ThemeController only stores theme_mode. Required:
   audit exact web preference path then share privacy across all money components.
5. Web syncStatus distinguishes offline/syncing/error. Flutter listeners discard
   metadata. Required: model cached/stale/pending states and aggregate readiness
   without clearing an unrelated listener error.
6. Earlier V3 uses #3478F6, blue-ice/navy surfaces and 44dp icon buttons, conflicting
   with the latest explicit #2563EB/neutral surfaces/48dp touch targets/56dp inputs.
   Required before UI migration: reconcile V3 foundation and contrast pairs, then
   build gallery and reusable components.

## Remaining gates

- Finish field-by-field validation, enum, permissions and calculation comparison.
- Run baseline analyzer/tests and record existing failures separately.
- Establish full design gallery before migrating application shell.
- Verify each module's specified widths, scales, light/dark, CRUD and stream refresh.
- Delete legacy presentation code only after its consumers have migrated.

## Baseline verification — 2026-09-06

- Targeted scope resolver and V3 gallery tests: 4 passed.
- Targeted analyzer for V3, gallery, main and scope resolver: zero issues.
- Full pre-migration suite after repairing five stale test method signatures:
  113 passed, 2 skipped, 30 failed.
- Confirmed baseline failures include category icon parity (`badge-percent`),
  borrowing/repayment expense classification, seconds-vs-milliseconds dates,
  compact login rendering, and 200% text overflow in legacy wallet/transaction UI.
  These failures remain migration inputs and must not be hidden by weakening tests.
