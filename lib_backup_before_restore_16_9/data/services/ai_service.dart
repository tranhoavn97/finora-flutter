import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'finora_nlp_engine.dart';

/// Service to communicate with the Node.js / Vercel backend for Gemini AI capabilities
/// with seamless on-device heuristic fallback when offline or unavailable.
class AiService {
  // Production builds can inject the deployed HTTPS backend with:
  // --dart-define=FINORA_API_BASE=https://api.example.com
  static const _configuredBase = String.fromEnvironment('FINORA_API_BASE',
      defaultValue: 'https://finoraht.vercel.app');

  static String get _apiBase {
    if (_configuredBase.trim().isNotEmpty) {
      return _configuredBase.trim().replaceFirst(RegExp(r'/$'), '');
    }
    return 'https://finoraht.vercel.app';
  }

  /// Communicates with `/api/gemini/chat` to get financial advice from Gemini,
  /// with automatic fallback to FinoraNlpEngine.
  static Future<String> getFinancialAdvice({
    required String prompt,
    bool throwOnError = false,
    List<Map<String, dynamic>>? chatHistory,
    Map<String, dynamic>? userFinanceContext,
  }) async {
    final client = http.Client();
    try {
      final uri = Uri.parse('$_apiBase/api/gemini/chat');
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      final headers = {
        'Content-Type': 'application/json',
        if (idToken != null && idToken.isNotEmpty)
          'Authorization': 'Bearer $idToken',
      };

      final body = {
        'message': prompt,
        if (chatHistory != null) 'history': chatHistory,
        if (userFinanceContext != null) 'context': userFinanceContext,
      };

      final response = await client
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final text = data['text']?.toString().trim();
        if (text != null && text.isNotEmpty) return text;
      }
    } catch (e) {
      if (throwOnError) rethrow;
    } finally {
      client.close();
    }

    // Graceful fallback to on-device FinoraNlpEngine
    final fallback = FinoraNlpEngine.generateFinancialAdvice(
      query: prompt,
      financeContext: userFinanceContext,
    );
    return fallback.replyText ??
        'Finora AI luôn sẵn sàng đồng hành cùng bạn quản lý tài chính hiệu quả.';
  }

  /// Suggests budget limit recommendations based on transaction history and categories.
  static Future<List<dynamic>> getBudgetSuggestions({
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> categories,
    required List<Map<String, dynamic>> budgets,
  }) async {
    final client = http.Client();
    try {
      final uri = Uri.parse('$_apiBase/api/gemini/analyze-budgets');
      final body = {
        'transactions': transactions,
        'categories': categories,
        'budgets': budgets,
      };

      final response = await client
          .post(uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['suggestions'] is List &&
            (data['suggestions'] as List).isNotEmpty) {
          return data['suggestions'];
        }
      }
    } catch (_) {
    } finally {
      client.close();
    }

    return _localBudgetSuggestions(
      transactions: transactions,
      categories: categories,
      budgets: budgets,
    );
  }

  static List<Map<String, dynamic>> _localBudgetSuggestions({
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> categories,
    required List<Map<String, dynamic>> budgets,
  }) {
    final now = DateTime.now();
    final spendByCategory = <String, int>{};
    for (final tx in transactions) {
      if (tx['type']?.toString() != 'expense') continue;
      final rawDate = tx['date'];
      final milliseconds = rawDate is num
          ? (rawDate.toInt() < 100000000000
              ? rawDate.toInt() * 1000
              : rawDate.toInt())
          : 0;
      if (milliseconds <= 0) continue;
      final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
      if (date.year != now.year || date.month != now.month) continue;
      final amount = (tx['amount'] as num?)?.round() ?? 0;
      final categoryId = tx['categoryId']?.toString() ?? '';
      final categoryName =
          tx['categoryName']?.toString().trim().toLowerCase() ?? '';
      if (categoryId.isNotEmpty) {
        spendByCategory[categoryId] =
            (spendByCategory[categoryId] ?? 0) + amount;
      }
      if (categoryName.isNotEmpty) {
        spendByCategory[categoryName] =
            (spendByCategory[categoryName] ?? 0) + amount;
      }
    }

    int roundUp(int amount) => ((amount + 49999) ~/ 50000) * 50000;
    final results = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final budget in budgets) {
      final categoryId = budget['categoryId']?.toString() ?? '';
      if (categoryId.isEmpty || !seen.add(categoryId)) continue;
      final categoryName = budget['categoryName']?.toString() ??
          categories
              .where((category) => category['id']?.toString() == categoryId)
              .map((category) => category['name']?.toString() ?? '')
              .firstOrNull ??
          '';
      final current = (budget['limitAmount'] as num?)?.round() ?? 0;
      final spent = spendByCategory[categoryId] ??
          spendByCategory[categoryName.trim().toLowerCase()] ??
          0;
      final basedOnSpend =
          spent > 0 ? roundUp((spent * 1.15).round()) : current;
      final suggested = basedOnSpend > 0 ? basedOnSpend : 200000;
      final reasoning = spent > current && current > 0
          ? 'Chi tiêu tháng này đã vượt hạn mức. Finora đề xuất thêm 15% đệm và làm tròn để dễ theo dõi.'
          : spent > 0
              ? 'Đề xuất dựa trên chi tiêu thực tế tháng này, cộng 15% dự phòng.'
              : 'Tháng này chưa phát sinh chi tiêu; tạm giữ hạn mức hiện tại.';
      results.add({
        'categoryId': categoryId,
        'categoryName': categoryName,
        'currentSpend': spent,
        'currentBudget': current,
        'suggestedBudget': suggested,
        'reasoning': reasoning,
        'source': 'on_device',
      });
    }
    return results;
  }
}
