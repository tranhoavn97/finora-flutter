# Finora Flutter — internal API reference (for screen porting)

All screens live in `lib/features/<name>/<name>_screen.dart`. They read state via
`provider` (`context.watch<XProvider>()` to rebuild, `context.read<XProvider>()` for actions).

## Theme & helpers
- `import '../../core/theme/app_theme.dart';` → `context.fc` returns `FinoraColors`:
  `textPrimary, textSecondary, textTertiary, surface, surfaceElevated, highlight, hairline, isDark`.
  `Brand.primaryBlue/accentBlue/primaryGreen/errorRed/warningOrange`.
  `AppText.mainBalance/pageTitle/sectionTitle/cardTitle/body/caption/overline` (TextStyle).
- `import '../../core/utils/formatters.dart';` → `formatVND(int)` → "1.000.000 ₫"; `CategoryIconHelper.resolveIcon(String?)` → emoji.
- `import '../../core/utils/date_filter.dart';` → `DateFilterOption` enum (`.key`, `.label`), `currentMonthKey()`, `monthKeyOf(int)`.

## Shared glass widgets — `import '../../core/widgets/glass_widgets.dart';`
- `GlassScaffold({PreferredSizeWidget? appBar, required Widget body, Widget? bottomNavigationBar, Widget? floatingActionButton})`
- `GlassTopBar({required String title, VoidCallback? onBack, List<Widget> actions})` — compact safe-area top bar.
- `GlassCard({required Widget child, EdgeInsets padding = 16, bool highlighted = false, double radius = 20, VoidCallback? onTap})`
- `PrimaryButton({required VoidCallback? onPressed, required Widget child, Color color = Brand.primaryBlue, bool glow = true, double height = 52, bool expand = false})`
- `GlassTextField({required TextEditingController controller, required String hint, TextInputType keyboardType, bool obscure, int maxLines, Widget? suffix})`
- `SegmentedControl({required List<(String,String)> options, required String selected, required ValueChanged<String> onChanged})` — (value,label) pairs.
- `FilterChipX({required String label, required bool selected, required VoidCallback onTap})`
- `SectionHeader({required String title, String? actionText, VoidCallback? onAction})`
- `Overline(String text)`
- `IconBadge({IconData? icon, String? emoji, required Color tint, double size = 42})`
- `EmptyState({required IconData icon, required String title, required String subtitle, String? actionText, VoidCallback? onAction})`

## Models — `import '../../data/models/...';`
- `transaction.dart` → `TransactionModel` (amount:int, type, date:int(ms), note?, categoryName?, categoryIcon?, categoryColor?, walletName?, fromWalletName?, toWalletName?, etc.). `copyWith({id,userId,amount,type})`.
- `wallet.dart` → `Wallet` (name, type, owner, ownerName, balance:int, currentDebt:int, creditLimit:int, isCreditCard:bool getter, themeColor?, bankCode?, ...).
- `category.dart` → `Category` (name, icon, color?, categoryGroup) + `Category.defaults` (List).
- `finance_models.dart` → `Budget, Goal, Loan, Asset, AppNotification, AppSettings`.

## Providers — `import '../../state/...';`
Each has a `Stream<String> events` (toast messages) — listen in `initState` and show a `SnackBar`.

- `TransactionProvider`: `filteredTransactions` (getter), `wallets`, `categories`, `searchQuery`, `selectedType`, `selectedWalletId`, `selectedDateFilter`. Methods: `load(uid)`, `setSearchQuery`, `setSelectedType`, `setSelectedWalletId`, `setSelectedDateFilter`, `createTransaction(uid,tx)`, `updateTransaction(uid,id,tx)`, `deleteTransaction(uid,tx)`.
- `WalletProvider`: `wallets`. `load(uid)`, `addWallet(uid,w)`, `updateWallet(uid,id,w)`, `deleteWallet(uid,id)`.
- `BudgetProvider`: `budgetsWithSpent` (List<BudgetSpentData{budget,spentAmount,progress}>), `categories`. `load(uid)`, `addBudget/updateBudget/deleteBudget`.
- `MoreProvider`: `assets, loans, goals, notifications, settings (AppSettings), wallets, categories`. `load(uid)`, plus CRUD: `addAsset/updateAsset/deleteAsset`, `addLoan/updateLoan/deleteLoan`, `addGoal/updateGoal/deleteGoal`, `markNotificationAsRead(uid,id)`, `deleteNotification(uid,id)`, `addCategory/updateCategory/deleteCategory`, `updateSettings(uid, AppSettings)`.
- `DashboardProvider`: `isLoading`, `error`, `data` (DashboardData{wallets, recentTransactions, allTransactions, totalWalletBalance, totalCreditCardDebt, currentMonthIncome, currentMonthExpenses, totalAssetsValue, totalBorrowed, totalLent, goalsCount}). `load(uid)`.
- `ThemeController`: `mode` ('system'|'light'|'dark'), `setMode(String)`.

## Screen constructors (must match exactly — referenced by MainScreen / navigation)
- `DashboardScreen({required String userId, required String userName})`
- `TransactionScreen({required String userId})`
- `ReportScreen({required String userId})`
- `MoreScreen({required String userId, required String userEmail, required String userName, String? userPhotoUrl, required VoidCallback onSignOut})`
- `AddTransactionPage({required String userId, TransactionModel? existing})` — full-screen form route.
- `WalletScreen({required String userId})`, `BudgetScreen({required String userId})`, `GoalScreen({required String userId})`,
  `AssetScreen({required String userId})`, `LoanScreen({required String userId})`, `CategoryScreen({required String userId})`,
  `NotificationScreen({required String userId})`, `SettingsScreen({required String userId})`,
  `ProfileScreen({required String userId, required String userEmail, required String userName, String? userPhotoUrl, required VoidCallback onSignOut})`

Navigation between screens: `Navigator.of(context).push(MaterialPageRoute(builder: (_) => WalletScreen(userId: userId)))`.
Full-screen forms: same with `fullscreenDialog: true`.

## Kotlin reference
Original screens: `D:\V-HO-\android-app\app\src\main\java\com\finora\app\feature\<name>\<Name>Screen.kt`.
Match their behavior/fields exactly; only the UI framework changes.
