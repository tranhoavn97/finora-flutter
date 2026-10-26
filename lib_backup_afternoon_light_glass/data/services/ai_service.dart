import 'dart:convert';
import 'dart:io';

/// Service to communicate with the local Node.js backend for Gemini AI capabilities.
class AiService {
  // Uses 10.0.2.2:3000 for Android Emulator, fallback to localhost:3000 for other platforms.
  static String get _apiBase {
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000';
      }
    } catch (_) {}
    return 'http://localhost:3000';
  }

  /// Communicates with `/api/gemini/chat` to get financial advice from Gemini.
  static Future<String> getFinancialAdvice({
    required String prompt,
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
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        return data['text'] ?? 'Không nhận được tư vấn từ cố vấn AI.';
      } else {
        return 'Lỗi kết nối từ máy chủ cố vấn (${response.statusCode}).';
      }
    } catch (e) {
      return 'Lỗi: Không thể kết nối với máy chủ AI của Finora. Vui lòng đảm bảo backend đang chạy.';
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
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        return data['suggestions'] ?? [];
      }
    } catch (_) {} finally {
      client.close();
    }
    return [];
  }
}
