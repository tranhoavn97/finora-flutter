import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart' hide Category;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';

import '../data/models/category.dart';
import '../data/models/wallet.dart';
import '../data/models/transaction.dart';
import '../data/services/ai_service.dart';
import '../data/services/finora_nlp_engine.dart';
import '../data/services/transaction_repository.dart';

enum AiCardStatus { saved, pending, undone, error }

class AiTransactionCardData {
  final String id;
  TransactionModel transaction;
  AiCardStatus status;
  String? firestoreId;
  String? errorMessage;

  AiTransactionCardData({
    required this.id,
    required this.transaction,
    this.status = AiCardStatus.saved,
    this.firestoreId,
    this.errorMessage,
  });
}

class AiChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? intent;
  final List<AiTransactionCardData> cards;
  final bool isBillScan;
  final String? imagePath;
  final List<String> quickReplies;

  AiChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.intent,
    this.cards = const [],
    this.isBillScan = false,
    this.imagePath,
    this.quickReplies = const [],
  });
}

class AiChatProvider extends ChangeNotifier {
  final _txRepo = TransactionRepository();
  final _imagePicker = ImagePicker();

  final List<AiChatMessage> _messages = [];
  List<AiChatMessage> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Speech to text state
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool get isListening => _isListening;
  bool _speechAvailable = false;
  String _lastWords = '';
  String get lastWords => _lastWords;

  List<Category> _categories = [];
  List<Wallet> _wallets = [];
  String? _userId;

  List<Category> get categories => _categories;
  List<Wallet> get wallets => _wallets;

  AiChatProvider() {
    _initDefaultGreeting();
    _initSpeech();
  }

  void _initDefaultGreeting() {
    _messages.add(
      AiChatMessage(
        id: 'msg_welcome',
        text:
            'Xin chào! Tôi là **Finora AI Copilot** — trợ lý tài chính thông minh của bạn 🌟\n\n'
            'Bạn có thể gõ hoặc bấm mic nói tự nhiên như:\n'
            '• *"Ăn phở 45k tiền mặt"*\n'
            '• *"Sáng cafe 35k Momo, trưa ăn cơm 50k, chiều nhận lương 15tr vào VCB"*\n'
            '• *"Hôm nay tôi đã tiêu những gì?"*\n'
            '• *"Gợi ý hạn mức ngân sách 50/30/20"*\n\n'
            'Tôi sẽ tự động phân loại, ghi nhớ vào sổ chi tiêu và đưa ra tư vấn ngay lập tức!',
        isUser: false,
        timestamp: DateTime.now(),
        intent: 'greeting',
        quickReplies: [
          '🍜 Ăn phở 45k tiền mặt',
          '☕ Cafe 35k Momo',
          '📊 Hôm nay đã tiêu gì?',
          '🎯 Gợi ý ngân sách 50/30/20',
          '🏆 Đánh giá sức khỏe tài chính',
        ],
      ),
    );
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (err) {
          _isListening = false;
          notifyListeners();
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
      );
    } catch (_) {
      _speechAvailable = false;
    }
  }

  void setContextData({
    required String userId,
    required List<Category> categories,
    required List<Wallet> wallets,
  }) {
    _userId = userId;
    _categories = categories;
    _wallets = wallets;
  }

  Future<void> toggleVoiceListening(Function(String text) onResult) async {
    if (!_speechAvailable) {
      await _initSpeech();
      if (!_speechAvailable) return;
    }

    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
    } else {
      _isListening = true;
      _lastWords = '';
      notifyListeners();

      try {
        await _speech.listen(
          listenOptions: stt.SpeechListenOptions(
            partialResults: true,
          ),
          onResult: (result) {
            _lastWords = result.recognizedWords;
            onResult(_lastWords);
            if (result.finalResult) {
              _isListening = false;
              notifyListeners();
            }
          },
        );
      } catch (_) {
        _isListening = false;
        notifyListeners();
      }
    }
  }

  Future<void> stopVoiceListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage({
    required String text,
    required String userId,
    Map<String, dynamic>? financeContext,
    String? imagePath,
  }) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMsgId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    _messages.add(
      AiChatMessage(
        id: userMsgId,
        text: text.trim(),
        isUser: true,
        timestamp: DateTime.now(),
        imagePath: imagePath,
      ),
    );

    _isLoading = true;
    notifyListeners();

    try {
      final history = _messages
          .where((m) => m.text.isNotEmpty)
          .take(8)
          .map((m) => {
                'role': m.isUser ? 'user' : 'model',
                'parts': [
                  {'text': m.text}
                ],
              })
          .toList();

      final result = await AiService.smartChat(
        message: text,
        chatHistory: history,
        userFinanceContext: financeContext,
        categories: _categories,
        wallets: _wallets,
      );

      final List<AiTransactionCardData> cards = [];

      // Extracted transactions are drafts. Never mutate a user's ledger until
      // they explicitly confirm the card in the chat UI.
      if (result.transactions.isNotEmpty) {
        for (final item in result.transactions) {
          // Match category
          Category? matchedCat;
          if (item.categoryName != null && item.categoryName!.isNotEmpty) {
            final target = item.categoryName!.trim().toLowerCase();
            matchedCat = _categories.firstWhere(
              (c) =>
                  c.name.toLowerCase() == target ||
                  c.name.toLowerCase().contains(target),
              orElse: () => _categories.firstWhere(
                (c) => c.categoryGroup == item.type,
                orElse: () => _categories.isNotEmpty
                    ? _categories.first
                    : Category(
                        id: '',
                        name: item.categoryName ?? 'Chi tiêu',
                        icon: 'payments',
                        color: '#1877F2',
                        categoryGroup: item.type,
                      ),
              ),
            );
          } else {
            matchedCat = _categories.firstWhere(
              (c) => c.categoryGroup == item.type,
              orElse: () =>
                  _categories.isNotEmpty ? _categories.first : const Category(),
            );
          }

          // Match wallet
          Wallet? matchedWallet;
          if (item.walletName != null && item.walletName!.isNotEmpty) {
            final target = FinoraNlpEngine.normalize(item.walletName!);
            matchedWallet = _wallets.firstWhere(
              (w) => FinoraNlpEngine.normalize(w.name) == target,
              orElse: () => const Wallet(),
            );
            if (matchedWallet.id.isEmpty) matchedWallet = null;
          } else {
            matchedWallet = null;
          }

          final tx = TransactionModel(
            userId: userId,
            amount: item.amount,
            type: item.type,
            date: item.date ?? DateTime.now().millisecondsSinceEpoch,
            note: item.note.isNotEmpty
                ? item.note
                : (matchedCat?.name ?? 'Giao dịch Finora AI'),
            categoryId: matchedCat?.id,
            categoryName: matchedCat?.name ?? item.categoryName,
            categoryIcon: matchedCat?.icon ?? 'payments',
            categoryColor: matchedCat?.color ?? '#1877F2',
            walletId: matchedWallet?.id,
            walletName: matchedWallet?.name,
            owner: item.owner ?? matchedWallet?.owner,
            ownerName: item.ownerName ?? matchedWallet?.ownerName,
          );

          final cardId =
              'card_${DateTime.now().microsecondsSinceEpoch}_${cards.length}';
          final cardData = AiTransactionCardData(
            id: cardId,
            transaction: tx,
            status: AiCardStatus.pending,
          );

          cards.add(cardData);
        }
      }

      // Generate context-aware quick follow-ups
      final List<String> followUps = [];
      if (cards.isNotEmpty) {
        followUps.addAll([
          '📊 Hôm nay đã tiêu gì?',
          '💳 Xem số dư các ví',
          '🎯 Gợi ý ngân sách 50/30/20',
        ]);
      } else if (result.intent == 'daily_summary') {
        followUps.addAll([
          '🎯 Gợi ý ngân sách 50/30/20',
          '🏆 Đánh giá sức khỏe tài chính',
          '💡 Lời khuyên tiết kiệm',
        ]);
      } else if (result.intent == 'budget_advice') {
        followUps.addAll([
          '🏆 Đánh giá sức khỏe tài chính',
          '📊 Hôm nay đã tiêu gì?',
          '💳 Xem số dư các ví',
        ]);
      }

      final aiMsgId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
      _messages.add(
        AiChatMessage(
          id: aiMsgId,
          text: result.replyText,
          isUser: false,
          timestamp: DateTime.now(),
          intent: result.intent,
          cards: cards,
          quickReplies: followUps,
        ),
      );
    } catch (e) {
      _messages.add(
        AiChatMessage(
          id: 'ai_err_${DateTime.now().millisecondsSinceEpoch}',
          text:
              'Xin lỗi, không thể xử lý yêu cầu lúc này ($e). Vui lòng thử lại!',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> confirmTransaction({
    required AiTransactionCardData card,
    required String userId,
  }) async {
    if (card.status != AiCardStatus.pending &&
        card.status != AiCardStatus.error) return;
    card.status = AiCardStatus.pending;
    card.errorMessage = null;
    notifyListeners();
    try {
      final docId = await _txRepo.createTransaction(userId, card.transaction);
      card.firestoreId = docId;
      card.status = AiCardStatus.saved;
    } catch (e) {
      card.status = AiCardStatus.error;
      card.errorMessage = 'Không thể lưu: $e';
    }
    notifyListeners();
  }

  void dismissDraft(AiTransactionCardData card) {
    if (card.status != AiCardStatus.pending &&
        card.status != AiCardStatus.error) return;
    card.status = AiCardStatus.undone;
    card.errorMessage = null;
    notifyListeners();
  }

  /// Undo a saved transaction
  Future<void> undoTransaction({
    required AiTransactionCardData card,
    required String userId,
  }) async {
    if (card.firestoreId == null || card.status != AiCardStatus.saved) return;

    try {
      final txToReverse = card.transaction.copyWith(id: card.firestoreId!);
      await _txRepo.deleteTransactionAndReverse(userId, txToReverse);
      card.status = AiCardStatus.undone;
      notifyListeners();
    } catch (e) {
      card.errorMessage = 'Lỗi hoàn tác: $e';
      notifyListeners();
    }
  }

  /// Pick and scan a bill receipt
  Future<void> pickAndScanBill({
    required ImageSource source,
    required String userId,
    Map<String, dynamic>? financeContext,
  }) async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (file == null) return;

      _isLoading = true;
      notifyListeners();

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = file.mimeType ?? 'image/jpeg';

      final scannedData = await AiService.scanBill(
        base64Image: base64Image,
        mimeType: mimeType,
        categories: _categories,
        wallets: _wallets,
      );

      if (scannedData != null && scannedData['amount'] != null) {
        final title = scannedData['note']?.toString() ??
            scannedData['title']?.toString() ??
            'Hóa đơn thanh toán';
        final amount = (scannedData['amount'] as num).toInt();
        final category = scannedData['categoryName']?.toString() ??
            scannedData['category']?.toString() ??
            'Ăn uống';
        final promptText =
            'Quét hóa đơn "$title", số tiền $amount đ, danh mục "$category"';

        await sendMessage(
          text: promptText,
          userId: userId,
          financeContext: financeContext,
          imagePath: file.path,
        );
      } else {
        _messages.add(
          AiChatMessage(
            id: 'scan_fail_${DateTime.now().millisecondsSinceEpoch}',
            text:
                'Không trích xuất được hóa đơn từ ảnh đã chọn. Bạn có thể nhập trực tiếp bằng tin nhắn nhé!',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      _messages.add(
        AiChatMessage(
          id: 'scan_err_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Lỗi khi quét hóa đơn: $e',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearHistory() {
    _messages.clear();
    _initDefaultGreeting();
    notifyListeners();
  }
}
