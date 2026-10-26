import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/models/transaction.dart';
import '../data/models/wallet.dart';
import '../data/services/auth_repository.dart';
import 'finance_store.dart';
import 'theme.dart';

final _money =
    NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
String money(num value) => _money.format(value);

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.user});
  final User user;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final FinanceStore _store = FinanceStore(widget.user.uid)..start();

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  void _compose() => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ChangeNotifierProvider.value(
            value: _store, child: const TransactionComposer()),
      );

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
        value: _store,
        child: Scaffold(
          body: IndexedStack(index: _index, children: [
            OverviewPage(user: widget.user, onAdd: _compose),
            const ActivityPage(),
            const WalletsPage(),
            ProfilePage(user: widget.user),
          ]),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.10)
                                : Colors.black.withValues(alpha: 0.06),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                  alpha: Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                        child: Row(
                          children: [
                            _nav(0, Icons.space_dashboard_rounded, 'Tổng quan'),
                            _nav(1, Icons.receipt_long_rounded, 'Dòng tiền'),
                            _nav(2, Icons.account_balance_wallet_rounded, 'Ví'),
                            _nav(3, Icons.grid_view_rounded, 'Khác'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _compose();
                      },
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFF5E62), Color(0xFFFF416C)],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.30),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF416C).withValues(alpha: 0.45),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _nav(int index, IconData icon, String label) {
    final isSelected = _index == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      flex: isSelected ? 3 : 2,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _index = index);
        },
        borderRadius: BorderRadius.circular(100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: isSelected ? 10 : 4, vertical: 6),
          decoration: isSelected
              ? BoxDecoration(
                  color: isDark ? const Color(0xFF24324A) : Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.16)
                        : Colors.black.withValues(alpha: 0.05),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : null,
          child: isSelected
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 19, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                )
              : Icon(
                  icon,
                  size: 21,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
        ),
      ),
    );
  }
}

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key, required this.user, required this.onAdd});
  final User user;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final name = user.displayName?.split(' ').last ??
        user.email?.split('@').first ??
        'bạn';
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async =>
            Future<void>.delayed(const Duration(milliseconds: 500)),
        child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
            children: [
              Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('CHÀO $name'.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                              color: FinoraTheme.cobalt)),
                      const SizedBox(height: 4),
                      Text('Tiền của bạn, hôm nay.',
                          style: Theme.of(context).textTheme.headlineSmall),
                    ])),
                CircleAvatar(
                    radius: 23,
                    backgroundColor: FinoraTheme.lime,
                    backgroundImage: user.photoURL == null
                        ? null
                        : NetworkImage(user.photoURL!),
                    child: user.photoURL == null
                        ? Text(name.characters.first.toUpperCase(),
                            style: const TextStyle(
                                color: FinoraTheme.ink,
                                fontWeight: FontWeight.w900))
                        : null),
              ]),
              const SizedBox(height: 24),
              _BalanceHero(store: store),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: _Metric(
                        label: 'Thu tháng này',
                        value: money(store.income),
                        color: const Color(0xFF16A46D),
                        icon: Icons.south_west_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _Metric(
                        label: 'Chi tháng này',
                        value: money(store.expense),
                        color: FinoraTheme.coral,
                        icon: Icons.north_east_rounded)),
              ]),
              const SizedBox(height: 28),
              const _SectionTitle(title: 'Nhịp chi tiêu', action: 'Tháng này'),
              const SizedBox(height: 12),
              _PulseChart(transactions: store.transactions),
              const SizedBox(height: 28),
              const _SectionTitle(title: 'Gần đây', action: 'Xem tất cả'),
              const SizedBox(height: 10),
              if (store.loading)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator()))
              else if (store.transactions.isEmpty)
                _EmptyState(onAdd: onAdd)
              else
                ...store.transactions
                    .take(5)
                    .map((tx) => TransactionTile(transaction: tx)),
            ]),
      ),
    );
  }
}

class _BalanceHero extends StatefulWidget {
  const _BalanceHero({required this.store});
  final FinanceStore store;
  @override
  State<_BalanceHero> createState() => _BalanceHeroState();
}

class _BalanceHeroState extends State<_BalanceHero> {
  bool hidden = false;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: FinoraTheme.ink,
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
              colors: [Color(0xFF171B16), Color(0xFF252C20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
                child: Text('GIÁ TRỊ RÒNG',
                    style: TextStyle(
                        color: Color(0xFFADB3A8),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5))),
            IconButton(
                onPressed: () => setState(() => hidden = !hidden),
                icon: Icon(
                    hidden
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.white70)),
          ]),
          Text(hidden ? '••••••••' : money(widget.store.netWorth),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5)),
          const SizedBox(height: 22),
          Row(children: [
            _HeroDatum(
                label: 'Khả dụng',
                value: hidden ? '••••' : money(widget.store.balance)),
            Container(
                width: 1,
                height: 34,
                color: Colors.white12,
                margin: const EdgeInsets.symmetric(horizontal: 20)),
            _HeroDatum(
                label: 'Dư nợ',
                value: hidden ? '••••' : money(widget.store.debt)),
          ]),
        ]),
      );
}

class _HeroDatum extends StatelessWidget {
  const _HeroDatum({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(color: Color(0xFF7F887A), fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800))
      ]));
}

class _Metric extends StatelessWidget {
  const _Metric(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});
  final String label, value;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, color: color, size: 18)),
            const SizedBox(height: 14),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: .5))),
            const SizedBox(height: 3),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))
          ])));
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action});
  final String title, action;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child:
                Text(title, style: Theme.of(context).textTheme.headlineSmall)),
        Text(action,
            style: const TextStyle(
                color: FinoraTheme.cobalt,
                fontSize: 12,
                fontWeight: FontWeight.w800))
      ]);
}

class _PulseChart extends StatelessWidget {
  const _PulseChart({required this.transactions});
  final List<TransactionModel> transactions;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final values = List<int>.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
      return transactions.where((t) {
        final d = DateTime.fromMillisecondsSinceEpoch(t.date);
        return t.type == 'expense' &&
            d.year == day.year &&
            d.month == day.month &&
            d.day == day.day;
      }).fold(0, (v, t) => v + t.amount);
    });
    final maxValue = math.max(1, values.fold(0, math.max));
    return Card(
        child: SizedBox(
            height: 180,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final ratio = values[i] / maxValue;
                      final day = now.subtract(Duration(days: 6 - i));
                      return Expanded(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                            Expanded(
                                child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 400),
                                        width: 18,
                                        height: 12 + 92 * ratio,
                                        decoration: BoxDecoration(
                                            color: i == 6
                                                ? FinoraTheme.lime
                                                : FinoraTheme.cobalt.withValues(
                                                    alpha: .25 + ratio * .45),
                                            borderRadius:
                                                BorderRadius.circular(10))))),
                            const SizedBox(height: 8),
                            Text(
                                DateFormat('E', 'vi')
                                    .format(day)
                                    .replaceAll('Th ', 'T'),
                                style: const TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w700))
                          ]));
                    })))));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(children: [
            const Icon(Icons.auto_graph_rounded,
                color: FinoraTheme.cobalt, size: 34),
            const SizedBox(height: 12),
            const Text('Chưa có chuyển động nào',
                style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('Thêm giao dịch đầu tiên để Finora bắt đầu phân tích.',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
                onPressed: onAdd, child: const Text('Thêm giao dịch'))
          ])));
}

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});
  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  String query = '';
  String filter = 'all';
  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final items = store.transactions
        .where((t) =>
            (filter == 'all' || t.type == filter) &&
            ('${t.note} ${t.categoryName} ${t.walletName}')
                .toLowerCase()
                .contains(query.toLowerCase()))
        .toList();
    const filters = [
      ('all', 'Tất cả'),
      ('expense', 'Chi'),
      ('income', 'Thu'),
      ('transfer', 'Chuyển')
    ];
    return SafeArea(
      bottom: false,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dòng tiền',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            TextField(
                onChanged: (v) => setState(() => query = v),
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Tìm giao dịch, ví, ghi chú...')),
            const SizedBox(height: 12),
            Row(
                children: filters
                    .map((entry) => Expanded(
                        child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                                selected: filter == entry.$1,
                                onSelected: (_) =>
                                    setState(() => filter = entry.$1),
                                label: SizedBox(
                                    width: double.infinity,
                                    child: Text(entry.$2,
                                        textAlign: TextAlign.center))))))
                    .toList()),
          ]),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Không có giao dịch phù hợp'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                  itemCount: items.length,
                  itemBuilder: (_, i) => Dismissible(
                    key: ValueKey(items[i].id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async =>
                        await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                                    title: const Text('Xóa giao dịch?'),
                                    content: const Text(
                                        'Thay đổi sẽ được đồng bộ ngay với bản web.'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Hủy')),
                                      FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Xóa'))
                                    ])) ??
                        false,
                    onDismissed: (_) => store.deleteTransaction(items[i]),
                    background: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.only(right: 20),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                            color: FinoraTheme.coral,
                            borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.delete_rounded,
                            color: Colors.white)),
                    child: TransactionTile(transaction: items[i]),
                  ),
                ),
        ),
      ]),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});
  final TransactionModel transaction;
  @override
  Widget build(BuildContext context) {
    final income = transaction.type == 'income';
    final transfer = transaction.type == 'transfer';
    final color = transfer
        ? FinoraTheme.cobalt
        : income
            ? const Color(0xFF16A46D)
            : FinoraTheme.coral;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(
                  transfer
                      ? Icons.swap_horiz_rounded
                      : income
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                  color: color)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                    transaction.note?.isNotEmpty == true
                        ? transaction.note!
                        : transaction.categoryName ??
                            (transfer ? 'Chuyển tiền' : 'Giao dịch'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                    '${transaction.walletName ?? transaction.fromWalletName ?? 'Ví'} · ${DateFormat('dd/MM, HH:mm').format(DateTime.fromMillisecondsSinceEpoch(transaction.date))}',
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: .48)))
              ])),
          Text(
              '${income ? '+' : transfer ? '' : '-'}${money(transaction.amount)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w900))
        ]));
  }
}

class WalletsPage extends StatelessWidget {
  const WalletsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    return SafeArea(
        bottom: false,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            children: [
              Row(children: [
                Expanded(
                    child: Text('Ví & tài khoản',
                        style: Theme.of(context).textTheme.headlineMedium)),
                IconButton.filled(
                    onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => ChangeNotifierProvider.value(
                            value: store, child: const WalletComposer())),
                    icon: const Icon(Icons.add_rounded))
              ]),
              const SizedBox(height: 6),
              Text(
                  '${store.wallets.length} nguồn tiền · ${money(store.balance)} khả dụng',
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: .5))),
              const SizedBox(height: 24),
              if (store.wallets.isEmpty)
                const Card(
                    child: Padding(
                        padding: EdgeInsets.all(30),
                        child: Column(children: [
                          Icon(Icons.wallet_outlined,
                              size: 38, color: FinoraTheme.cobalt),
                          SizedBox(height: 12),
                          Text('Thêm ví đầu tiên',
                              style: TextStyle(fontWeight: FontWeight.w900)),
                          SizedBox(height: 6),
                          Text(
                              'Tài khoản ngân hàng, tiền mặt hoặc thẻ tín dụng.')
                        ]))),
              ...store.wallets.map((wallet) => _WalletPanel(wallet: wallet)),
            ]));
  }
}

class _WalletPanel extends StatelessWidget {
  const _WalletPanel({required this.wallet});
  final Wallet wallet;
  @override
  Widget build(BuildContext context) {
    final store = context.read<FinanceStore>();
    final colors = wallet.isCreditCard
        ? const [Color(0xFF5C6CFF), Color(0xFF2732A8)]
        : const [Color(0xFF1E2520), Color(0xFF3B4737)];
    return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(28)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(
                    wallet.isCreditCard
                        ? Icons.credit_card_rounded
                        : Icons.account_balance_wallet_rounded,
                    color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(wallet.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16)),
                  Text(
                      wallet.bankName ??
                          (wallet.isCreditCard
                              ? 'Thẻ tín dụng'
                              : 'Ví thanh toán'),
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 11))
                ])),
            PopupMenuButton<String>(
                iconColor: Colors.white,
                onSelected: (v) {
                  if (v == 'delete') store.deleteWallet(wallet);
                },
                itemBuilder: (_) => const [
                      PopupMenuItem(value: 'delete', child: Text('Xóa ví'))
                    ])
          ]),
          const SizedBox(height: 28),
          Text(wallet.isCreditCard ? 'DƯ NỢ HIỆN TẠI' : 'SỐ DƯ KHẢ DỤNG',
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2)),
          const SizedBox(height: 5),
          Text(money(wallet.isCreditCard ? wallet.currentDebt : wallet.balance),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7)),
          const SizedBox(height: 18),
          Row(children: [
            Text(wallet.ownerName.toUpperCase(),
                style: const TextStyle(
                    color: FinoraTheme.lime,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1)),
            const Spacer(),
            if (wallet.accountNumber?.isNotEmpty == true)
              Text(
                  '•••• ${wallet.accountNumber!.substring(math.max(0, wallet.accountNumber!.length - 4))}',
                  style: const TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.w700))
          ]),
        ]));
  }
}

class WalletComposer extends StatefulWidget {
  const WalletComposer({super.key});
  @override
  State<WalletComposer> createState() => _WalletComposerState();
}

class _WalletComposerState extends State<WalletComposer> {
  final name = TextEditingController();
  final amount = TextEditingController();
  String type = 'bank';
  String owner = 'husband';
  bool busy = false;
  @override
  void dispose() {
    name.dispose();
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
      padding: EdgeInsets.fromLTRB(
          20, 24, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Ví mới', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        TextField(
            controller: name,
            autofocus: true,
            decoration:
                const InputDecoration(labelText: 'Tên ví hoặc ngân hàng')),
        const SizedBox(height: 12),
        TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
                labelText: type == 'credit_card'
                    ? 'Hạn mức tín dụng'
                    : 'Số dư ban đầu')),
        const SizedBox(height: 12),
        SegmentedButton<String>(segments: const [
          ButtonSegment(value: 'bank', label: Text('Tài khoản')),
          ButtonSegment(value: 'cash', label: Text('Tiền mặt')),
          ButtonSegment(value: 'credit_card', label: Text('Tín dụng'))
        ], selected: {
          type
        }, onSelectionChanged: (v) => setState(() => type = v.first)),
        const SizedBox(height: 12),
        SegmentedButton<String>(segments: const [
          ButtonSegment(value: 'husband', label: Text('Chồng')),
          ButtonSegment(value: 'wife', label: Text('Vợ'))
        ], selected: {
          owner
        }, onSelectionChanged: (v) => setState(() => owner = v.first)),
        const SizedBox(height: 22),
        FilledButton(
            onPressed: busy
                ? null
                : () async {
                    if (name.text.trim().isEmpty) return;
                    setState(() => busy = true);
                    final value = int.tryParse(
                            amount.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                        0;
                    await context.read<FinanceStore>().addWallet(Wallet(
                        name: name.text.trim(),
                        type: type,
                        owner: owner,
                        ownerName: owner == 'wife' ? 'Vợ' : 'Chồng',
                        initialBalance: type == 'credit_card' ? 0 : value,
                        creditLimit: type == 'credit_card' ? value : 0));
                    if (context.mounted) Navigator.pop(context);
                  },
            child: const Text('Tạo ví')),
      ])));
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.user});
  final User user;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final savingsRate = store.income == 0
        ? 0
        : ((store.income - store.expense) / store.income * 100)
            .clamp(0, 100)
            .round();
    return SafeArea(
        bottom: false,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            children: [
              Text('Không gian của bạn',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 22),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(children: [
                        CircleAvatar(
                            radius: 28,
                            backgroundColor: FinoraTheme.lime,
                            backgroundImage: user.photoURL == null
                                ? null
                                : NetworkImage(user.photoURL!),
                            child: user.photoURL == null
                                ? const Icon(Icons.person_rounded,
                                    color: FinoraTheme.ink)
                                : null),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(user.displayName ?? 'Tài khoản Finora',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16)),
                              Text(user.email ?? '',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: .5)))
                            ]))
                      ]))),
              const SizedBox(height: 24),
              Text('Sức khỏe tài chính',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                      color: FinoraTheme.cobalt,
                      borderRadius: BorderRadius.circular(28)),
                  child: Row(children: [
                    SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(alignment: Alignment.center, children: [
                          CircularProgressIndicator(
                              value: savingsRate / 100,
                              strokeWidth: 8,
                              backgroundColor: Colors.white12,
                              color: FinoraTheme.lime),
                          Text('$savingsRate',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900))
                        ])),
                    const SizedBox(width: 20),
                    const Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('TỶ LỆ TÍCH LŨY',
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1)),
                          SizedBox(height: 7),
                          Text('Mỗi quyết định nhỏ đang tạo nên bức tranh lớn.',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  height: 1.35))
                        ]))
                  ])),
              const SizedBox(height: 24),
              Text('Công cụ', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              const _ToolTile(
                  icon: Icons.pie_chart_rounded,
                  title: 'Ngân sách',
                  subtitle: 'Hạn mức và quy tắc 50/30/20'),
              const _ToolTile(
                  icon: Icons.flag_rounded,
                  title: 'Mục tiêu',
                  subtitle: 'Theo dõi các cột mốc tài chính'),
              const _ToolTile(
                  icon: Icons.trending_up_rounded,
                  title: 'Tài sản & đầu tư',
                  subtitle: 'Danh mục và hiệu suất'),
              const _ToolTile(
                  icon: Icons.handshake_rounded,
                  title: 'Khoản vay',
                  subtitle: 'Khoản phải thu và phải trả'),
              const _ToolTile(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Finora AI',
                  subtitle: 'Phân tích và ghi chép tự nhiên'),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                  onPressed: () => AuthRepository().signOut(),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Đăng xuất'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      foregroundColor: FinoraTheme.coral,
                      side: const BorderSide(color: FinoraTheme.coral),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)))),
            ]));
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: FinoraTheme.cobalt.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: FinoraTheme.cobalt, size: 20)),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14)));
}

class TransactionComposer extends StatefulWidget {
  const TransactionComposer({super.key});
  @override
  State<TransactionComposer> createState() => _TransactionComposerState();
}

class _TransactionComposerState extends State<TransactionComposer> {
  final amount = TextEditingController();
  final note = TextEditingController();
  String type = 'expense';
  String owner = 'husband';
  String? walletId;
  bool busy = false;
  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallets = context.watch<FinanceStore>().wallets;
    walletId ??= wallets.isEmpty ? null : wallets.first.id;
    return Container(
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32))),
        padding: EdgeInsets.fromLTRB(
            20, 22, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text('Giao dịch mới',
                    style: Theme.of(context).textTheme.headlineMedium)),
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded))
          ]),
          const SizedBox(height: 18),
          TextField(
              controller: amount,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
              decoration:
                  const InputDecoration(prefixText: '₫ ', hintText: '0')),
          const SizedBox(height: 14),
          SegmentedButton<String>(segments: const [
            ButtonSegment(
                value: 'expense',
                icon: Icon(Icons.north_east_rounded),
                label: Text('Chi')),
            ButtonSegment(
                value: 'income',
                icon: Icon(Icons.south_west_rounded),
                label: Text('Thu')),
            ButtonSegment(
                value: 'transfer',
                icon: Icon(Icons.swap_horiz_rounded),
                label: Text('Chuyển'))
          ], selected: {
            type
          }, onSelectionChanged: (v) => setState(() => type = v.first)),
          const SizedBox(height: 14),
          TextField(
              controller: note,
              decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  prefixIcon: Icon(Icons.edit_note_rounded))),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
              initialValue: walletId,
              decoration: const InputDecoration(
                  labelText: 'Nguồn tiền',
                  prefixIcon: Icon(Icons.account_balance_wallet_rounded)),
              items: wallets
                  .map(
                      (w) => DropdownMenuItem(value: w.id, child: Text(w.name)))
                  .toList(),
              onChanged: (v) => setState(() => walletId = v)),
          const SizedBox(height: 12),
          SegmentedButton<String>(segments: const [
            ButtonSegment(value: 'husband', label: Text('Chồng')),
            ButtonSegment(value: 'wife', label: Text('Vợ'))
          ], selected: {
            owner
          }, onSelectionChanged: (v) => setState(() => owner = v.first)),
          const SizedBox(height: 22),
          FilledButton(
              onPressed: busy || walletId == null
                  ? null
                  : () async {
                      final value = int.tryParse(
                              amount.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                          0;
                      if (value <= 0) return;
                      setState(() => busy = true);
                      final wallet =
                          wallets.firstWhere((w) => w.id == walletId);
                      await context.read<FinanceStore>().addTransaction(
                          TransactionModel(
                              amount: value,
                              type: type,
                              date: DateTime.now().millisecondsSinceEpoch,
                              note: note.text.trim(),
                              categoryName: type == 'income'
                                  ? 'Thu nhập'
                                  : type == 'transfer'
                                      ? 'Chuyển tiền'
                                      : 'Chi tiêu',
                              walletId: wallet.id,
                              walletName: wallet.name,
                              fromWalletId:
                                  type == 'transfer' ? wallet.id : null,
                              fromWalletName:
                                  type == 'transfer' ? wallet.name : null,
                              owner: owner,
                              ownerName: owner == 'wife' ? 'Vợ' : 'Chồng'));
                      if (context.mounted) Navigator.pop(context);
                    },
              child: Text(busy ? 'Đang đồng bộ...' : 'Lưu giao dịch')),
        ])));
  }
}
