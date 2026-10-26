import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/wallet.dart';

/// Same card hierarchy and physical aspect ratio as the web wallet page.
class WebWalletCard extends StatelessWidget {
  static double minimumHeight(BuildContext context, {required bool credit}) =>
      (credit ? 188.0 : 140.0) *
      math.max(1.0, MediaQuery.textScalerOf(context).scale(12) / 12);
  final Wallet wallet;
  final bool masked;
  final VoidCallback onHistory, onEdit, onDelete;
  final VoidCallback? onPay;
  final double aspectRatio;
  const WebWalletCard(
      {super.key,
      required this.wallet,
      this.masked = false,
      required this.onHistory,
      required this.onEdit,
      required this.onDelete,
      this.onPay,
      this.aspectRatio = 1.88});
  @override
  Widget build(BuildContext context) {
    final w = wallet;
    final brand =
        BankIconRegistry.resolve(w.bankCode, bankName: w.bankName ?? w.name);
    final cash = w.type == 'cash';
    final credit = w.isCreditCard;
    final name = w.name.toLowerCase();
    var skin = w.themeColor ?? '';
    if (skin.isEmpty) {
      if (RegExp('gold|vàng').hasMatch(name)) {
        skin = 'gold';
      } else if (RegExp('silver|sliver|bạc|platinum').hasMatch(name)) {
        skin = 'silver';
      } else if (['mbbank', 'bidv', 'acb'].contains(brand.code)) {
        skin = 'blue';
      } else if (['vcb', 'vpb'].contains(brand.code)) {
        skin = 'emerald';
      } else if (['tcb', 'cake', 'hdb'].contains(brand.code)) {
        skin = 'rose';
      } else if (['tpb', 'timo'].contains(brand.code)) {
        skin = 'purple';
      }
    }
    const skins = <String, List<Color>>{
      'gold': [Color(0xFF4A380A), Color(0xFF785C14), Color(0xFF2E2205)],
      'silver': [Color(0xFF2C3440), Color(0xFF455263), Color(0xFF1C222B)],
      'blue': [Color(0xFF0D366E), Color(0xFF1A5BB8), Color(0xFF082247)],
      'cyan': [Color(0xFF084857), Color(0xFF0D728A), Color(0xFF052C36)],
      'emerald': [Color(0xFF08452D), Color(0xFF0F6E49), Color(0xFF052B1C)],
      'lime': [Color(0xFF354D08), Color(0xFF567A10), Color(0xFF203004)],
      'orange': [Color(0xFF632707), Color(0xFF9C3F0E), Color(0xFF3B1703)],
      'rose': [Color(0xFF590D1B), Color(0xFF8C162D), Color(0xFF3B0710)],
      'pink': [Color(0xFF590B37), Color(0xFF8C1457), Color(0xFF3B0623)],
      'purple': [Color(0xFF3A0F5C), Color(0xFF601A99), Color(0xFF24083B)],
      'indigo': [Color(0xFF1F1F69), Color(0xFF3535A6), Color(0xFF131342)],
      'black': [Color(0xFF18191E), Color(0xFF242730), Color(0xFF0F1013)]
    };
    final colors = cash
        ? const [Color(0xFF06281D), Color(0xFF093527), Color(0xFF041A13)]
        : skins[skin.toLowerCase()] ?? skins['black']!;
    final usage = w.creditLimit > 0 ? w.currentDebt / w.creditLimit : 0.0;
    final available = math.max(0, w.creditLimit - w.currentDebt);
    Widget logo(double size) => brand.assetPath != null && !cash
        ? Image.asset(brand.assetPath!,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(Icons.account_balance,
                size: size * .65, color: const Color(0xFF0F172A)))
        : Icon(cash ? Icons.payments_outlined : Icons.account_balance,
            size: size * .65, color: Colors.white);
    Widget money(int value, {Color color = Colors.white, double size = 16}) =>
        FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(masked ? '•••••• ₫' : formatVND(value),
                style: TextStyle(
                    color: color,
                    fontSize: size,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    fontFeatures: const [FontFeature.tabularFigures()])));
    const muted = TextStyle(color: Colors.white70, fontSize: 9.5);
    final number = w.accountNumber;
    final maskedNumber = number != null && number.isNotEmpty
        ? '••••  ••••  ••••  ${number.substring(math.max(0, number.length - 4))}'
        : cash
            ? 'TIỀN MẶT'
            : 'CHƯA CÓ SỐ TÀI KHOẢN';
    final owner = w.ownerName.isNotEmpty
        ? w.ownerName
        : w.owner == 'wife'
            ? 'Vợ'
            : 'Chồng';
    return LayoutBuilder(
        builder: (context, constraints) {
          final effectiveRatio = math.min(
              aspectRatio,
              constraints.maxWidth /
                  minimumHeight(context, credit: credit));
          final cardHeight = constraints.maxWidth / effectiveRatio;
          final contentHeight = math.max(120.0, cardHeight - 20.0);
          final contentWidth = math.max(260.0, constraints.maxWidth - 26.0);
          return AspectRatio(
                aspectRatio: effectiveRatio,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: onHistory,
                    child: Stack(children: [
                      // Specular Ambient Light Overlay (clean luxury surface, no watermark)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                begin: const Alignment(-0.8, -1.0),
                                end: const Alignment(0.8, 1.0),
                                colors: [
                                  Colors.white.withValues(alpha: 0.12),
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.black.withValues(alpha: 0.15),
                                ],
                                stops: const [0.0, 0.45, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 10),
                        child: SizedBox(
                          width: contentWidth,
                          height: contentHeight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: contentWidth,
                                maxWidth: contentWidth,
                                minHeight: contentHeight,
                              ),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                Row(children: [
                                  Container(
                                      width: 36,
                                      height: 36,
                                      clipBehavior: Clip.antiAlias,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(9),
                                          color: cash
                                              ? const Color(0xFF10B981)
                                              : Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.18),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1.5),
                                            ),
                                          ],
                                          border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.35),
                                              width: 1.0)),
                                      padding:
                                          EdgeInsets.all(cash ? 0 : 2.5),
                                      child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(7),
                                          child: logo(31))),
                                  const SizedBox(width: 9),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(w.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800)),
                                        Text(
                                            credit
                                                ? 'THẺ TÍN DỤNG'
                                                : cash
                                                    ? 'TIỀN MẶT'
                                                    : 'NGÂN HÀNG',
                                            style: muted)
                                      ])),
                                  SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: PopupMenuButton<String>(
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(Icons.more_vert,
                                              color: Colors.white70, size: 18),
                                          onSelected: (v) => v == 'edit'
                                              ? onEdit()
                                              : onDelete(),
                                          itemBuilder: (_) => [
                                                const PopupMenuItem(
                                                    value: 'edit',
                                                    child:
                                                        Text('Sửa thông tin')),
                                                const PopupMenuItem(
                                                    value: 'delete',
                                                    child: Text('Xóa ví / thẻ'))
                                              ])),
                                ]),
                                Row(children: [
                                  Container(
                                      width: 30,
                                      height: 23,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFf6e3a0),
                                                Color(0xFFcfac54)
                                              ]),
                                          border: Border.all(
                                              color: Colors.white54)),
                                      child: const Icon(Icons.grid_view,
                                          size: 21, color: Color(0xFF96792f))),
                                  const SizedBox(width: 5),
                                  const Icon(Icons.contactless_outlined,
                                      color: Colors.white60, size: 17),
                                  if (credit) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerRight,
                                            child: Text(maskedNumber,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    letterSpacing: 1.2))))
                                  ]
                                ]),
                                if (!credit)
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(maskedNumber,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              letterSpacing: 1.2))),
                                if (credit)
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 7),
                                      decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: .22),
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: Column(children: [
                                        Row(children: [
                                          Expanded(
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                const Text('Dư nợ hiện tại',
                                                    style: muted),
                                                money(w.currentDebt,
                                                    color:
                                                        const Color(0xFFfecdd3),
                                                    size: 14)
                                              ])),
                                          Expanded(
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                const Text('Còn khả dụng',
                                                    style: muted),
                                                money(available,
                                                    color:
                                                        const Color(0xFFa7f3d0),
                                                    size: 14)
                                              ]))
                                        ]),
                                        const SizedBox(height: 5),
                                        LinearProgressIndicator(
                                            value:
                                                masked ? 0 : usage.clamp(0, 1),
                                            minHeight: 4,
                                            borderRadius:
                                                BorderRadius.circular(9),
                                            backgroundColor: Colors.white24,
                                            color: usage >= .85
                                                ? Colors.redAccent
                                                : Colors.white70),
                                        const SizedBox(height: 4),
                                        Row(children: [
                                          Expanded(
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                FittedBox(
                                                    child: Text(
                                                        masked
                                                            ? 'Hạn mức •••••• ₫'
                                                            : 'Hạn mức ${formatVND(w.creditLimit)} · ${(usage * 100).round()}%',
                                                        style: muted)),
                                                Text(
                                                    '$owner · Sao kê ${w.statementDay}',
                                                    style: muted)
                                              ])),
                                          if (onPay != null)
                                            SizedBox(
                                                height: 27,
                                                child: TextButton(
                                                    onPressed: onPay,
                                                    style: TextButton.styleFrom(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 7),
                                                        foregroundColor:
                                                            Colors.white,
                                                        backgroundColor:
                                                            Colors.white12,
                                                        minimumSize: Size.zero),
                                                    child: const Text(
                                                        'Trả nợ thẻ',
                                                        style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold))))
                                        ]),
                                      ]))
                                else
                                  Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Expanded(
                                            child: Text(owner.toUpperCase(),
                                                style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.8))),
                                        Expanded(
                                            flex: 2,
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('Số dư khả dụng',
                                                      style: TextStyle(
                                                          color: Colors.white
                                                              .withValues(
                                                                  alpha: 0.8),
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          letterSpacing: 0.2)),
                                                  const SizedBox(height: 2),
                                                  money(w.balance, size: 21.0)
                                                ]))
                                      ]),
                              ])),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            );
        });
  }
}
