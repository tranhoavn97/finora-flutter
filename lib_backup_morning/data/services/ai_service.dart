import 'dart:convert';
import 'dart:io';

/// Service to communicate with the local Node.js backend for Gemini AI capabilities.
class AiService {
  // Production builds can inject the deployed HTTPS backend with:
  // --dart-define=FINORA_API_BASE=https://api.example.com
  static const _configuredBase =
      String.fromEnvironment('FINORA_API_BASE', defaultValue: '');

  static String get _apiBase {
    if (_configuredBase.trim().isNotEmpty) {
      return _configuredBase.trim().replaceFirst(RegExp(r'/$'), '');
    }
    try {
      if (Platform.isAndroid) {
        // Development fallback for the Android emulator only.
        return 'http://10.0.2.2:3000';
      }
    } catch (_) {}
    return 'http://localhost:3000';
  }

  /// Communicates with `/api/gemini/chat` to get financial advice from Gemini.
  static Future<String> getFinancialAdvice({
    required String prompt,
    bool throwOnError = false,
    List<Map<String, dynamic>>? chatHistory,
    Map<String, dynamic>? userFinanceContext,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    try {
      final uri = Uri.parse('$_apiBase/api/gemini/chat');
      final request = await client.postUrl(uri);

      request.headers.contentType = ContentType.json;

      final body = {
        'message': prompt,
        if (chatHistory != null) 'history': chatHistory,
        if (userFinanceContext != null) 'context': userFinanceContext,
      };

      request.write(jsonEncode(body));
      final response =
          await request.close().timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        final text = data['text']?.toString().trim();
        if (text != null && text.isNotEmpty) return text;
        throw const FormatException('AI response is empty');
      } else {
        if (throwOnError)
          throw HttpException('AI server status ${response.statusCode}');
        return 'Máy chủ Finora AI đang bận (${response.statusCode}). Vui lòng thử lại sau.';
      }
    } catch (e) {
      if (throwOnError) rethrow;
      return _configuredBase.isEmpty
          ? 'Finora AI chưa được cấu hình máy chủ cho bản cài đặt này.'
          : 'Không thể kết nối Finora AI. Vui lòng kiểm tra mạng và thử lại.';
    } finally {
      client.close();
    }
  }

  /// Suggests budget limit recommendations based on transaction history and categories.
  static Future<List<dynamic>> getBudgetSuggestions({
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> categories,
    required List<Map<String, dynamic>> budgets,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);
    try {
      final uri = Uri.parse('$_apiBase/api/gemini/analyze-budgets');
      final request = await client.postUrl(uri);

      request.headers.contentType = ContentType.json;

      final body = {
        'transactions': transactions,
        'categories': categories,
        'budgets': budgets,
      };

      request.write(jsonEncode(body));
      final response =
          await request.close().timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        return data['suggestions'] ?? [];
      }
    } catch (_) {
    } finally {
      client.close();
    }
    return [];
  }
}
