import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/finance_models.dart';

/// Authenticated server-side GPT integration. Never represents local rules as GPT.
class AiService {
  // Production builds can inject the deployed HTTPS backend with:
  // --dart-define=FINORA_API_BASE=https://api.example.com
  static const _configuredBase = String.fromEnvironment('FINORA_API_BASE',
      defaultValue: 'https://finora-web-nine.vercel.app');

  static String get _apiBase {
    if (_configuredBase.trim().isNotEmpty) {
      return _configuredBase.trim().replaceFirst(RegExp(r'/$'), '');
    }
    return 'https://finora-web-nine.vercel.app';
  }

  static Future<AssistantReply> getAssistantReply({
    required String prompt,
    List<Map<String, dynamic>>? chatHistory,
    Map<String, dynamic>? userFinanceContext,
    http.Client? client,
    Future<String?> Function()? tokenProvider,
  }) async {
    final transport = client ?? http.Client();
    try {
      final token = await (tokenProvider?.call() ??
          FirebaseAuth.instance.currentUser?.getIdToken() ??
          Future<String?>.value(null));
      if (token == null || token.isEmpty)
        throw const AssistantException('Vui lòng đăng nhập lại để dùng GPT.');
      final response = await transport
          .post(
            Uri.parse('$_apiBase/api/openai/chat'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token'
            },
            body: jsonEncode({
              'message': prompt,
              'history': chatHistory ?? [],
              'context': userFinanceContext ?? {}
            }),
          )
          .timeout(const Duration(seconds: 30));
      return decodeAssistantReply(response);
    } on AssistantException {
      rethrow;
    } catch (_) {
      throw const AssistantException(
          'Chưa kết nối được GPT. Kiểm tra mạng và thử lại; chưa có giao dịch nào được ghi.');
    } finally {
      if (client == null) transport.close();
    }
  }

  static AssistantReply decodeAssistantReply(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {}
    if (response.statusCode != 200) {
      final code = data is Map ? data['code'] : null;
      if (code == 'OPENAI_NOT_CONFIGURED') {
        throw const AssistantException(
            'Chưa kích hoạt GPT. Chủ ứng dụng cần cấu hình OpenAI API trên máy chủ FINORA.');
      }
      if (response.statusCode == 401)
        throw const AssistantException(
            'Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.');
      if (response.statusCode == 429)
        throw const AssistantException(
            'GPT đang đạt giới hạn yêu cầu hoặc hạn mức API. Vui lòng thử lại sau.');
      if (response.statusCode == 404)
        throw const AssistantException(
            'Máy chủ chưa được cập nhật tích hợp GPT. Vui lòng triển khai API FINORA mới.');
      throw const AssistantException(
          'GPT tạm thời chưa trả lời được. Hãy thử lại sau.');
    }
    if (data is! Map ||
        data['source'] != 'openai' ||
        data['text'] is! String ||
        (data['text'] as String).trim().isEmpty ||
        data['transactions'] is! List) {
      throw const AssistantException(
          'Phản hồi GPT không hợp lệ. Chưa tạo giao dịch nào.');
    }
    final drafts = <SmartTransactionParsed>[];
    for (final raw in (data['transactions'] as List).take(10)) {
      if (raw is! Map ||
          !['income', 'expense'].contains(raw['type']) ||
          raw['amount'] is! num) {
        throw const AssistantException(
            'Bản nháp GPT không hợp lệ. Hãy thử lại.');
      }
      final amount = raw['amount'] as num;
      if (!amount.isFinite ||
          amount <= 0 ||
          amount > 1000000000000 ||
          amount != amount.round()) {
        throw const AssistantException('Số tiền trong bản nháp chưa hợp lệ.');
      }
      drafts.add(SmartTransactionParsed(
        type: raw['type'] as String,
        amount: amount.toInt(),
        note: raw['note']?.toString() ?? '',
        walletName: raw['walletName']?.toString(),
        categoryName: raw['categoryName']?.toString(),
        date: DateTime.tryParse(raw['date']?.toString() ?? '')
                ?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
      ));
    }
    return AssistantReply(text: data['text'] as String, transactions: drafts);
  }

  static Future<String> getFinancialAdvice(
      {required String prompt,
      bool throwOnError = false,
      List<Map<String, dynamic>>? chatHistory,
      Map<String, dynamic>? userFinanceContext}) async {
    return (await getAssistantReply(
            prompt: prompt,
            chatHistory: chatHistory,
            userFinanceContext: userFinanceContext))
        .text;
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
      final suggested = basedOnSpend;
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

class AssistantReply {
  final String text;
  final List<SmartTransactionParsed> transactions;
  const AssistantReply({required this.text, this.transactions = const []});
}

class AssistantException implements Exception {
  final String message;
  const AssistantException(this.message);
  @override
  String toString() => message;
}
