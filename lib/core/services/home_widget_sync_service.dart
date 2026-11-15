import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../data/services/wallet_repository.dart';
import '../../state/dashboard_provider.dart';

/// Synchronizes live spending metrics, wallet balance, and pending bank queue count
/// to the Android Home Screen 5x2 and 5x4 AppWidgets via `com.finora/home_widget`.
class HomeWidgetSyncService {
  static const MethodChannel _channel = MethodChannel('com.finora/home_widget');
  static final HomeWidgetSyncService _instance = HomeWidgetSyncService._internal();
  factory HomeWidgetSyncService() => _instance;
  HomeWidgetSyncService._internal();

  String _lastSignature = '';

  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Pure snapshot payload builder shared between native sync and unit tests.
  static Map<String, dynamic> buildPayload({
    required DashboardData dashboardData,
    required int pendingCount,
    required bool hideAmounts,
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    var todayExpense = 0;
    var todayCount = 0;

    for (final t in dashboardData.allTransactions) {
      if (t.date <= 0) continue;
      final dt = DateTime.fromMillisecondsSinceEpoch(t.date);
      if (dt.year == ref.year && dt.month == ref.month && dt.day == ref.day) {
        todayCount++;
        final normalized = WalletRepository.normalizeTransactionType(t.type);
        if (normalized == 'expense') {
          todayExpense += t.amount.abs();
        }
      }
    }

    final recent = dashboardData.recentTransactions.take(3).map((t) {
      final dt = DateTime.fromMillisecondsSinceEpoch(t.date);
      final type = WalletRepository.normalizeTransactionType(t.type);
      final cleanNote = (t.note ?? '').trim();
      final title = cleanNote.isNotEmpty
          ? cleanNote
          : (t.categoryName?.trim().isNotEmpty == true
              ? t.categoryName!.trim()
              : (type == 'transfer' ? 'Chuyển khoản' : 'Giao dịch'));
      final walletLabel = (t.walletName ?? t.fromWalletName ?? '').trim();
      final metaParts = <String>[
        if (t.categoryName != null &&
            t.categoryName!.trim().isNotEmpty &&
            cleanNote.isNotEmpty)
          t.categoryName!.trim(),
        if (walletLabel.isNotEmpty) walletLabel,
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}',
      ];
      return <String, dynamic>{
        'title': title,
        'meta': metaParts.join(' • '),
        'amount': type == 'income' ? t.amount.abs() : -t.amount.abs(),
        'type': type,
      };
    }).toList();

    final hh = ref.hour.toString().padLeft(2, '0');
    final mm = ref.minute.toString().padLeft(2, '0');

    return <String, dynamic>{
      'todayExpense': todayExpense.toDouble(),
      'todayCount': todayCount,
      'monthExpense': dashboardData.currentMonthExpenses.abs().toDouble(),
      'monthIncome': dashboardData.currentMonthIncome.abs().toDouble(),
      'totalBalance': dashboardData.totalWalletBalance.toDouble(),
      'hideAmounts': hideAmounts,
      'pendingCount': pendingCount < 0 ? 0 : pendingCount,
      'syncedAt': '$hh:$mm',
      'recent': recent,
    };
  }

  Future<void> sync({
    required DashboardData dashboardData,
    required int pendingCount,
    required bool hideAmounts,
    bool force = false,
  }) async {
    if (!supported) return;
    final payload = buildPayload(
      dashboardData: dashboardData,
      pendingCount: pendingCount,
      hideAmounts: hideAmounts,
    );
    final signature = jsonEncode(<String, dynamic>{
      'todayExpense': payload['todayExpense'],
      'todayCount': payload['todayCount'],
      'monthExpense': payload['monthExpense'],
      'monthIncome': payload['monthIncome'],
      'totalBalance': payload['totalBalance'],
      'hideAmounts': payload['hideAmounts'],
      'pendingCount': payload['pendingCount'],
      'recent': payload['recent'],
    });
    if (!force && signature == _lastSignature) return;
    _lastSignature = signature;

    try {
      await _channel.invokeMethod('syncWidgetData', {
        'payload': jsonEncode(payload),
      });
    } catch (_) {}
  }

  Future<void> refreshWidgets() async {
    if (!supported) return;
    try {
      await _channel.invokeMethod('refreshWidgets');
    } catch (_) {}
  }

  Future<bool> canPinWidgets() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('canPinWidgets') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Requests the Android launcher to pin the 5x2 or 5x4 FINORA Home Widget.
  Future<bool> requestPinWidget(String widgetType) async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('requestPinWidget', {
            'widgetType': widgetType == '5x4' ? '5x4' : '5x2',
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }
}
