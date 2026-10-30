import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/app_typography.dart';
import '../../core/utils/vietqr_parser.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/finora_notice.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../data/models/vietqr_data.dart';
import '../../data/services/qr_payment_draft_store.dart';
import '../../state/theme_studio_controller.dart';
import 'qr_confirm_expense_sheet.dart';

/// Screen for scanning VietQR codes with live camera, picking from gallery,
/// or entering transfer/QR details via a Luxury Bento modal sheet.
class QrScannerScreen extends StatefulWidget {
  final String userId;

  const QrScannerScreen({
    super.key,
    required this.userId,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _controller;
  late final AnimationController _animController;
  late final Animation<double> _scanLineAnimation;

  bool _isProcessing = false;
  bool _isTorchOn = false;

  String get _font => AppTypography.activeFontFamily ?? 'BeVietnamPro';

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) {
        _handleRawCode(raw);
        break;
      }
    }
  }

  void _handleRawCode(String raw) {
    if (_isProcessing) return;
    final data = VietQrParser.parse(raw);
    if (data == null ||
        (data.amount != null &&
            (!data.amount!.isFinite ||
                data.amount! < 0 ||
                data.amount! > 999999999999 ||
                data.amount! != data.amount!.truncateToDouble()))) {
      FinoraNotice.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Không nhận diện được mã VietQR hoặc định dạng ngân hàng hợp lệ.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    _openConfirmSheet(data);
  }

  Future<void> _resumeDrafts() async {
    try {
      final drafts = await QrPaymentDraftStore.list(widget.userId);
      if (!mounted) return;
      if (drafts.isEmpty) {
        FinoraNotice.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa có nháp QR trên máy.')),
        );
        return;
      }
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final studio = Provider.of<ThemeStudioController?>(context, listen: false);
      final primary = studio?.primaryColor ?? const Color(0xFF00866A);
      final fmt = NumberFormat('#,###', 'vi_VN');

      final draft = await showModalBottomSheet<QrPaymentDraft>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.68,
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF101920) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.22)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Row(
                  children: [
                    Icon(LucideIcons.clock, size: 19, color: primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Giao dịch QR chờ xác nhận (${drafts.length})',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: drafts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final d = drafts[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.pop(ctx, d),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF172430)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              BankIcon(
                                bankCode: d.data.bankShortName,
                                bankName: d.data.bankName,
                                size: 42,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${d.data.bankShortName} · ${d.data.accountNumber}',
                                      style: TextStyle(
                                        fontFamily: _font,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${fmt.format(d.amount).replaceAll(',', '.')} ₫${d.memo.isNotEmpty ? " · ${d.memo}" : ""}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: _font,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? const Color(0xFF34D399)
                                            : primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                LucideIcons.chevron_right,
                                size: 18,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (draft != null && mounted) {
        setState(() => _isProcessing = true);
        await _openConfirmSheet(draft.data, resumeDraft: draft);
      }
    } catch (_) {
      if (mounted) {
        FinoraNotice.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa đọc được bản nháp trên máy.')),
        );
      }
    }
  }

  Future<void> _openConfirmSheet(
    VietQrData data, {
    QrPaymentDraft? resumeDraft,
  }) async {
    try {
      await _controller.stop();
    } catch (_) {}
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: QrConfirmExpenseSheet(
          qrData: data,
          userId: widget.userId,
          resumeDraft: resumeDraft,
        ),
      ),
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      try {
        await _controller.start();
      } catch (_) {}
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final capture = await _controller.analyzeImage(image.path);
      if (capture != null && capture.barcodes.isNotEmpty) {
        final raw = capture.barcodes.first.rawValue;
        if (raw != null) {
          _handleRawCode(raw);
          return;
        }
      }

      if (mounted) {
        FinoraNotice.of(context).showSnackBar(
          const SnackBar(
              content: Text('Không tìm thấy mã QR trong bức ảnh đã chọn.')),
        );
      }
    } catch (e) {
      if (mounted) {
        FinoraNotice.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đọc ảnh: $e')),
        );
      }
    }
  }

  Future<void> _showManualInputDialog() async {
    HapticFeedback.selectionClick();
    final result = await showModalBottomSheet<VietQrData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: const _QrManualInputSheet(),
      ),
    );
    if (result != null && mounted) {
      setState(() => _isProcessing = true);
      await _openConfirmSheet(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    const scanBoxSize = 264.0;
    final studio = Provider.of<ThemeStudioController?>(context);
    final primary = studio?.primaryColor ?? const Color(0xFF00866A);
    final secondary = studio?.secondaryColor ?? const Color(0xFF10B981);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Camera Stream
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (ctx, err) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101920).withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.camera_off,
                            color: secondary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Chưa thể mở máy ảnh trực tiếp',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: _font,
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          err.errorDetails?.message ??
                              'Bạn có thể chọn ảnh mã QR từ thư viện hoặc nhập thông tin chuyển khoản trực tiếp bên dưới.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: _font,
                            color: Colors.white70,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _controller.start(),
                              icon: const Icon(Icons.refresh_rounded, size: 17),
                              label: const Text('Thử lại Camera'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.14),
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _pickImageFromGallery,
                              icon: const Icon(LucideIcons.image, size: 17),
                              label: const Text('Chọn ảnh QR'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showManualInputDialog,
                              icon: const Icon(LucideIcons.pen_line, size: 17),
                              label: const Text('Nhập thông tin CK'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // 2. Viewfinder Mask & Reticle
          Center(
            child: SizedBox(
              width: scanBoxSize,
              height: scanBoxSize,
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(scanBoxSize, scanBoxSize),
                    painter: _ViewfinderPainter(accentColor: secondary),
                  ),
                  AnimatedBuilder(
                    animation: _scanLineAnimation,
                    builder: (ctx, _) {
                      return Positioned(
                        top: _scanLineAnimation.value * (scanBoxSize - 4),
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                primary,
                                secondary,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: secondary.withValues(alpha: 0.65),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 3. Top Controls Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 14,
                right: 14,
                bottom: 14,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Quét mã VietQR',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _font,
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Nháp QR trên máy',
                    onPressed: _isProcessing ? null : _resumeDrafts,
                    icon: const Icon(LucideIcons.clock,
                        color: Colors.white, size: 20),
                  ),
                  IconButton(
                    icon: Icon(
                      _isTorchOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      color:
                          _isTorchOn ? const Color(0xFFFBBF24) : Colors.white70,
                    ),
                    onPressed: () async {
                      await _controller.toggleTorch();
                      setState(() => _isTorchOn = !_isTorchOn);
                    },
                  ),
                ],
              ),
            ),
          ),

          // 4. Bottom Guide & Actions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                top: 24,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.92),
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hướng camera vào mã VietQR hoặc chọn nhập liệu thủ công',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _font,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: _pickImageFromGallery,
                            icon: const Icon(LucideIcons.image, size: 17),
                            label: Text(
                              'Ảnh từ máy',
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.16),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.20),
                                ),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: _showManualInputDialog,
                            icon: const Icon(LucideIcons.pen_line, size: 17),
                            label: Text(
                              'Nhập tay / Dán QR',
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Luxury Bento Modal Sheet for Manual VietQR Transfer Input & Raw QR Paste
class _QrManualInputSheet extends StatefulWidget {
  const _QrManualInputSheet();

  @override
  State<_QrManualInputSheet> createState() => _QrManualInputSheetState();
}

class _QrManualInputSheetState extends State<_QrManualInputSheet> {
  /// 0 = Nhập thông tin CK, 1 = Dán chuỗi mã QR
  int _tabIndex = 0;

  late BankInfo _selectedBank;
  final _accountCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  final _rawQrCtrl = TextEditingController();

  String get _font => AppTypography.activeFontFamily ?? 'BeVietnamPro';

  List<BankInfo> get _allBanks => [
        ...VietQrParser.supportedBanks.values,
        ...VietQrParser.popularWallets,
      ];

  @override
  void initState() {
    super.initState();
    _selectedBank = VietQrParser.supportedBanks['970422'] ??
        VietQrParser.supportedBanks.values.first;
  }

  @override
  void dispose() {
    _accountCtrl.dispose();
    _accountNameCtrl.dispose();
    _amountCtrl.dispose();
    _memoCtrl.dispose();
    _rawQrCtrl.dispose();
    super.dispose();
  }

  double get _parsedAmount {
    final clean = _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(clean) ?? 0;
  }

  void _openBankPicker(Color primary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final banks = _allBanks;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.72,
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121C24) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.22)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Row(
                  children: [
                    Icon(LucideIcons.landmark, size: 18, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chọn ngân hàng / ví thụ hưởng',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.75,
                    ),
                    itemCount: banks.length,
                    itemBuilder: (_, idx) {
                      final bank = banks[idx];
                      final selected = bank.bin == _selectedBank.bin;
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedBank = bank);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? primary.withValues(
                                    alpha: isDark ? 0.22 : 0.10)
                                : (isDark
                                    ? const Color(0xFF1A2632)
                                    : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? primary
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFE2E8F0)),
                              width: selected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              BankIcon(
                                bankCode: bank.shortName,
                                bankName: bank.name,
                                size: 34,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bank.shortName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: _font,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      bank.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: _font,
                                        fontSize: 10.5,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submit() {
    HapticFeedback.lightImpact();
    if (_tabIndex == 1) {
      final raw = _rawQrCtrl.text.trim();
      if (raw.isEmpty) {
        FinoraNotice.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng dán chuỗi mã QR hoặc thông tin CK')),
        );
        return;
      }
      final parsed = VietQrParser.parse(raw);
      if (parsed == null) {
        FinoraNotice.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Không nhận diện được chuỗi QR. Hãy thử nhập ở tab "Nhập thông tin CK".'),
          ),
        );
        return;
      }
      Navigator.of(context).pop(parsed);
      return;
    }

    final acc = _accountCtrl.text.trim();
    if (acc.isEmpty) {
      FinoraNotice.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tài khoản người nhận')),
      );
      return;
    }

    final amt = _parsedAmount;
    final accName = _accountNameCtrl.text.trim();
    final memo = _memoCtrl.text.trim();

    final data = VietQrData(
      bankBin: _selectedBank.bin,
      bankName: _selectedBank.name,
      bankShortName: _selectedBank.shortName,
      bankLogo: _selectedBank.logo,
      accountNumber: acc,
      accountName: accName.isNotEmpty ? accName.toUpperCase() : null,
      amount: amt > 0 ? amt : null,
      memo: memo.isNotEmpty ? memo : null,
      rawPayload:
          '${_selectedBank.shortName}|$acc|${amt > 0 ? amt.toInt() : ""}|$memo',
      androidPackage: _selectedBank.androidPackage,
      iosScheme: _selectedBank.iosScheme,
    );

    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(context);
    final primary = studio?.primaryColor ?? const Color(0xFF00866A);
    final secondary = studio?.secondaryColor ?? const Color(0xFF10B981);
    final quickBanks = _allBanks.take(8).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: (MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom -
                40)
            .clamp(240, MediaQuery.sizeOf(context).height),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101920) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.14)
                : const Color(0xFFE2E8F0),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.15),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.22)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.qr_code,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nhập liệu giao dịch QR',
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Điền thông tin chuyển khoản hoặc dán chuỗi VietQR',
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Segmented Switcher: Nhập thông tin CK | Dán chuỗi mã QR
              Container(
                height: 44,
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF172430)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 0),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: _tabIndex == 0
                                ? (isDark
                                    ? const Color(0xFF223444)
                                    : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10.5),
                            boxShadow: _tabIndex == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                          alpha: isDark ? 0.25 : 0.06),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.landmark,
                                size: 14,
                                color: _tabIndex == 0
                                    ? (isDark
                                        ? const Color(0xFF34D399)
                                        : primary)
                                    : (isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Nhập thông tin CK',
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 12.8,
                                  fontWeight: _tabIndex == 0
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: _tabIndex == 0
                                      ? (isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A))
                                      : (isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 1),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: _tabIndex == 1
                                ? (isDark
                                    ? const Color(0xFF223444)
                                    : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10.5),
                            boxShadow: _tabIndex == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                          alpha: isDark ? 0.25 : 0.06),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.clipboard_paste,
                                size: 14,
                                color: _tabIndex == 1
                                    ? (isDark
                                        ? const Color(0xFF34D399)
                                        : primary)
                                    : (isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Dán chuỗi mã QR',
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 12.8,
                                  fontWeight: _tabIndex == 1
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: _tabIndex == 1
                                      ? (isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A))
                                      : (isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (_tabIndex == 0) ...[
                // Bank Selector Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabel('NGÂN HÀNG / VÍ NHẬN', isDark),
                    GestureDetector(
                      onTap: () => _openBankPicker(primary),
                      child: Text(
                        'Tất cả ngân hàng (${_allBanks.length}) ›',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF34D399) : primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Selected Bank Pod
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openBankPicker(primary),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF172430)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primary.withValues(alpha: isDark ? 0.45 : 0.30),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        BankIcon(
                          bankCode: _selectedBank.shortName,
                          bankName: _selectedBank.name,
                          size: 38,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_selectedBank.name} (${_selectedBank.shortName})',
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Mã BIN: ${_selectedBank.bin} · Nhấn để đổi ngân hàng',
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 11.5,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.chevron_down,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Horizontal Quick Bank Chips
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: quickBanks.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, idx) {
                      final b = quickBanks[idx];
                      final selected = b.bin == _selectedBank.bin;
                      return InkWell(
                        borderRadius: BorderRadius.circular(99),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedBank = b);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: selected
                                ? primary.withValues(
                                    alpha: isDark ? 0.24 : 0.12)
                                : (isDark
                                    ? const Color(0xFF172430)
                                    : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: selected
                                  ? primary
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              BankIcon(
                                bankCode: b.shortName,
                                bankName: b.name,
                                size: 22,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                b.shortName,
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: selected
                                      ? (isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A))
                                      : (isDark
                                          ? const Color(0xFFCBD5E1)
                                          : const Color(0xFF475569)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 14),

                // Account Number & Recipient Name
                _buildLabel('SỐ TÀI KHOẢN NGƯỜI NHẬN', isDark),
                const SizedBox(height: 6),
                _buildInputPod(
                  controller: _accountCtrl,
                  hint: 'Nhập số tài khoản hoặc SĐT ví...',
                  icon: LucideIcons.hash,
                  isDark: isDark,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 12),

                _buildLabel('TÊN CHỦ TÀI KHOẢN (TUỲ CHỌN)', isDark),
                const SizedBox(height: 6),
                _buildInputPod(
                  controller: _accountNameCtrl,
                  hint: 'Ví dụ: NGUYEN VAN A',
                  icon: LucideIcons.user,
                  isDark: isDark,
                  textCapitalization: TextCapitalization.characters,
                ),

                const SizedBox(height: 12),

                _buildLabel('SỐ TIỀN CHUYỂN (VND)', isDark),
                const SizedBox(height: 6),
                _buildInputPod(
                  controller: _amountCtrl,
                  hint: '0',
                  icon: LucideIcons.banknote,
                  isDark: isDark,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [DotSeparatorTextInputFormatter()],
                  suffixText: '₫',
                ),

                const SizedBox(height: 12),

                _buildLabel('NỘI DUNG CHUYỂN KHOẢN', isDark),
                const SizedBox(height: 6),
                _buildInputPod(
                  controller: _memoCtrl,
                  hint: 'Nhập lời nhắn hoặc lý do chi tiêu...',
                  icon: LucideIcons.file_text,
                  isDark: isDark,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ] else ...[
                // Raw QR String Paste Tab
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabel('CHUỖI MÃ VIETQR / THÔNG TIN CK', isDark),
                    TextButton.icon(
                      onPressed: () async {
                        final clip =
                            await Clipboard.getData(Clipboard.kTextPlain);
                        final text = clip?.text?.trim() ?? '';
                        if (text.isNotEmpty) {
                          setState(() => _rawQrCtrl.text = text);
                        }
                      },
                      icon: Icon(LucideIcons.clipboard_paste,
                          size: 14, color: primary),
                      label: Text(
                        'Dán từ bộ nhớ tạm',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF34D399) : primary,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF172430)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: TextField(
                    controller: _rawQrCtrl,
                    textCapitalization: TextCapitalization.none,
                    maxLines: 4,
                    style: TextStyle(
                      fontFamily: _font,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      hintText:
                          'Dán chuỗi EMVCo (000201...) hoặc định dạng nhanh:\nVCB|0123456789|50000|An trua',
                      hintStyle: TextStyle(
                        fontFamily: _font,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Submit CTA
              Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(primary, Colors.black, 0.12)!,
                      primary,
                      secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: isDark ? 0.38 : 0.24),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _submit,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.circle_arrow_right,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Tiếp tục chọn Danh mục & Ví thanh toán',
                          style: TextStyle(
                            fontFamily: _font,
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: _font,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.55,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
      ),
    );
  }

  Widget _buildInputPod({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? suffixText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172430) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        style: TextStyle(
          fontFamily: _font,
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          prefixIcon: Icon(
            icon,
            size: 17,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 32, minHeight: 42),
          suffixText: suffixText,
          suffixStyle: TextStyle(
            fontFamily: _font,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: _font,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for camera viewfinder corner brackets
class _ViewfinderPainter extends CustomPainter {
  final Color accentColor;
  const _ViewfinderPainter({this.accentColor = const Color(0xFF38BDF8)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor
      ..strokeWidth = 3.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 30.0;

    // Top-Left
    canvas.drawLine(const Offset(0, cornerLen), Offset.zero, paint);
    canvas.drawLine(Offset.zero, const Offset(cornerLen, 0), paint);

    // Top-Right
    canvas.drawLine(
        Offset(size.width - cornerLen, 0), Offset(size.width, 0), paint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, cornerLen), paint);

    // Bottom-Left
    canvas.drawLine(
        Offset(0, size.height - cornerLen), Offset(0, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(cornerLen, size.height), paint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width - cornerLen, size.height),
        Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - cornerLen), paint);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}
